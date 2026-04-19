local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local GearConfig = require(configs.GearConfig)

local endpoint = {}

function endpoint.Call(player: Player, itemId: string)
	if type(itemId) ~= "string" then return false end

	local itemInstance = PlayerDataHandler.GetItemInstance(player, itemId)
	if itemInstance == nil then return false end

	local itemData = GearConfig.items[itemInstance.name]
	if itemData == nil then return false end

	local slot = itemData.slot
	if GearConfig.slotToField[slot] == nil then
		return false
	end

	return PlayerDataHandler.EquipGear(player, itemId, slot)
end

return endpoint
