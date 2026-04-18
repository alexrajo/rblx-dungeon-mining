local CaveUtil = {}

-- ============================================================
-- CONFIGURATION CONSTANTS
-- ============================================================

-- Size of each block/voxel in studs
local BLOCK_SIZE = 4

-- How many blocks wide/deep the cave grid spans (X and Z)
local CAVE_SIZE = 100

-- How many blocks deep the floor fills below the worm path
local CAVE_FLOOR_DEPTH = 2

-- Lowest solid grid layer to instantiate. The layer below this is hidden by
-- the baseplate underside and only wastes parts.
local MIN_GENERATED_SOLID_GY = -CAVE_FLOOR_DEPTH + 1

-- Lowest carved cell that can become playable cave air. Lower cells produce
-- walkable surfaces inside or under the brown baseplate.
local MIN_PLAYABLE_AIR_GY = 1

-- How many blocks of roof sit above the worm path.
-- The worm sphere carves naturally into this, giving an uneven roof.
-- Increase for a taller cave with more ceiling variation.
local CAVE_ROOF_HEIGHT = 6

-- Number of worms to generate (more = more tunnels/branching)
local NUM_WORMS = 3

-- How many steps each worm takes (longer = longer tunnels)
local WORM_LENGTH = 80

-- How far the worm moves each step (in studs). Keep close to BLOCK_SIZE.
local WORM_STEP_SIZE = 4

-- How sharply the worm can turn each step (radians). Higher = more winding.
local WORM_TURN_AMOUNT = 1

-- Controls how smooth the worm's path is. Higher = smoother curves.
local WORM_RESOLUTION = 6

-- Radius of the tunnel carved by each worm (in studs)
local TUNNEL_RADIUS = 20

-- Y variation the worm is allowed (studs). Low = flat cave.
local WORM_Y_VARIATION = 2

-- Radius (in studs) of the guaranteed open spawn area at the cave center
local SPAWN_CLEAR_RADIUS = 16
local SPAWN_PLATFORM_SIZE = Vector3.new(12, 1, 12)
local SPAWN_PLATFORM_SURFACE_CLEARANCE = 0.05

-- How many blocks from the edge the gradual closing begins.
-- Tunnels shrink to nothing by the time they reach the cave boundary.
local BORDER_FADE_BLOCKS = 8

-- Material for cave wall/ceiling blocks
local WALL_MATERIAL = Enum.Material.SmoothPlastic
local WALL_COLOR = BrickColor.new("Dark grey")

-- Material for the baseplate
local BASE_MATERIAL = Enum.Material.SmoothPlastic
local BASE_COLOR = BrickColor.new("Reddish brown")

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

local NEIGHBOUR_OFFSETS = {
	Vector3.new( 1, 0, 0), Vector3.new(-1, 0, 0),
	Vector3.new( 0, 1, 0), Vector3.new( 0,-1, 0),
	Vector3.new( 0, 0, 1), Vector3.new( 0, 0,-1),
}

local function isWithinCaveBounds(gx: number, gy: number, gz: number, halfSize: number): boolean
	return math.abs(gx) <= halfSize
		and math.abs(gz) <= halfSize
		and gy >= -CAVE_FLOOR_DEPTH
		and gy <= CAVE_ROOF_HEIGHT
end

-- Returns true if at least one of the 6 face-neighbours of (x,y,z) is air.
-- A cell is air when it was carved by a worm, falls outside the fill volume,
-- or sits inside the spawn clear zone.
local function isExposed(
	x: number, y: number, z: number,
	allCarved: {[string]: boolean},
	halfSize: number,
	inSpawnZone: (number, number) -> boolean
): boolean
	for _, n in ipairs(NEIGHBOUR_OFFSETS) do
		local nx, ny, nz = x + n.X, y + n.Y, z + n.Z

		-- Outside horizontal cave bounds → open air beyond the wall
		if math.abs(nx) > halfSize or math.abs(nz) > halfSize then
			return true
		end

		-- Outside vertical fill range → open air above roof or below floor
		if ny < -CAVE_FLOOR_DEPTH or ny > CAVE_ROOF_HEIGHT then
			return true
		end

		-- Carved by a worm → air
		if allCarved[nx .. "," .. ny .. "," .. nz] then
			return true
		end

		-- Spawn clear zone is always air
		if inSpawnZone(nx, nz) then
			return true
		end
	end

	return false
