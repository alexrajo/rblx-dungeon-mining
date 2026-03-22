local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local GearConfig = require(configs.GearConfig)

local endpoint = {}

function endpoint.Call(player: Player, itemName: string)
	if type(itemName) ~= "string" then return false end

	local itemData = GearConfig.items[itemName]
	if itemData == nil then return false end

	local slot = itemData.slot
	local tier = itemData.tier

	-- Tier 1 (Wood) items are always available as starting gear
	if tier > 1 then
		local owned = PlayerDataHandler.GetItemCount(player, itemName)
		if owned <= 0 then return false end
	end

	PlayerDataHandler.EquipGear(player, itemName, slot)
	return true
end

return endpoint
