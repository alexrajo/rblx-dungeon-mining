local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.modules
local MineTransitionService = require(modules.MineTransitionService)

local endpoint = {}

function endpoint.Call(player: Player)
	return { success = MineTransitionService.StartExitTransition(player) }
end

return endpoint
