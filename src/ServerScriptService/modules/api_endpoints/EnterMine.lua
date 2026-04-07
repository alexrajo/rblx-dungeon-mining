local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local MineTransitionService = require(modules.MineTransitionService)

local endpoint = {}

function endpoint.Call(player: Player, startFloor: number)
	if type(startFloor) ~= "number" then startFloor = 1 end
	startFloor = math.floor(startFloor)
	if startFloor < 1 then startFloor = 1 end

	-- Validate checkpoint is unlocked (floor 1 is always available)
	if not PlayerDataHandler.HasUnlockedCheckpoint(player, startFloor, true) then
		return { success = false, reason = "checkpoint_locked" }
	end

	return { success = MineTransitionService.StartEnterTransition(player, startFloor) }
end

return endpoint
