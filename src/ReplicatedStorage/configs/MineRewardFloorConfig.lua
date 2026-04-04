local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configs = ReplicatedStorage.configs
local DropsConfig = require(Configs.DropsConfig)
local GearConfig = require(Configs.GearConfig)

local MineRewardFloorConfig = {
	[10] = {
		itemName = "Copper",
		amount = 25,
	},
	[20] = {
		itemName = "Iron",
		amount = 20,
	},
	[30] = {
		itemName = "Gold",
		amount = 15,
	},
	[40] = {
		itemName = "Iron Sword",
		amount = 1,
	},
	[50] = {
		itemName = "Diamond",
		amount = 10,
	},
	[60] = {
		itemName = "Gold Chestplate",
		amount = 1,
	},
	[70] = {
		itemName = "Obsidian",
		amount = 8,
	},
	[80] = {
		itemName = "Diamond Sword",
		amount = 1,
	},
	[90] = {
		itemName = "Fire Essence",
		amount = 12,
	},
	[100] = {
		itemName = "Obsidian Sword",
		amount = 1,
	},
	[110] = {
		itemName = "Mythril",
		amount = 6,
	},
	[120] = {
		itemName = "Mythril",
		amount = 20,
	},
}

local function isValidRewardEntry(entry): boolean
	if typeof(entry) ~= "table" then
		return false
	end

	if type(entry.itemName) ~= "string" or entry.itemName == "" then
		return false
	end

	if type(entry.amount) ~= "number" or entry.amount < 1 then
		return false
	end

	if DropsConfig.itemDefinitions[entry.itemName] ~= nil then
		return true
	end

	return GearConfig.GetItemData(entry.itemName) ~= nil
end

function MineRewardFloorConfig.IsRewardFloor(floorNumber: number): boolean
	return type(floorNumber) == "number"
		and floorNumber >= 1
		and floorNumber % 10 == 0
		and MineRewardFloorConfig[floorNumber] ~= nil
end

function MineRewardFloorConfig.GetRewardForFloor(floorNumber: number)
	local rewardData = MineRewardFloorConfig[floorNumber]
	if not isValidRewardEntry(rewardData) then
		return nil
	end

	return rewardData
end

return MineRewardFloorConfig
