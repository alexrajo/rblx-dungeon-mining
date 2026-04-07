local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local MineTransitionService = require(modules.MineTransitionService)

local endpoint = {}

function endpoint.Call(player: Player, targetFloor: number)
	if type(targetFloor) ~= "number" then
		return { success = false, reason = "invalid_floor" }
	end

	targetFloor = math.floor(targetFloor)
	if targetFloor < 1 then
		return { success = false, reason = "invalid_floor" }
	end

	if not PlayerDataHandler.HasUnlockedCheckpoint(player, targetFloor, true) then
		return { success = false, reason = "checkpoint_locked" }
	end

	return { success = MineTransitionService.StartCheckpointTransition(player, targetFloor) }
end

return endpoint
