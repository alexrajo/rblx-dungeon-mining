local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configs = ReplicatedStorage.configs
local DropsConfig = require(Configs.DropsConfig)
local ItemConfig = require(Configs.ItemConfig)
local itemDefinitions = DropsConfig.itemDefinitions

local ItemService = {}

function ItemService.GetItemDefinitionFromName(name)
	local itemDefinition = itemDefinitions[name]
	if itemDefinition ~= nil then
		return itemDefinition
	end

	local itemData = ItemConfig.GetItemData(name)
	if itemData ~= nil then
		return {
			imageId = ItemConfig.GetImageIdForItem(name),
			slot = itemData.slot,
			category = itemData.category,
			stackable = itemData.stackable,
		}
	end

	return nil
end

return ItemService
