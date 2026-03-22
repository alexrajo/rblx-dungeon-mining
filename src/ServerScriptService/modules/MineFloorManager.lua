local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local MineLayerConfig = require(configs.MineLayerConfig)
local OreConfig = require(configs.OreConfig)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

-- Mine area offset — the mine exists far below the hub
local MINE_ORIGIN = Vector3.new(0, -500, 0)
local FLOOR_SPACING = 100 -- Distance between floors on Y axis

-- Active floor content per player (for v0.1, shared instance)
local activeFloorFolder = nil
local currentFloorNumber = 0

local MineFloorManager = {}

-- Hub spawn location (players teleport here when exiting)
local HUB_SPAWN = Vector3.new(0, 10, 0)

function MineFloorManager.GetLayerForFloor(floor: number): (number?, table?)
	for layerNum, layerData in pairs(MineLayerConfig) do
		if type(layerNum) ~= "number" then continue end
		if floor >= layerData.floors.min and floor <= layerData.floors.max then
			return layerNum, layerData
		end
	end
	return nil, nil
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

	local floorOrigin = MINE_ORIGIN + Vector3.new(0, -floorNumber * FLOOR_SPACING, 0)

	-- Create a simple floor platform
	local platform = Instance.new("Part")
	platform.Name = "FloorPlatform"
	platform.Size = Vector3.new(100, 2, 100)
	platform.Position = floorOrigin
	platform.Anchored = true
	platform.Material = Enum.Material.Slate
	platform.BrickColor = BrickColor.new("Dark stone grey")
	platform.Parent = floorFolder

	-- Walls
	local wallPositions = {
		{ pos = floorOrigin + Vector3.new(50, 15, 0), size = Vector3.new(2, 30, 100) },
		{ pos = floorOrigin + Vector3.new(-50, 15, 0), size = Vector3.new(2, 30, 100) },
		{ pos = floorOrigin + Vector3.new(0, 15, 50), size = Vector3.new(100, 30, 2) },
		{ pos = floorOrigin + Vector3.new(0, 15, -50), size = Vector3.new(100, 30, 2) },
	}
	for i, wallData in ipairs(wallPositions) do
		local wall = Instance.new("Part")
		wall.Name = "Wall_" .. i
		wall.Size = wallData.size
		wall.Position = wallData.pos
		wall.Anchored = true
		wall.Material = Enum.Material.Rock
		wall.BrickColor = BrickColor.new("Dark stone grey")
		wall.Parent = floorFolder
	end

	-- Ceiling
	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Size = Vector3.new(100, 2, 100)
	ceiling.Position = floorOrigin + Vector3.new(0, 30, 0)
	ceiling.Anchored = true
	ceiling.Material = Enum.Material.Rock
	ceiling.BrickColor = BrickColor.new("Really black")
	ceiling.Parent = floorFolder

	-- Spawn ore nodes
	local primaryOre = layerData.primaryOre
	local secondaryOre = layerData.secondaryOre
	local NUM_ORE_NODES = 6

	for i = 1, NUM_ORE_NODES do
		local oreType = (i <= 4) and primaryOre or secondaryOre
		local oreData = OreConfig.byName[oreType]
		if oreData == nil then continue end

		local node = Instance.new("Part")
		node.Name = oreType .. "Node_" .. i
		node.Size = Vector3.new(4, 4, 4)
		node.Shape = Enum.PartType.Block
		node.Position = floorOrigin + Vector3.new(
			math.random(-35, 35),
			3,
			math.random(-35, 35)
		)
		node.Anchored = true
		node.Material = Enum.Material.Rock

		-- Color based on ore type
		if oreType == "Stone" then
			node.BrickColor = BrickColor.new("Medium stone grey")
		elseif oreType == "Copper" then
			node.BrickColor = BrickColor.new("Nougat")
		elseif oreType == "Iron" then
			node.BrickColor = BrickColor.new("Dark stone grey")
		elseif oreType == "Gold" then
			node.BrickColor = BrickColor.new("Bright yellow")
		elseif oreType == "Diamond" then
			node.BrickColor = BrickColor.new("Cyan")
		elseif oreType == "Obsidian" then
			node.BrickColor = BrickColor.new("Really black")
		elseif oreType == "Mythril" then
			node.BrickColor = BrickColor.new("Bright violet")
		end

		node:SetAttribute("OreType", oreType)
		node:SetAttribute("TierRequired", oreData.minPickaxeTier)
		node:SetAttribute("NodeHP", oreData.nodeHP)
		CollectionService:AddTag(node, "OreNode")

		node.Parent = floorFolder
	end

	-- Spawn enemies
	local enemyTypes = layerData.enemies
	local NUM_ENEMIES = math.min(3, #enemyTypes * 2)

	for i = 1, NUM_ENEMIES do
		local enemyType = enemyTypes[math.random(1, #enemyTypes)]

		-- Create a simple enemy model placeholder
		local enemyModel = Instance.new("Model")
		enemyModel.Name = enemyType

		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Position = floorOrigin + Vector3.new(
			math.random(-30, 30),
			3,
			math.random(-30, 30)
		)
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

	-- Spawn ladder to next floor
	local ladder = Instance.new("Part")
	ladder.Name = "Ladder"
	ladder.Size = Vector3.new(4, 6, 4)
	ladder.Position = floorOrigin + Vector3.new(
		math.random(-20, 20),
		4,
		math.random(-20, 20)
	)
	ladder.Anchored = true
	ladder.Material = Enum.Material.Wood
	ladder.BrickColor = BrickColor.new("Brown")
	CollectionService:AddTag(ladder, "MineLadder")
	ladder.Parent = floorFolder

	-- Add lighting
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 0.5
	pointLight.Range = 60
	pointLight.Color = Color3.fromRGB(255, 200, 150)
	pointLight.Parent = platform

	floorFolder.Parent = workspace

	return floorFolder
end

function MineFloorManager.ClearFloor()
	if activeFloorFolder then
		activeFloorFolder:Destroy()
		activeFloorFolder = nil
	end
end

function MineFloorManager.EnterMine(player: Player, startFloor: number)
	startFloor = startFloor or 1
	if startFloor < 1 then startFloor = 1 end

	-- Clear any existing floor
	MineFloorManager.ClearFloor()

	-- Spawn floor
	currentFloorNumber = startFloor
	activeFloorFolder = MineFloorManager.SpawnFloor(currentFloorNumber)

	-- Update player state
	PlayerDataHandler.SetInMine(player, true)
	PlayerDataHandler.SetCurrentFloor(player, currentFloorNumber)

	-- Teleport player
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local floorOrigin = MINE_ORIGIN + Vector3.new(0, -currentFloorNumber * FLOOR_SPACING, 0)
			humanoidRootPart.CFrame = CFrame.new(floorOrigin + Vector3.new(0, 5, 0))
		end
	end

	return true
end

function MineFloorManager.DescendFloor(player: Player)
	local nextFloor = currentFloorNumber + 1

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

	-- Clear and spawn next floor
	MineFloorManager.ClearFloor()
	currentFloorNumber = nextFloor
	activeFloorFolder = MineFloorManager.SpawnFloor(currentFloorNumber)

	-- Update player state
	PlayerDataHandler.SetCurrentFloor(player, currentFloorNumber)

	-- Teleport player
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local floorOrigin = MINE_ORIGIN + Vector3.new(0, -currentFloorNumber * FLOOR_SPACING, 0)
			humanoidRootPart.CFrame = CFrame.new(floorOrigin + Vector3.new(0, 5, 0))
		end
	end

	return true
end

function MineFloorManager.ExitMine(player: Player)
	MineFloorManager.ClearFloor()
	currentFloorNumber = 0

	-- Update player state
	PlayerDataHandler.SetInMine(player, false)
	PlayerDataHandler.SetCurrentFloor(player, 0)

	-- Teleport player back to hub
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.CFrame = CFrame.new(HUB_SPAWN)
		end
	end

	return true
end

return MineFloorManager
