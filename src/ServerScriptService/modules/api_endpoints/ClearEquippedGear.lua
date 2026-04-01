local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local endpoint = {}

function endpoint.Call(player: Player, slotName: string)
	if type(slotName) ~= "string" then
		return false
	end
	if not GearConfig.IsArmorSlot(slotName) then
		return false
	end

	return PlayerDataHandler.ClearEquippedGear(player, slotName)
end

return endpoint
