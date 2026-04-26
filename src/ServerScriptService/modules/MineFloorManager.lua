local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local CaveUtil = require(modules.CaveUtil)
local CrateService = require(modules.CrateService)
local OreNodeUtil = require(modules.OreNodeUtil)

local configs = ReplicatedStorage.configs
local CrateConfig = require(configs.CrateConfig)
local MineLayerConfig = require(configs.MineLayerConfig)
local MineRewardFloorConfig = require(configs.MineRewardFloorConfig)
local OreConfig = require(configs.OreConfig)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local EnemyNPCRefsFolder = ServerStorage.NPCs.Enemies

-- Mine area offset — the mine exists far below the hub
local MINE_ORIGIN = Vector3.new(0, -500, 0)
local FLOOR_SPACING = 100 -- Distance between floors on Y axis

-- Hub spawn location (players teleport here when exiting)
local HUB_SPAWN = Vector3.new(0, 10, 0)
local MINE_EXIT_OFFSET = 8

-- Floor pool: floorNumber → { folder: Folder, players: {[Player]: true}, spawnPosition: Vector3 }
local floorPool: { [number]: { folder: Folder, players: { [Player]: boolean }, spawnPosition: Vector3 } } = {}

-- Track which floor each player is on (nil = not in mine / above ground)
local playerFloors: { [Player]: number } = {}

local MineFloorManager = {}

function MineFloorManager.GetCurrentFloor(player: Player): number?
	return playerFloors[player]
end

function MineFloorManager.IsRewardFloor(floor: number): boolean
	return MineRewardFloorConfig.IsRewardFloor(floor)
end

function MineFloorManager.GetLayerForFloor(floor: number): (number?, table?)
	for layerNum, layerData in pairs(MineLayerConfig) do
		if type(layerNum) ~= "number" then continue end
		if floor >= layerData.floors.min and floor <= layerData.floors.max then
			return layerNum, layerData
		end
	end
	return nil, nil
end

local NUM_LIGHTS = 4
local ORES_PER_LADDER_REVEAL = 50
local DEFAULT_THEME = "default"
local ASCENDING_LADDER_OFFSET = Vector3.new(0, 3, 12)
local REWARD_ROOM_SIZE = Vector3.new(48, 20, 48)
local REWARD_ROOM_WALL_THICKNESS = 2
local REWARD_ROOM_FLOOR_THICKNESS = 2
local REWARD_ROOM_LIGHT_HEIGHT = 10
local REWARD_ROOM_SPAWN_OFFSET = Vector3.new(0, 1, 14)
local REWARD_ROOM_EXIT_LADDER_OFFSET = Vector3.new(-12, 1, 14)
local REWARD_ROOM_DESCEND_LADDER_OFFSET = Vector3.new(12, 3, -14)
local REWARD_ROOM_CHEST_OFFSET = Vector3.new(0, 2, 0)
local FLOOR_POSITION_TO_SURFACE_OFFSET = Vector3.new(0, 4, 0)

