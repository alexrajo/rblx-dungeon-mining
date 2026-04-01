local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)

local endpoint = {}

function endpoint.Call(player: Player, slotIndex: number)
	return PlayerDataHandler.ClearHotbarSlot(player, slotIndex)
end

return endpoint
