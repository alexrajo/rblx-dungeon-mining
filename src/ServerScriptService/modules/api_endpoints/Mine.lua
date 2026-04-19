local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerScriptService.modules
local CrateService = require(modules.CrateService)
local HotbarToolValidator = require(modules.HotbarToolValidator)
local OreNodeService = require(modules.OreNodeService)
local OreNodeUtil = require(modules.OreNodeUtil)
local PlayerDataHandler = require(modules.PlayerDataHandler)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

local configs = ReplicatedStorage.configs
local OreConfig = require(configs.OreConfig)
local GearConfig = require(configs.GearConfig)
local globalConfig = require(ReplicatedStorage.GlobalConfig)

-- Cross script communication
local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial

-- Timestamp-based per-player cooldown. Keyed by Player instance so entries
-- are automatically distinct across sessions; cleaned up on PlayerRemoving.
local lastMineTime: {[Player]: number} = {}

Players.PlayerRemoving:Connect(function(player)
	lastMineTime[player] = nil
end)

local endpoint = {}

local function findTaggedAncestor(instance: Instance, tagName: string): Instance?
	local current = instance
	while current and current ~= workspace do
		if CollectionService:HasTag(current, tagName) then
			return current
		end
		current = current.Parent
	end

	return nil
end

local function isOnPlayerFloor(player: Player, instance: Instance): boolean
	local floorNumber = instance:GetAttribute("FloorNumber")
	return type(floorNumber) ~= "number" or PlayerDataHandler.GetCurrentFloor(player) == floorNumber
end

function endpoint.Call(player: Player, tool: Instance?, nodeInstance: Instance, hitPosition: Vector3)
	local now = os.clock()
	local serverWindow = globalConfig.MINE_SWING_COOLDOWN - globalConfig.SERVER_ACTION_LENIENCY
	if lastMineTime[player] and (now - lastMineTime[player]) < serverWindow then
		return { success = false, cooldown = 0.1 }
	end

	local validTool, pickaxeItemName, toolReason = HotbarToolValidator.Validate(player, tool, "Mine", "Pickaxe")
	if not validTool or pickaxeItemName == nil then
		return { success = false, cooldown = 0.1, reason = toolReason }
	end

	-- Validate target exists and is tagged
	if nodeInstance == nil or nodeInstance.Parent == nil then
		return { success = false, cooldown = 0.1 }
	end

	local crateInstance = findTaggedAncestor(nodeInstance, "MineCrate")
	local oreNodeInstance = findTaggedAncestor(nodeInstance, "OreNode")
	if crateInstance == nil and oreNodeInstance == nil then
		return { success = false, cooldown = 0.1 }
	end

	-- Validate player character and range
	local character = player.Character
	if character == nil then return { success = false, cooldown = 0.5 } end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart == nil then return { success = false, cooldown = 0.5 } end

	-- Check pickaxe tier from the wielded tool.
	local pickaxeTier = GearConfig.GetTierForItem(pickaxeItemName) or 1

	if crateInstance ~= nil then
		if not isOnPlayerFloor(player, crateInstance) then
			return { success = false, cooldown = 0.1 }
		end

		local cratePosition = CrateService.GetPosition(crateInstance)
		local distance = (cratePosition - humanoidRootPart.Position).Magnitude
		if distance > globalConfig.MINE_REACH_DISTANCE then
			return { success = false, cooldown = 0.1 }
		end

		lastMineTime[player] = os.clock()

		local miningDamage = StatCalculation.GetMiningDamage(pickaxeTier)
		local currentHP = crateInstance:GetAttribute("CurrentHP") or crateInstance:GetAttribute("CrateHP") or 1
		currentHP -= miningDamage
		crateInstance:SetAttribute("CurrentHP", currentHP)

		signalTutorialEvent:Fire(player, "mine")

		if currentHP <= 0 then
			CrateService.BreakCrate(player, crateInstance)
			return { success = true, cooldown = globalConfig.MINE_SWING_COOLDOWN, broken = true }
		end

		return { success = true, cooldown = globalConfig.MINE_SWING_COOLDOWN, broken = false, remainingHP = currentHP }
	end

	if oreNodeInstance == nil or not oreNodeInstance:IsA("Model") then
		return { success = false, cooldown = 0.1 }
	end

	local nodeModel = oreNodeInstance :: Model
	local nodePosition = OreNodeUtil.GetPosition(nodeModel)
	local distance = (nodePosition - humanoidRootPart.Position).Magnitude
	if distance > globalConfig.MINE_REACH_DISTANCE then
		return { success = false, cooldown = 0.1 }
	end

	local oreType = nodeModel:GetAttribute("OreType") or "Stone"
	local oreData = OreConfig.byName[oreType]
	if oreData == nil then
		return { success = false, cooldown = 0.5 }
	end

	if pickaxeTier < oreData.minPickaxeTier then
		-- Pickaxe too weak — bounce off feedback
		return {
			success = false,
			cooldown = 0.5,
			reason = "tier_too_low",
			requiredTier = oreData.minPickaxeTier,
			pickaxeTier = pickaxeTier,
		}
	end

	-- Record the accepted action time (no task.delay needed with timestamp approach)
	lastMineTime[player] = os.clock()

	-- Calculate damage
	local miningDamage = StatCalculation.GetMiningDamage(pickaxeTier)

	-- Reduce node HP
	local currentHP = nodeModel:GetAttribute("CurrentHP") or nodeModel:GetAttribute("NodeHP") or oreData.nodeHP
	currentHP = currentHP - miningDamage
	nodeModel:SetAttribute("CurrentHP", currentHP)

	signalTutorialEvent:Fire(player, "mine")

	if currentHP <= 0 then
		OreNodeService.BreakNode(player, nodeModel)

		return { success = true, cooldown = globalConfig.MINE_SWING_COOLDOWN, broken = true }
	end

	return { success = true, cooldown = globalConfig.MINE_SWING_COOLDOWN, broken = false, remainingHP = currentHP }
end

return endpoint
