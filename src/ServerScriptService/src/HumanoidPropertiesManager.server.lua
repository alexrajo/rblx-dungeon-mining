local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

function updateCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local maxHealth = StatCalculation.GetPlayerMaxHealth(1)
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth

	local bootsItemName = PlayerDataHandler.GetEquippedBootsItemName(player)
	humanoid.WalkSpeed = StatCalculation.GetPlayerMoveSpeed(bootsItemName ~= "" and bootsItemName or nil)
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
