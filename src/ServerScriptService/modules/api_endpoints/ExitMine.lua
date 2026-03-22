local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.modules

local endpoint = {}

function endpoint.Call(player: Player)
	local MineFloorManager = require(modules.MineFloorManager)
	MineFloorManager.ExitMine(player)
	return { success = true }
end

return endpoint
