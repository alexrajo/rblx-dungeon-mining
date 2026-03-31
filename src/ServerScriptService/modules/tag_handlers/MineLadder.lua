local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local MineTransitionService = require(modules.MineTransitionService)

local TagHandler = {}

local debounce = {}

function TagHandler.Apply(instance: Instance)
	local existingPrompt = instance:FindFirstChildOfClass("ProximityPrompt")
	if existingPrompt then
		existingPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Descend"
	prompt.ObjectText = "Ladder"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = instance

	prompt.Triggered:Connect(function(player: Player)
		if Players:GetPlayerFromCharacter(player.Character) ~= player then return end

		if debounce[player] then return end
		debounce[player] = true

		MineTransitionService.StartDescendTransition(player)

		task.delay(2, function()
			debounce[player] = nil
		end)
	end)
end

return TagHandler