local function createAscendingLadder(position: Vector3, parent: Instance, floorNumber: number)
	local ladderModel = Instance.new("Model")
	ladderModel.Name = "SurfaceLadder"
	ladderModel:SetAttribute("FloorNumber", floorNumber)
	ladderModel:SetAttribute("LadderAction", "exit")
	ladderModel:SetAttribute("LadderVariant", "ascending")

	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(7, 1, 7)
	platform.CFrame = CFrame.new(position)
	platform.Anchored = true
	platform.Material = Enum.Material.Slate
	platform.BrickColor = BrickColor.new("Dark stone grey")
	platform.Parent = ladderModel

	local leftRail = Instance.new("Part")
	leftRail.Name = "LeftRail"
	leftRail.Size = Vector3.new(0.6, 7, 0.6)
	leftRail.CFrame = CFrame.new(position + Vector3.new(-1.8, 4, 0))
	leftRail.Anchored = true
	leftRail.Material = Enum.Material.Metal
	leftRail.BrickColor = BrickColor.new("Black")
	leftRail.Parent = ladderModel

	local rightRail = leftRail:Clone()
	rightRail.Name = "RightRail"
	rightRail.CFrame = CFrame.new(position + Vector3.new(1.8, 4, 0))
	rightRail.Parent = ladderModel

	for rungIndex = 1, 4 do
		local rung = Instance.new("Part")
		rung.Name = "Rung_" .. rungIndex
		rung.Size = Vector3.new(4.2, 0.35, 0.45)
		rung.CFrame = CFrame.new(position + Vector3.new(0, 1.4 + rungIndex * 1.2, 0))
		rung.Anchored = true
		rung.Material = Enum.Material.WoodPlanks
		rung.BrickColor = BrickColor.new("Reddish brown")
		rung.Parent = ladderModel
	end

	local topMarker = Instance.new("Part")
	topMarker.Name = "TopMarker"
	topMarker.Size = Vector3.new(5, 0.8, 1.6)
	topMarker.CFrame = CFrame.new(position + Vector3.new(0, 7.3, 0))
	topMarker.Anchored = true
	topMarker.Material = Enum.Material.Neon
	topMarker.Color = Color3.fromRGB(255, 235, 140)
	topMarker.Parent = ladderModel

	ladderModel.PrimaryPart = platform
	CollectionService:AddTag(ladderModel, "MineLadder")
	ladderModel.Parent = parent

	return ladderModel
end

local function createDescendingLadder(position: Vector3, parent: Instance, floorNumber: number)
	local ladder = Instance.new("Part")
	ladder.Name = "Ladder"
	ladder.Size = Vector3.new(4, 6, 4)
	ladder.Position = position
	ladder.Anchored = true
	ladder.Material = Enum.Material.Wood
	ladder.BrickColor = BrickColor.new("Brown")
	ladder:SetAttribute("FloorNumber", floorNumber)
	ladder:SetAttribute("LadderAction", "descend")
	ladder:SetAttribute("LadderVariant", "descending")
	CollectionService:AddTag(ladder, "MineLadder")
	ladder.Parent = parent

	return ladder
end

local function createRewardChest(position: Vector3, parent: Instance, floorNumber: number)
	local refs = ReplicatedStorage:FindFirstChild("refs")
	local chestRef = if refs ~= nil then refs:FindFirstChild("Chest") else nil
	if chestRef == nil or not chestRef:IsA("Model") then
		warn("MineFloorManager: Missing ReplicatedStorage.refs.Chest model")
		return nil
	end

	local chest = chestRef:Clone()
	chest.Name = "RewardChest"
	chest:SetAttribute("FloorNumber", floorNumber)
	chest:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0))
	CollectionService:AddTag(chest, "MineRewardChest")
	chest.Parent = parent

	return chest
end

local function getCrateRef(): Instance?
	local refs = ReplicatedStorage:FindFirstChild("refs")
	local crateRef = if refs ~= nil then refs:FindFirstChild("Crate") else nil
	if crateRef == nil then
		warn("MineFloorManager: Missing ReplicatedStorage.refs.Crate")
		return nil
	end

	if not crateRef:IsA("Model") and not crateRef:IsA("BasePart") then
		warn("MineFloorManager: ReplicatedStorage.refs.Crate must be a Model or BasePart")
		return nil
	end

	return crateRef
end

