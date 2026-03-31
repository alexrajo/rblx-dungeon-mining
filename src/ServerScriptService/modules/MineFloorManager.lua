local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local CaveUtil = require(modules.CaveUtil)

local configs = ReplicatedStorage.configs
local MineLayerConfig = require(configs.MineLayerConfig)
local OreConfig = require(configs.OreConfig)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

-- Mine area offset — the mine exists far below the hub
local MINE_ORIGIN = Vector3.new(0, -500, 0)
local FLOOR_SPACING = 100 -- Distance between floors on Y axis

-- Hub spawn location (players teleport here when exiting)
local HUB_SPAWN = Vector3.new(0, 10, 0)

-- Floor pool: floorNumber → { folder: Folder, players: {[Player]: true} }
local floorPool: { [number]: { folder: Folder, players: { [Player]: boolean } } } = {}

-- Track which floor each player is on (nil = not in mine / above ground)
local playerFloors: { [Player]: number } = {}

local MineFloorManager = {}

function MineFloorManager.GetLayerForFloor(floor: number): (number?, table?)
	for layerNum, layerData in pairs(MineLayerConfig) do
		if type(layerNum) ~= "number" then continue end
		if floor >= layerData.floors.min and floor <= layerData.floors.max then
			return layerNum, layerData
		end
	end
	return nil, nil
end

-- Ore type → BrickColor mapping
local ORE_COLORS = {
	Stone = BrickColor.new("Medium stone grey"),
	Copper = BrickColor.new("Nougat"),
	Iron = BrickColor.new("Dark stone grey"),
	Gold = BrickColor.new("Bright yellow"),
	Diamond = BrickColor.new("Cyan"),
	Obsidian = BrickColor.new("Really black"),
	Mythril = BrickColor.new("Bright violet"),
}

local NUM_ORE_NODES = 6
local NUM_LIGHTS = 4

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

--- Get the floor origin position for a given floor number.
local function getFloorOrigin(floorNumber: number): Vector3
	return MINE_ORIGIN + Vector3.new(0, -floorNumber * FLOOR_SPACING, 0)
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

