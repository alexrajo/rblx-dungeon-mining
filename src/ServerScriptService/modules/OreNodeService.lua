local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local OreNodeUtil = require(modules.OreNodeUtil)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local configs = ReplicatedStorage.configs
local OreConfig = require(configs.OreConfig)
local dropsConfig = require(configs.DropsConfig)

local OreNodeService = {}

local RE_ItemDrop = APIService.GetEvent("DropItems")

local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial

function OreNodeService.BreakNode(player: Player, nodeInstance: Instance): boolean
	if nodeInstance == nil or nodeInstance.Parent == nil or not nodeInstance:IsA("Model") then
		return false
	end

	local nodeModel = nodeInstance :: Model
	local oreType = nodeModel:GetAttribute("OreType") or "Stone"
	local oreData = OreConfig.byName[oreType]
	if oreData == nil then
		return false
	end

	local nodePosition = OreNodeUtil.GetPosition(nodeModel)
	local xpReward = math.max(5, oreData.baseValue)

	local dropType = nodeModel:GetAttribute("DropType")
	local itemRewards = {}
	if dropType then
		local drops = dropsConfig.types[dropType]
		if drops then
			for dropName, dropChance in pairs(drops) do
				if math.random() <= dropChance then
					itemRewards[dropName] = (itemRewards[dropName] or 0) + 1
				end
			end
		end
	else
		itemRewards[oreType] = 1
	end

	if RE_ItemDrop then
		for itemName, amount in pairs(itemRewards) do
			local itemDefinition = dropsConfig.itemDefinitions[itemName]
			if itemDefinition then
				RE_ItemDrop:FireClient(player, amount, nodePosition, itemDefinition)
			end
		end
	end

	PlayerDataHandler.GiveXP(player, xpReward)
	PlayerDataHandler.GiveItems(player, itemRewards)

	signalTutorialEvent:Fire(player, "getItem")

	local breakEvent = nodeModel:FindFirstChild("NodeBreak")
	if breakEvent and breakEvent:IsA("BindableEvent") then
		breakEvent:Fire()
	end

	return true
end

return OreNodeService