end

-- Returns a set of grid-coordinate keys "gx,gy,gz" that the worm carves empty.
local function runWorm(origin: Vector3, wormIndex: number, seed: number): {[string]: boolean}
	local carved = {}

	local startOffset = Vector3.new(
		math.noise(wormIndex * 3.1, seed) * CAVE_SIZE * BLOCK_SIZE * 0.3,
		0,
		math.noise(wormIndex * 5.7, seed) * CAVE_SIZE * BLOCK_SIZE * 0.3
	)

	local wormCF = CFrame.new(origin + startOffset)
	local halfSize = math.floor(CAVE_SIZE / 2)

	for i = 1, WORM_LENGTH do
		local p = wormCF.Position

		local rx = math.noise(p.X / WORM_RESOLUTION + 0.1, seed + wormIndex * 10) * WORM_TURN_AMOUNT
		local ry = math.noise(p.Y / WORM_RESOLUTION + 0.1, seed + wormIndex * 20) * WORM_TURN_AMOUNT * 0.2
		local rz = math.noise(p.Z / WORM_RESOLUTION + 0.1, seed + wormIndex * 30) * WORM_TURN_AMOUNT

		wormCF = wormCF * CFrame.Angles(rx, ry, rz) * CFrame.new(0, 0, -WORM_STEP_SIZE)

		local clampedPos = Vector3.new(
			wormCF.Position.X,
			math.clamp(wormCF.Position.Y, origin.Y - WORM_Y_VARIATION, origin.Y + WORM_Y_VARIATION),
			wormCF.Position.Z
		)
		wormCF = CFrame.new(clampedPos) * (wormCF - wormCF.Position)

		local wormGX = math.round((clampedPos.X - origin.X) / BLOCK_SIZE)
		local wormGZ = math.round((clampedPos.Z - origin.Z) / BLOCK_SIZE)
		local edgeDist = halfSize - math.max(math.abs(wormGX), math.abs(wormGZ))

		local borderT = math.clamp(edgeDist / BORDER_FADE_BLOCKS, 0, 1)
		local effectiveRadius = TUNNEL_RADIUS * borderT
		if effectiveRadius <= 0 then
			continue
		end

		local radiusInBlocks = math.ceil(effectiveRadius / BLOCK_SIZE)
		for dx = -radiusInBlocks, radiusInBlocks do
			for dy = -radiusInBlocks, radiusInBlocks do
				for dz = -radiusInBlocks, radiusInBlocks do
					local offset = Vector3.new(dx, dy, dz) * BLOCK_SIZE
					if offset.Magnitude <= effectiveRadius then
						local gx = math.round((clampedPos.X + offset.X - origin.X) / BLOCK_SIZE)
						local gy = math.round((clampedPos.Y + offset.Y - origin.Y) / BLOCK_SIZE)
						local gz = math.round((clampedPos.Z + offset.Z - origin.Z) / BLOCK_SIZE)
						if isWithinCaveBounds(gx, gy, gz, halfSize) then
							carved[gx .. "," .. gy .. "," .. gz] = true
						end
					end
				end
			end
		end
	end

	return carved
end

local function createShellPart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Anchored = true
	part.CanCollide = true
	part.Material = WALL_MATERIAL
	part.BrickColor = WALL_COLOR
	part.Parent = parent

	return part
end