local function createRewardRoom(floorOrigin: Vector3, parent: Instance, floorNumber: number): Vector3
	local roomModel = Instance.new("Model")
	roomModel.Name = "RewardRoom"

	local roomSize = REWARD_ROOM_SIZE
	local halfX = roomSize.X / 2
	local halfY = roomSize.Y / 2
	local halfZ = roomSize.Z / 2

	local floorPart = Instance.new("Part")
	floorPart.Name = "Floor"
	floorPart.Size = Vector3.new(roomSize.X, REWARD_ROOM_FLOOR_THICKNESS, roomSize.Z)
	floorPart.CFrame = CFrame.new(floorOrigin + Vector3.new(0, -REWARD_ROOM_FLOOR_THICKNESS / 2, 0))
	floorPart.Anchored = true
	floorPart.Material = Enum.Material.Slate
	floorPart.BrickColor = BrickColor.new("Dark stone grey")
	floorPart.Parent = roomModel

	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Size = Vector3.new(roomSize.X, REWARD_ROOM_WALL_THICKNESS, roomSize.Z)
	ceiling.CFrame = CFrame.new(floorOrigin + Vector3.new(0, roomSize.Y, 0))
	ceiling.Anchored = true
	ceiling.Material = Enum.Material.Slate
	ceiling.BrickColor = BrickColor.new("Dark stone grey")
	ceiling.Parent = roomModel

	local function createWall(name: string, size: Vector3, offset: Vector3)
		local wall = Instance.new("Part")
		wall.Name = name
		wall.Size = size
		wall.CFrame = CFrame.new(floorOrigin + offset)
		wall.Anchored = true
		wall.Material = Enum.Material.Rock
		wall.BrickColor = BrickColor.new("Dark taupe")
		wall.Parent = roomModel
	end

	createWall(
		"NorthWall",
		Vector3.new(roomSize.X, roomSize.Y, REWARD_ROOM_WALL_THICKNESS),
		Vector3.new(0, halfY, -halfZ)
	)
	createWall(
		"SouthWall",
		Vector3.new(roomSize.X, roomSize.Y, REWARD_ROOM_WALL_THICKNESS),
		Vector3.new(0, halfY, halfZ)
	)
	createWall(
		"WestWall",
		Vector3.new(REWARD_ROOM_WALL_THICKNESS, roomSize.Y, roomSize.Z),
		Vector3.new(-halfX, halfY, 0)
	)
	createWall(
		"EastWall",
		Vector3.new(REWARD_ROOM_WALL_THICKNESS, roomSize.Y, roomSize.Z),
		Vector3.new(halfX, halfY, 0)
	)

	local lightAnchor = Instance.new("Part")
	lightAnchor.Name = "LightAnchor"
	lightAnchor.Size = Vector3.new(1, 1, 1)
	lightAnchor.CFrame = CFrame.new(floorOrigin + Vector3.new(0, REWARD_ROOM_LIGHT_HEIGHT, 0))
	lightAnchor.Anchored = true
	lightAnchor.Transparency = 1
	lightAnchor.CanCollide = false
	lightAnchor.Parent = roomModel

	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 1
	pointLight.Range = 45
	pointLight.Color = Color3.fromRGB(255, 217, 153)
	pointLight.Parent = lightAnchor

	roomModel.Parent = parent

	createAscendingLadder(floorOrigin + REWARD_ROOM_EXIT_LADDER_OFFSET, parent, floorNumber)
	createDescendingLadder(floorOrigin + REWARD_ROOM_DESCEND_LADDER_OFFSET, parent, floorNumber)
	createRewardChest(floorOrigin + REWARD_ROOM_CHEST_OFFSET, parent, floorNumber)

	return floorOrigin + REWARD_ROOM_SPAWN_OFFSET
end

--- Fisher-Yates shuffle in place.
local function shuffleArray(arr: { any })
	for i = #arr, 2, -1 do
		local j = math.random(1, i)
		arr[i], arr[j] = arr[j], arr[i]
	end
end

--- Anchor the player's HumanoidRootPart so they don't fall during loading.
local function freezePlayer(player: Player)
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = true
		end
	end
end

--- Unanchor the player's HumanoidRootPart after floor is ready.
local function unfreezePlayer(player: Player)
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = false
		end
	end
end

function MineFloorManager.SetPlayerFrozen(player: Player, isFrozen: boolean)
	if isFrozen then
		freezePlayer(player)
	else
		unfreezePlayer(player)
	end
end

