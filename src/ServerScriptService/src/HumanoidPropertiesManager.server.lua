local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

function updateCharacter(character: Model)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local maxHealth = StatCalculation.GetPlayerMaxHealth(1)
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth

	-- Walk speed is base 16, boots bonus applied separately if needed
	humanoid.WalkSpeed = StatCalculation.GetPlayerMoveSpeed(0)
end

function playerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		updateCharacter(character)
	end)

	local character = player.Character
	if character then
		updateCharacter(character)
	end
end

Players.PlayerAdded:Connect(playerAdded)

for _, plr in pairs(Players:GetChildren()) do
	playerAdded(plr)
end
