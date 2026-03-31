local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.modules
local MineTransitionService = require(modules.MineTransitionService)

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

		-- Default to floor 1, or the player can choose a checkpoint via UI
		local startFloor = instance:GetAttribute("StartFloor") or 1
		MineTransitionService.StartEnterTransition(player, startFloor)

		task.delay(3, function()
			debounce[player] = nil
		end)
	end)
end

return TagHandler
