local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configs = ReplicatedStorage.configs
local DropsConfig = require(Configs.DropsConfig)
local GearConfig = require(Configs.GearConfig)
local BombConfig = require(Configs.BombConfig)
local itemDefinitions = DropsConfig.itemDefinitions

local ItemService = {}

function ItemService.GetItemDefinitionFromName(name)
	local itemDefinition = itemDefinitions[name]
	if itemDefinition ~= nil then
		return itemDefinition
	end

	local gearSlot = GearConfig.GetSlotForItem(name)
	if gearSlot ~= nil then
		local imageId = if BombConfig.IsBombItem(name)
			then BombConfig.GetImageIdForItem(name)
			else GearConfig.GetImageIdForItem(name)
		return {
			imageId = imageId,
		}
	end

	return nil
end

return ItemService
