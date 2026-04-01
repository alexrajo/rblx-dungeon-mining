local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)

local endpoint = {}

function endpoint.Call(player: Player, slotIndex: number, entryId: string)
	return PlayerDataHandler.AssignHotbarEntry(player, slotIndex, entryId)
end

return endpoint
