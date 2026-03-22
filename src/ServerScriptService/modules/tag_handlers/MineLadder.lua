local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.modules

local TagHandler = {}

local debounce = {}

function TagHandler.Apply(instance: Instance)
	instance.Touched:Connect(function(hit)
		local character = hit.Parent
		if character == nil then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid == nil then return end

		local player = game.Players:GetPlayerFromCharacter(character)
		if player == nil then return end

		if debounce[player] then return end
		debounce[player] = true

		-- Lazy require to avoid circular dependency at module load time
		local MineFloorManager = require(modules.MineFloorManager)
		MineFloorManager.DescendFloor(player)

		task.delay(2, function()
			debounce[player] = nil
		end)
	end)
end

return TagHandler
