local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

function updateCharacter(character: Model, scale: number)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local depth = humanoid:FindFirstChild("BodyDepthScale")
	local width = humanoid:FindFirstChild("BodyWidthScale")
	local height = humanoid:FindFirstChild("BodyHeightScale")

	if not depth or not width or not height then
		return
	end

	depth.Value = scale
	width.Value = scale
	height.Value = scale
end

function playerAdded(player: Player)
	local allPlayerData = ReplicatedStorage:WaitForChild("PlayerData")
	local playerData = allPlayerData:WaitForChild(player.Name)
	local levelValue = playerData:WaitForChild("Level")

	player.CharacterAdded:Connect(function(character)
		local scale = StatCalculation.GetCharacterScale(levelValue.Value)
		updateCharacter(character, scale)
	end)

	levelValue.Changed:Connect(function(level)
		local scale = StatCalculation.GetCharacterScale(level)
		local character = player.Character
		if character then
			updateCharacter(character, scale)
		end
	end)

	local character = player.Character
	if character then
		local scale = StatCalculation.GetCharacterScale(levelValue.Value)
		updateCharacter(character, scale)
	end
end

Players.PlayerAdded:Connect(playerAdded)

for _, plr in pairs(Players:GetChildren()) do
	playerAdded(plr)
end

