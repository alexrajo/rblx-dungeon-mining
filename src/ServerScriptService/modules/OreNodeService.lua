local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local OreNodeUtil = require(modules.OreNodeUtil)
local WorldSoundService = require(modules.WorldSoundService)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local ItemLookupService = require(Services.ItemLookupService)

local configs = ReplicatedStorage.configs
local OreConfig = require(configs.OreConfig)
local dropsConfig = require(configs.DropsConfig)

local OreNodeService = {}

local ORE_NODE_BREAK_SOUND_ID = "9118587701"

local RE_ItemDrop = APIService.GetEvent("DropItems")

local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial

local function createLadder(position: Vector3, parent: Instance, floorNumber: number?)
	local ladder = Instance.new("Part")
	ladder.Name = "Ladder"
	ladder.Size = Vector3.new(4, 6, 4)
	ladder.Position = position
	ladder.Anchored = true
	ladder.Material = Enum.Material.Wood
	ladder.BrickColor = BrickColor.new("Brown")
	if floorNumber ~= nil then
		ladder:SetAttribute("FloorNumber", floorNumber)
	end
	ladder:SetAttribute("LadderAction", "descend")
	ladder:SetAttribute("LadderVariant", "descending")
	CollectionService:AddTag(ladder, "MineLadder")
	ladder.Parent = parent

	return ladder
end

function OreNodeService.BreakNode(player: Player, nodeInstance: Instance): boolean
	if nodeInstance == nil or nodeInstance.Parent == nil or not nodeInstance:IsA("Model") then
		return false
	end

	local nodeModel = nodeInstance :: Model
	if nodeModel:GetAttribute("Broken") then
		return false
	end
	nodeModel:SetAttribute("Broken", true)

	local oreType = nodeModel:GetAttribute("OreType") or "Stone"
	local oreData = OreConfig.byName[oreType]
	if oreData == nil then
		nodeModel:SetAttribute("Broken", nil)
		return false
	end

	local originalParent = nodeModel.Parent
	local nodePosition = OreNodeUtil.GetPosition(nodeModel)
	local revealPosition = nodePosition + Vector3.new(0, 3, 0)
	local floorNumber = nodeModel:GetAttribute("FloorNumber")
	local revealsLadder = nodeModel:GetAttribute("RevealsLadder")
	local xpReward = math.max(5, oreData.baseValue)

	local dropType = nodeModel:GetAttribute("DropType")
	local itemRewards = {}
	if type(dropType) == "string" then
		itemRewards = dropsConfig.RollLoot(dropType)
	else
		itemRewards[oreType] = 1
	end

	local hasItemRewards = next(itemRewards) ~= nil
	if hasItemRewards then
		if RE_ItemDrop then
			for itemName, amount in pairs(itemRewards) do
				local itemDefinition = ItemLookupService.GetItemDefinitionFromName(itemName)
				if itemDefinition then
					RE_ItemDrop:FireClient(player, amount, nodePosition, itemDefinition)
				end
			end
		end
	end

	PlayerDataHandler.GiveXP(player, xpReward)

	if hasItemRewards then
		PlayerDataHandler.GiveItems(player, itemRewards)

		signalTutorialEvent:Fire(player, "getItem")
	end

	if revealsLadder and originalParent and originalParent.Parent then
		createLadder(revealPosition, originalParent, floorNumber)
	end

	WorldSoundService.PlayOneShotAtPosition(ORE_NODE_BREAK_SOUND_ID, nodePosition)
	nodeModel:Destroy()

	return true
end

return OreNodeService
