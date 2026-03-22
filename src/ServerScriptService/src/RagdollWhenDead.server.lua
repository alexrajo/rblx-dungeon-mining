local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.modules
local RagdollUtils = require(modules.RagdollUtils)

game.Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			RagdollUtils.ActivateRagdoll(char)
		end)
	end)
end)