local function getFloorSurfacePosition(floorPosition: Vector3): Vector3
	return floorPosition - Vector3.new(0, BLOCK_SIZE, 0)
end

local function createSpawnPlatform(parent: Instance, surfacePosition: Vector3): Part
	local platform = Instance.new("Part")
	platform.Name = "SpawnPlatform"
	platform.Size = SPAWN_PLATFORM_SIZE
	platform.CFrame = CFrame.new(surfacePosition - Vector3.new(0, SPAWN_PLATFORM_SIZE.Y / 2, 0))
	platform.Anchored = true
	platform.CanCollide = true
	platform.Material = BASE_MATERIAL
	platform.BrickColor = BASE_COLOR
	platform.Parent = parent

	return platform
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Generates a cave Model at `position`.
--- Only surface blocks (those adjacent to at least one air cell) are created,
--- skipping fully buried interior blocks for performance.
--- @param position Vector3 - World position for the cave origin (center of baseplate)
--- @return Model, {Vector3}, Vector3
function CaveUtil.GenerateCave(position: Vector3): (Model, {Vector3}, Vector3)
	local seed = tick() * math.random()

	local cave = Instance.new("Model")
	cave.Name = "Cave"

	-- --- Baseplate ---
	local baseplateSize = CAVE_SIZE * BLOCK_SIZE
	local baseplate = Instance.new("Part")
	baseplate.Name = "Baseplate"
	baseplate.Size = Vector3.new(baseplateSize, BLOCK_SIZE, baseplateSize)
	baseplate.CFrame = CFrame.new(position + Vector3.new(0, -BLOCK_SIZE / 2, 0))
	baseplate.Anchored = true
	baseplate.CanCollide = true
	baseplate.Material = BASE_MATERIAL
	baseplate.BrickColor = BASE_COLOR
	baseplate.Parent = cave

	local halfSize = math.floor(CAVE_SIZE / 2)
	local generatedSpan = (halfSize * 2 + 1) * BLOCK_SIZE
	local shellHeight = (CAVE_ROOF_HEIGHT + CAVE_FLOOR_DEPTH + 2) * BLOCK_SIZE
	local shellCenterY = ((CAVE_ROOF_HEIGHT - CAVE_FLOOR_DEPTH + 1) * BLOCK_SIZE) / 2
	local roofY = (CAVE_ROOF_HEIGHT + 1) * BLOCK_SIZE
	local sideOffset = generatedSpan / 2 + BLOCK_SIZE / 2

	-- --- Exterior shell ---
	-- Use large perimeter parts so cracks to the outside are always sealed.
	createShellPart(
		cave,
		"RoofShell",
		Vector3.new(generatedSpan + BLOCK_SIZE * 2, BLOCK_SIZE, generatedSpan + BLOCK_SIZE * 2),
		position + Vector3.new(0, roofY, 0)
	)
	createShellPart(
		cave,
		"NorthWallShell",
		Vector3.new(generatedSpan, shellHeight, BLOCK_SIZE),
		position + Vector3.new(0, shellCenterY, -sideOffset)
	)
	createShellPart(
		cave,
		"SouthWallShell",
		Vector3.new(generatedSpan, shellHeight, BLOCK_SIZE),
		position + Vector3.new(0, shellCenterY, sideOffset)
	)
	createShellPart(
		cave,
		"WestWallShell",
		Vector3.new(BLOCK_SIZE, shellHeight, generatedSpan),
		position + Vector3.new(-sideOffset, shellCenterY, 0)
	)
	createShellPart(
		cave,
		"EastWallShell",
		Vector3.new(BLOCK_SIZE, shellHeight, generatedSpan),
		position + Vector3.new(sideOffset, shellCenterY, 0)
	)

	-- --- Run worms to get carved-out positions ---
	local allCarved = {}
	for w = 1, NUM_WORMS do
		local carved = runWorm(position, w, seed)
		for key, v in pairs(carved) do
			local _, yStr = string.match(key, "^(-?%d+),(-?%d+),(-?%d+)$")
			local gy = tonumber(yStr)
			if gy ~= nil and gy >= MIN_PLAYABLE_AIR_GY then
				allCarved[key] = v
			end
		end
	end

	-- --- Collect valid floor spawn positions ---
	local function inSpawnZone(x: number, z: number): boolean
		return Vector2.new(x * BLOCK_SIZE, z * BLOCK_SIZE).Magnitude <= SPAWN_CLEAR_RADIUS
	end

	local spawnExclusionRadius = SPAWN_CLEAR_RADIUS + BLOCK_SIZE
	local floorPositions: {Vector3} = {}
	local spawnPosition = position
	local rejectedOutOfBoundsFloorPositions = 0

	for key, _ in pairs(allCarved) do
		local xStr, yStr, zStr = string.match(key, "^(-?%d+),(-?%d+),(-?%d+)$")
		local gx, gy, gz = tonumber(xStr), tonumber(yStr), tonumber(zStr)
		if gx == nil or gy == nil or gz == nil then
			continue
		end

		if not isWithinCaveBounds(gx, gy, gz, halfSize) then
			rejectedOutOfBoundsFloorPositions += 1
			continue
		end

		if gy >= MIN_PLAYABLE_AIR_GY and gy <= CAVE_ROOF_HEIGHT then
			local belowKey = gx .. "," .. (gy - 1) .. "," .. gz
			local belowIsSolid = not allCarved[belowKey] and not inSpawnZone(gx, gz)

			if belowIsSolid then
				local worldX = gx * BLOCK_SIZE
				local worldZ = gz * BLOCK_SIZE
				if Vector2.new(worldX, worldZ).Magnitude > spawnExclusionRadius then
					table.insert(floorPositions, position + Vector3.new(
						worldX,
						gy * BLOCK_SIZE + BLOCK_SIZE / 2,
						worldZ
					))
				end
			end
		end
	end

	if rejectedOutOfBoundsFloorPositions > 0 then
		warn(("CaveUtil.GenerateCave rejected %d out-of-bounds floor candidates"):format(rejectedOutOfBoundsFloorPositions))
	end

	-- Spawn players on the nearest real walkable floor candidate. Keeping the
	-- candidate's X/Z avoids placing the character over unsupported spawn air.
	if #floorPositions > 0 then
		local bestSpawnPosition = floorPositions[1]
		local bestDistance = math.huge

		for _, floorPosition in ipairs(floorPositions) do
			local offset = floorPosition - position
			local distance = Vector2.new(offset.X, offset.Z).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				bestSpawnPosition = floorPosition
			end
		end

		spawnPosition = getFloorSurfacePosition(bestSpawnPosition)
			+ Vector3.new(0, SPAWN_PLATFORM_SURFACE_CLEARANCE, 0)
	end

	createSpawnPlatform(cave, spawnPosition)

	-- --- Fill the cave volume, surface blocks only ---
	for x = -halfSize, halfSize do
		for y = MIN_GENERATED_SOLID_GY, CAVE_ROOF_HEIGHT do
			for z = -halfSize, halfSize do
				-- This position is air; nothing to place
				if allCarved[x .. "," .. y .. "," .. z] or inSpawnZone(x, z) then
					continue
				end

				-- Skip fully buried blocks — they're invisible and waste part count
				if not isExposed(x, y, z, allCarved, halfSize, inSpawnZone) then
					continue
				end

				local worldPos = position + Vector3.new(x, y, z) * BLOCK_SIZE
				local block = Instance.new("Part")
				block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
				block.CFrame = CFrame.new(worldPos)
				block.Anchored = true
				block.CanCollide = true
				block.Material = WALL_MATERIAL
				block.BrickColor = WALL_COLOR
				block.Parent = cave
			end
		end
	end

	return cave, floorPositions, spawnPosition
end

return CaveUtil