--- Get the floor origin position for a given floor number.
local function getFloorOrigin(floorNumber: number): Vector3
	return MINE_ORIGIN + Vector3.new(0, -floorNumber * FLOOR_SPACING, 0)
end

local function getEntranceTeleportPosition(): Vector3
	local mineEntrances = CollectionService:GetTagged("MineEntrance")
	local entrance = mineEntrances[1]
	if entrance == nil then
		return HUB_SPAWN
	end

	if entrance:IsA("Model") then
		local pivot = entrance:GetPivot()
		return pivot.Position + (pivot.LookVector * MINE_EXIT_OFFSET)
	end

	if entrance:IsA("BasePart") then
		local part = entrance :: BasePart
		return part.Position + (part.CFrame.LookVector * MINE_EXIT_OFFSET)
	end

	return HUB_SPAWN
end

--- Count players on a given floor.
local function getPlayerCountOnFloor(floorNumber: number): number
	local entry = floorPool[floorNumber]
	if entry == nil then return 0 end

	local count = 0
	for _ in pairs(entry.players) do
		count += 1
	end
	return count
end

--- Check if any player is above ground (not in a mine).
local function anyPlayerAboveGround(): boolean
	for _, player in ipairs(Players:GetPlayers()) do
		if playerFloors[player] == nil then
			return true
		end
	end
	return false
end

--- Check if a floor is needed as a preload for the previous floor.
local function isFloorNeededAsPreload(floorNumber: number): boolean
	if floorNumber <= 1 then
		-- Floor 1 is needed as preload when any player is above ground
		return anyPlayerAboveGround()
	end
	-- Floor N is needed if floor N-1 has active players
	return getPlayerCountOnFloor(floorNumber - 1) > 0
end

--- Destroy a floor and remove it from the pool. Also cascade-check the next floor.
local function cleanupFloorIfEmpty(floorNumber: number)
	local entry = floorPool[floorNumber]
	if entry == nil then return end

	-- Don't cleanup if players are still on the floor
	if getPlayerCountOnFloor(floorNumber) > 0 then return end

	-- Don't cleanup if floor is needed as preload for previous floor
	if isFloorNeededAsPreload(floorNumber) then return end

	-- Destroy and remove
	entry.folder:Destroy()
	floorPool[floorNumber] = nil

	-- Cascade: the next floor may have been preloaded for this one
	if floorPool[floorNumber + 1] then
		cleanupFloorIfEmpty(floorNumber + 1)
	end
end

