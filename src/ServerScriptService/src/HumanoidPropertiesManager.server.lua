local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)
local GlobalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))

function updateCharacter(character: Model, level: number)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	humanoid.WalkSpeed = GlobalConfig.DEFAULT_WALKSPEED
	humanoid.MaxHealth = math.max(GlobalConfig.DEFAULT_MAXHEALTH, 100 + level^1.5)
	humanoid.Health = humanoid.MaxHealth
end

function playerAdded(player: Player)
	local allPlayerData = ReplicatedStorage:WaitForChild("PlayerData")
	local playerData = allPlayerData:WaitForChild(player.Name)
	local levelValue = playerData:WaitForChild("Level")
	
	player.CharacterAdded:Connect(function(character)
		updateCharacter(character, levelValue.Value)
	end)
	
	levelValue.Changed:Connect(function(level)
		local character = player.Character
		if character then
			updateCharacter(character, levelValue.Value)
		end
	end)
	
	local character = player.Character
	if character then
		updateCharacter(character, levelValue.Value)
	end
end

Players.PlayerAdded:Connect(playerAdded)

for _, plr in pairs(Players:GetChildren()) do
	playerAdded(plr)
end