local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local StatCalculation = require(ReplicatedStorage.utils.StatCalculation)

function updateCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local maxHealth = StatCalculation.GetPlayerMaxHealth(1)
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth

	PlayerDataHandler.ApplyPlayerMoveSpeed(player)
end

function playerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		updateCharacter(player, character)
	end)

	local character = player.Character
	if character then
		updateCharacter(player, character)
	end
end

Players.PlayerAdded:Connect(playerAdded)

for _, plr in pairs(Players:GetChildren()) do
	playerAdded(plr)
end