function MineFloorManager.SpawnFloor(floorNumber: number): (Folder?, Vector3?)
	local layerNum, layerData = MineFloorManager.GetLayerForFloor(floorNumber)
	if layerData == nil then
		warn("MineFloorManager: No layer data for floor", floorNumber)
		return nil
	end

	-- Create a folder to hold all floor content
	local floorFolder = Instance.new("Folder")
	floorFolder.Name = "MineFloor_" .. floorNumber
	floorFolder:SetAttribute("FloorNumber", floorNumber)

	local floorOrigin = getFloorOrigin(floorNumber)

	if MineRewardFloorConfig.IsRewardFloor(floorNumber) then
		local spawnPosition = createRewardRoom(floorOrigin, floorFolder, floorNumber)
		floorFolder.Parent = workspace
		return floorFolder, spawnPosition
	end

	-- Generate procedural cave
	local caveModel, floorPositions, spawnPosition = CaveUtil.GenerateCave(floorOrigin)
	caveModel.Parent = floorFolder

	createAscendingLadder(spawnPosition + ASCENDING_LADDER_OFFSET, floorFolder, floorNumber)

	-- Shuffle floor positions for random placement
	shuffleArray(floorPositions)

	local reservedSpawnPositionKeys = {}
	local spawnablePositions = {}
	for _, floorPosition in ipairs(floorPositions) do
		local key = ("%d,%d,%d"):format(
			math.round(floorPosition.X),
			math.round(floorPosition.Y),
			math.round(floorPosition.Z)
		)
		if not reservedSpawnPositionKeys[key] then
			reservedSpawnPositionKeys[key] = true
			table.insert(spawnablePositions, floorPosition)
		end
	end

	local spawnIndex = 0
	local exhaustedSpawnTypes = {}
	local function takeSpawnPosition(spawnType: string): Vector3?
		spawnIndex += 1
		if spawnIndex <= #spawnablePositions then
			return spawnablePositions[spawnIndex]
		end

		if not exhaustedSpawnTypes[spawnType] then
			exhaustedSpawnTypes[spawnType] = true
			warn("MineFloorManager: Not enough unique floor positions for " .. spawnType)
		end
		return nil
	end

	-- Compute ore node count from density and available floor positions
	local oreDensity = layerData.oreDensity or MineLayerConfig.defaultOreDensity
	local numOreNodes = math.max(1, math.floor(#floorPositions * oreDensity + 0.5))

	-- Split ore nodes across primary, secondary, and optional tertiary types.
	-- Ratio: ~1/2 primary, ~1/3 secondary, ~1/6 tertiary (3:2:1).
	-- With no tertiary: ~2/3 primary, ~1/3 secondary (matching original 4:2 split at n=6).
	local primaryOre = layerData.primaryOre
	local secondaryOre = layerData.secondaryOre
	local tertiaryOre = layerData.tertiaryOre
	local secondaryCount = math.floor(numOreNodes / 3)
	local tertiaryCount = tertiaryOre and math.floor(numOreNodes / 6) or 0
	local primaryCount = numOreNodes - secondaryCount - tertiaryCount

	local spawnedOreNodes = {}

	for i = 1, numOreNodes do
		local oreType
		if i <= primaryCount then
			oreType = primaryOre
		elseif i <= primaryCount + secondaryCount then
			oreType = secondaryOre
		else
			oreType = tertiaryOre
		end
		local oreData = OreConfig.byName[oreType]
		if oreData == nil then continue end

		local floorPosition = takeSpawnPosition("ore nodes")
		if floorPosition == nil then
			break
		end

		local nodeRef = OreNodeUtil.GetRef(oreType)
		if nodeRef == nil then continue end

		local node = nodeRef:Clone()
		node.Name = oreType .. "Node_" .. i
		if OreNodeUtil.EnsurePrimaryPart(node) == nil then
			node:Destroy()
			continue
		end
		OreNodeUtil.AnchorModel(node)

		-- floorPositions are walkable air-cell centers; move down to the actual floor surface.
		node:PivotTo(CFrame.new(OreNodeUtil.GetFloorPlacementPosition(floorPosition)))
		OreNodeUtil.ApplyAttributes(node, floorNumber, oreType, oreData)

		node.Parent = floorFolder
		CollectionService:AddTag(node, "OreNode")
		table.insert(spawnedOreNodes, node)
	end

	if #spawnedOreNodes > 0 then
		local revealCandidates = {}
		for _, node in ipairs(spawnedOreNodes) do
			table.insert(revealCandidates, node)
		end

		shuffleArray(revealCandidates)

		-- Scale ladder reveals with ore count: 1 base per ORES_PER_LADDER_REVEAL nodes (minimum 1),
		-- plus a chance for one extra reveal.
		local baseRevealCount = math.max(1, math.floor(#spawnedOreNodes / ORES_PER_LADDER_REVEAL))
		local revealCount = baseRevealCount
		revealCount = math.min(revealCount, #revealCandidates)

		for i = 1, revealCount do
			revealCandidates[i]:SetAttribute("RevealsLadder", true)
		end
	end

	-- Spawn destructible resource crates on remaining walkable floor positions.
	local crateDensity = layerData.crateDensity or CrateConfig.defaultCrateDensity
	local numCrates = math.max(0, math.floor(#floorPositions * crateDensity + 0.5))
	local crateRef = if numCrates > 0 then getCrateRef() else nil

	if crateRef ~= nil then
		for i = 1, numCrates do
			local floorPosition = takeSpawnPosition("mine crates")
			if floorPosition == nil then
				break
			end

			local crate = crateRef:Clone()
			crate.Name = "MineCrate_" .. i
			crate:SetAttribute("FloorNumber", floorNumber)
			crate:SetAttribute("CrateHP", CrateConfig.defaultHealth)

			local floorSurfacePosition = floorPosition - FLOOR_POSITION_TO_SURFACE_OFFSET
			CrateService.PlaceOnFloor(crate, floorSurfacePosition)
			CrateService.AnchorCrate(crate)

			crate.Parent = floorFolder
			CollectionService:AddTag(crate, "MineCrate")
		end
	end

	-- Spawn enemies on floor positions
	local enemyTypes = layerData.enemies
	local enemyDensity = if layerData.enemyDensity ~= nil then layerData.enemyDensity else MineLayerConfig.defaultEnemyDensity
	local numEnemies = if enemyTypes ~= nil and #enemyTypes > 0 then math.floor(#floorPositions * enemyDensity + 0.5) else 0

	for i = 1, numEnemies do
		local floorPosition = takeSpawnPosition("enemies")
		if floorPosition == nil then break end

		local enemyType = enemyTypes[math.random(1, #enemyTypes)]

        local enemyRef = EnemyNPCRefsFolder:FindFirstChild(enemyType)
        local enemyModel

        if enemyRef == nil or enemyRef:FindFirstChild("HumanoidRootPart") == nil then
            enemyModel = Instance.new("Model")
            enemyModel.Name = enemyType
    
            local rootPart = Instance.new("Part")
            rootPart.Name = "HumanoidRootPart"
            rootPart.Size = Vector3.new(2, 2, 1)
            rootPart.Position = floorPosition + Vector3.new(0, 1, 0)
            rootPart.Anchored = false
            rootPart.CanCollide = true
            rootPart.BrickColor = BrickColor.new("Bright red")
            rootPart.Parent = enemyModel
		    enemyModel.PrimaryPart = rootPart

            local humanoid = Instance.new("Humanoid")
            humanoid.Parent = enemyModel
        else
            enemyModel = enemyRef:Clone()
            enemyModel:PivotTo(CFrame.new(floorPosition + Vector3.new(0, 1, 0)))
        end


		enemyModel:SetAttribute("FloorNumber", floorNumber)
		enemyModel:SetAttribute("EnemyType", enemyType)

		enemyModel.Parent = floorFolder
		CollectionService:AddTag(enemyModel, "Enemy")
	end

	-- Add distributed lighting throughout the cave
	local lightSpacing = math.max(1, math.floor(#floorPositions / (NUM_LIGHTS + 1)))
	for i = 1, NUM_LIGHTS do
		local lightIndex = i * lightSpacing
		if lightIndex > #floorPositions then break end

		local lightPart = Instance.new("Part")
		lightPart.Name = "LightAnchor_" .. i
		lightPart.Size = Vector3.new(1, 1, 1)
		lightPart.Position = floorPositions[lightIndex] + Vector3.new(0, 8, 0)
		lightPart.Anchored = true
		lightPart.Transparency = 1
		lightPart.CanCollide = false
		lightPart.Parent = floorFolder

		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 0.5
		pointLight.Range = 60
		pointLight.Color = Color3.fromRGB(255, 200, 150)
		pointLight.Parent = lightPart
	end

	floorFolder.Parent = workspace

	return floorFolder, spawnPosition
end

local function getThemeForFloor(floorNumber: number): string
	local _, layerData = MineFloorManager.GetLayerForFloor(floorNumber)
	if layerData ~= nil and type(layerData.theme) == "string" and layerData.theme ~= "" then
		return layerData.theme
	end

	return DEFAULT_THEME
end

local function setPlayerThemeForFloor(player: Player, floorNumber: number)
	PlayerDataHandler.SetActiveTheme(player, getThemeForFloor(floorNumber))
end

--- Get a floor from the pool, or generate it synchronously as fallback.
local function getOrCreateFloor(floorNumber: number): Folder?
	local entry = floorPool[floorNumber]
	if entry then
		return entry.folder
	end

	-- Fallback: generate synchronously
	local folder, spawnPosition = MineFloorManager.SpawnFloor(floorNumber)
	if folder and spawnPosition then
		floorPool[floorNumber] = {
			folder = folder,
			players = {},
			spawnPosition = spawnPosition,
		}
	end
	return folder
end

--- Preload a floor in the background if not already in pool.
local function preloadFloor(floorNumber: number)
	if floorPool[floorNumber] then return end

	local folder, spawnPosition = MineFloorManager.SpawnFloor(floorNumber)
	if folder and spawnPosition then
		floorPool[floorNumber] = {
			folder = folder,
			players = {},
			spawnPosition = spawnPosition,
		}
	end
end

--- Add a player to a floor's tracking set.
local function addPlayerToFloor(player: Player, floorNumber: number)
	local entry = floorPool[floorNumber]
	if entry then
		entry.players[player] = true
	end
	playerFloors[player] = floorNumber
end

--- Remove a player from a floor's tracking set and trigger cleanup.
local function removePlayerFromFloor(player: Player, floorNumber: number)
	local entry = floorPool[floorNumber]
	if entry then
		entry.players[player] = nil
	end
	if playerFloors[player] == floorNumber then
		playerFloors[player] = nil
	end

	cleanupFloorIfEmpty(floorNumber)
end

--- Move a player between floors without leaving playerFloors in a transient nil state.
local function movePlayerToFloor(player: Player, oldFloor: number?, newFloor: number)
	if oldFloor == newFloor then
		addPlayerToFloor(player, newFloor)
		return
	end

	addPlayerToFloor(player, newFloor)

	if oldFloor ~= nil then
		removePlayerFromFloor(player, oldFloor)
	end
end

--- Teleport a player to a floor's origin.
local function teleportToFloor(player: Player, floorNumber: number)
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoidRootPart and humanoid then
			local entry = floorPool[floorNumber]
			local spawnPosition = if entry then entry.spawnPosition else getFloorOrigin(floorNumber)
			local rootHeightOffset = humanoid.HipHeight + (humanoidRootPart.Size.Y / 2)
			local targetCFrame = CFrame.new(spawnPosition + Vector3.new(0, rootHeightOffset, 0))

			humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
			humanoidRootPart.CFrame = targetCFrame
			humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

function MineFloorManager.EnterMine(player: Player, startFloor: number)
	startFloor = startFloor or 1
	if startFloor < 1 then startFloor = 1 end

	-- Remove from previous floor if re-entering
	local previousFloor = playerFloors[player]

	-- Freeze player to prevent falling if floor needs sync generation
	freezePlayer(player)

	-- Get or create the floor
	local folder = getOrCreateFloor(startFloor)
	if folder == nil then
		unfreezePlayer(player)
		return false
	end

	-- Add player to floor tracking
	movePlayerToFloor(player, previousFloor, startFloor)

	-- Update player state
	PlayerDataHandler.SetInMine(player, true)
	PlayerDataHandler.SetCurrentFloor(player, startFloor)
	setPlayerThemeForFloor(player, startFloor)

	-- Teleport player and keep them frozen until the transition service releases them.
	teleportToFloor(player, startFloor)

	-- Preload next floor in background
	task.defer(function()
		preloadFloor(startFloor + 1)
	end)

	return true
end

function MineFloorManager.DescendFloor(player: Player)
	local currentFloor = playerFloors[player]
	if currentFloor == nil then return false end

	local nextFloor = currentFloor + 1

	-- Update max floor reached
	PlayerDataHandler.SetMaxFloorReached(player, nextFloor)

	-- Check for checkpoint
	local layerNum, layerData = MineFloorManager.GetLayerForFloor(nextFloor)
	if layerData then
		if MineLayerConfig.IsCheckpointFloor(nextFloor) and PlayerDataHandler.SetLatestCheckpointFloor(player, nextFloor) then

			local notificationEvent = APIService.GetEvent("SendNotification")
			notificationEvent:FireClient(player, {
				Type = "checkpoint",
				Title = "Checkpoint Unlocked!",
				Description = "Floor " .. nextFloor,
			})
		end

		-- Award floor completion bonus
		PlayerDataHandler.GiveCoins(player, layerData.floorCompletionBonus or 10)
	end

	-- Freeze player to prevent falling if floor needs sync generation
	freezePlayer(player)

	-- Get or create the next floor
	local folder = getOrCreateFloor(nextFloor)
	if folder == nil then
		unfreezePlayer(player)
		return false
	end

	-- Move tracking to the new floor before cleaning up the previous one.
	local oldFloor = currentFloor
	movePlayerToFloor(player, oldFloor, nextFloor)

	-- Update player state
	PlayerDataHandler.SetCurrentFloor(player, nextFloor)
	setPlayerThemeForFloor(player, nextFloor)

	-- Teleport player and keep them frozen until the transition service releases them.
	teleportToFloor(player, nextFloor)

	-- Preload next floor in background
	task.defer(function()
		preloadFloor(nextFloor + 1)
	end)

	return true
end

function MineFloorManager.TravelToCheckpoint(player: Player, targetFloor: number)
	if targetFloor < 1 then
		return false
	end

	local currentFloor = playerFloors[player]

	freezePlayer(player)

	local folder = getOrCreateFloor(targetFloor)
	if folder == nil then
		unfreezePlayer(player)
		return false
	end

	movePlayerToFloor(player, currentFloor, targetFloor)
	PlayerDataHandler.SetInMine(player, true)
	PlayerDataHandler.SetCurrentFloor(player, targetFloor)
	setPlayerThemeForFloor(player, targetFloor)

	teleportToFloor(player, targetFloor)

	task.defer(function()
		preloadFloor(targetFloor + 1)
	end)

	return true
end

function MineFloorManager.ExitMine(player: Player)
	local currentFloor = playerFloors[player]

	-- Update player state
	PlayerDataHandler.SetInMine(player, false)
	PlayerDataHandler.SetCurrentFloor(player, 0)
	PlayerDataHandler.SetActiveTheme(player, DEFAULT_THEME)

	-- Remove from floor tracking (triggers cleanup)
	if currentFloor then
		removePlayerFromFloor(player, currentFloor)
	end

	-- Teleport player back to hub
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.CFrame = CFrame.new(getEntranceTeleportPosition())
		end
	end

	-- Re-preload floor 1 since a player is now above ground
	task.defer(function()
		preloadFloor(1)
	end)

	return true
end

--- Initialize the floor manager: preload floor 1 and set up player disconnect handling.
function MineFloorManager.Init()
	-- Preload floor 1 so it's ready when someone enters the mine
	preloadFloor(1)

	-- Clean up when players disconnect
	Players.PlayerRemoving:Connect(function(player: Player)
		local currentFloor = playerFloors[player]
		if currentFloor then
			PlayerDataHandler.SetInMine(player, false)
			PlayerDataHandler.SetCurrentFloor(player, 0)
			removePlayerFromFloor(player, currentFloor)
		end
	end)

	-- Reset mine state (including ambience) when a character respawns
	local function onCharacterAdded(player: Player)
		local currentFloor = playerFloors[player]
		if currentFloor then
			removePlayerFromFloor(player, currentFloor)
		end
		PlayerDataHandler.SetInMine(player, false)
		PlayerDataHandler.SetCurrentFloor(player, 0)
		PlayerDataHandler.SetActiveTheme(player, DEFAULT_THEME)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function()
			onCharacterAdded(player)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function()
			onCharacterAdded(player)
		end)
	end
end

return MineFloorManager
