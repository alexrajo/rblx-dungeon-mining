local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configs = ReplicatedStorage.configs
local DropsConfig = require(Configs.DropsConfig)
local itemDefinitions = DropsConfig.itemDefinitions

local ItemService = {}

function ItemService.GetItemDefinitionFromName(name)
	return itemDefinitions[name]
end

return ItemService