function MineFloorManager.SpawnFloor(floorNumber: number): Folder
	local layerNum, layerData = MineFloorManager.GetLayerForFloor(floorNumber)
	if layerData == nil then
		warn("MineFloorManager: No layer data for floor", floorNumber)
		return nil
	end

	-- Create a folder to hold all floor content
	local floorFolder = Instance.new("Folder")
	floorFolder.Name = "MineFloor_" .. floorNumber

	local floorOrigin = getFloorOrigin(floorNumber)

	-- Generate procedural cave
	local caveModel, floorPositions = CaveUtil.GenerateCave(floorOrigin)
	caveModel.Parent = floorFolder

	-- Shuffle floor positions for random placement
	shuffleArray(floorPositions)

	local spawnIndex = 0

	-- Spawn ore nodes on valid floor positions
	local primaryOre = layerData.primaryOre
	local secondaryOre = layerData.secondaryOre

	for i = 1, NUM_ORE_NODES do
		local oreType = (i <= 4) and primaryOre or secondaryOre
		local oreData = OreConfig.byName[oreType]
		if oreData == nil then continue end

		spawnIndex = spawnIndex + 1
		if spawnIndex > #floorPositions then
			warn("MineFloorManager: Not enough floor positions for ore nodes")
			break
		end

		local node = Instance.new("Part")
		node.Name = oreType .. "Node_" .. i
		node.Size = Vector3.new(4, 4, 4)
		node.Shape = Enum.PartType.Block
		node.Position = floorPositions[spawnIndex]
		node.Anchored = true
		node.Material = Enum.Material.Rock
		node.BrickColor = ORE_COLORS[oreType] or BrickColor.new("Medium stone grey")

		node:SetAttribute("OreType", oreType)
		node:SetAttribute("TierRequired", oreData.minPickaxeTier)
		node:SetAttribute("NodeHP", oreData.nodeHP)
		CollectionService:AddTag(node, "OreNode")

		node.Parent = floorFolder
	end

	-- Spawn enemies on floor positions
	local enemyTypes = layerData.enemies
	local NUM_ENEMIES = math.min(3, #enemyTypes * 2)

	for i = 1, NUM_ENEMIES do
		spawnIndex = spawnIndex + 1
		if spawnIndex > #floorPositions then break end

		local enemyType = enemyTypes[math.random(1, #enemyTypes)]

		local enemyModel = Instance.new("Model")
		enemyModel.Name = enemyType

		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Position = floorPositions[spawnIndex] + Vector3.new(0, 1, 0)
		rootPart.Anchored = false
		rootPart.CanCollide = true
		rootPart.BrickColor = BrickColor.new("Bright red")
		rootPart.Parent = enemyModel

		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = enemyModel

		enemyModel.PrimaryPart = rootPart
		enemyModel:SetAttribute("EnemyType", enemyType)
		CollectionService:AddTag(enemyModel, "Enemy")

		enemyModel.Parent = floorFolder
	end

	-- Spawn ladder far from spawn to encourage exploration
	local ladderIndex = math.max(spawnIndex + 1, math.floor(#floorPositions * 0.75))
	if ladderIndex > #floorPositions then ladderIndex = #floorPositions end

	if ladderIndex >= 1 and ladderIndex <= #floorPositions then
		local ladder = Instance.new("Part")
		ladder.Name = "Ladder"
		ladder.Size = Vector3.new(4, 6, 4)
		ladder.Position = floorPositions[ladderIndex] + Vector3.new(0, 1, 0)
		ladder.Anchored = true
		ladder.Material = Enum.Material.Wood
		ladder.BrickColor = BrickColor.new("Brown")
		CollectionService:AddTag(ladder, "MineLadder")
		ladder.Parent = floorFolder
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

	return floorFolder
end

--- Get a floor from the pool, or generate it synchronously as fallback.
local function getOrCreateFloor(floorNumber: number): Folder
	local entry = floorPool[floorNumber]
	if entry then
		return entry.folder
	end

	-- Fallback: generate synchronously
	local folder = MineFloorManager.SpawnFloor(floorNumber)
	if folder then
		floorPool[floorNumber] = { folder = folder, players = {} }
	end
	return folder
end

--- Preload a floor in the background if not already in pool.
local function preloadFloor(floorNumber: number)
	if floorPool[floorNumber] then return end

	local folder = MineFloorManager.SpawnFloor(floorNumber)
	if folder then
		floorPool[floorNumber] = { folder = folder, players = {} }
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

--- Teleport a player to a floor's origin.
local function teleportToFloor(player: Player, floorNumber: number)
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local floorOrigin = getFloorOrigin(floorNumber)
			humanoidRootPart.CFrame = CFrame.new(floorOrigin + Vector3.new(0, 5, 0))
		end
	end
end

function MineFloorManager.EnterMine(player: Player, startFloor: number)
	startFloor = startFloor or 1
	if startFloor < 1 then startFloor = 1 end

	-- Remove from previous floor if re-entering
	local previousFloor = playerFloors[player]
	if previousFloor then
		removePlayerFromFloor(player, previousFloor)
	end

	-- Freeze player to prevent falling if floor needs sync generation
	freezePlayer(player)

	-- Get or create the floor
	local folder = getOrCreateFloor(startFloor)
	if folder == nil then
		unfreezePlayer(player)
		return false
	end

	-- Add player to floor tracking
	addPlayerToFloor(player, startFloor)

	-- Update player state
	PlayerDataHandler.SetInMine(player, true)
	PlayerDataHandler.SetCurrentFloor(player, startFloor)

	-- Teleport player then unfreeze
	teleportToFloor(player, startFloor)
	unfreezePlayer(player)

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
		local checkpointInterval = layerData.checkpointInterval or 5
		if nextFloor % checkpointInterval == 0 or nextFloor == layerData.floors.min then
			PlayerDataHandler.UnlockCheckpoint(player, nextFloor)

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

	-- Remove from old floor, add to new
	local oldFloor = currentFloor
	removePlayerFromFloor(player, oldFloor)
	addPlayerToFloor(player, nextFloor)

	-- Update player state
	PlayerDataHandler.SetCurrentFloor(player, nextFloor)

	-- Teleport player then unfreeze
	teleportToFloor(player, nextFloor)
	unfreezePlayer(player)

	-- Preload next floor in background
	task.defer(function()
		preloadFloor(nextFloor + 1)
	end)

	return true
end

function MineFloorManager.ExitMine(player: Player)
	local currentFloor = playerFloors[player]

	-- Update player state
	PlayerDataHandler.SetInMine(player, false)
	PlayerDataHandler.SetCurrentFloor(player, 0)

	-- Remove from floor tracking (triggers cleanup)
	if currentFloor then
		removePlayerFromFloor(player, currentFloor)
	end

	-- Teleport player back to hub
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.CFrame = CFrame.new(HUB_SPAWN)
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
end

return MineFloorManager
