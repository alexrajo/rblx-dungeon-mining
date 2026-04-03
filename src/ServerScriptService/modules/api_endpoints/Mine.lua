local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local OreNodeService = require(modules.OreNodeService)

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

local debounce = {}

local endpoint = {}

function endpoint.Call(player: Player, nodeInstance: Instance, hitPosition: Vector3)
	if debounce[player] then return { success = false, cooldown = 0.1 } end

	-- Validate node exists and is tagged
	if nodeInstance == nil or nodeInstance.Parent == nil then
		return { success = false, cooldown = 0.1 }
	end
	if not CollectionService:HasTag(nodeInstance, "OreNode") then
		return { success = false, cooldown = 0.1 }
	end

	-- Validate player character and range
	local character = player.Character
	if character == nil then return { success = false, cooldown = 0.5 } end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart == nil then return { success = false, cooldown = 0.5 } end

	local nodePosition = nodeInstance:IsA("Model") and nodeInstance:GetPivot().Position or nodeInstance.Position
	local distance = (nodePosition - humanoidRootPart.Position).Magnitude
	if distance > globalConfig.MINE_REACH_DISTANCE then
		return { success = false, cooldown = 0.1 }
	end

	-- Check pickaxe tier
	local equippedPickaxe = PlayerDataHandler.GetEquippedPickaxe(player)
	local pickaxeTier = GearConfig.GetTierForItem(equippedPickaxe) or 1

	local oreType = nodeInstance:GetAttribute("OreType") or "Stone"
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

	-- Apply cooldown
	debounce[player] = true
	task.delay(globalConfig.MINE_SWING_COOLDOWN, function()
		debounce[player] = nil
	end)

	-- Calculate damage
	local miningDamage = StatCalculation.GetMiningDamage(pickaxeTier)

	-- Reduce node HP
	local currentHP = nodeInstance:GetAttribute("CurrentHP") or nodeInstance:GetAttribute("NodeHP") or oreData.nodeHP
	currentHP = currentHP - miningDamage
	nodeInstance:SetAttribute("CurrentHP", currentHP)

	signalTutorialEvent:Fire(player, "mine")

	if currentHP <= 0 then
		OreNodeService.BreakNode(player, nodeInstance)

		return { success = true, cooldown = globalConfig.MINE_SWING_COOLDOWN, broken = true }
	end

	return { success = true, cooldown = globalConfig.MINE_SWING_COOLDOWN, broken = false, remainingHP = currentHP }
end

return endpoint
