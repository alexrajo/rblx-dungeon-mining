local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configs = ReplicatedStorage.configs
local DropsConfig = require(Configs.DropsConfig)
local GearConfig = require(Configs.GearConfig)
local itemDefinitions = DropsConfig.itemDefinitions

local ItemService = {}

function ItemService.GetItemDefinitionFromName(name)
	local itemDefinition = itemDefinitions[name]
	if itemDefinition ~= nil then
		return itemDefinition
	end

	local gearSlot = GearConfig.GetSlotForItem(name)
	if gearSlot ~= nil then
		return {
			imageId = GearConfig.GetImageIdForItem(name),
		}
	end

	return nil
end

return ItemService
