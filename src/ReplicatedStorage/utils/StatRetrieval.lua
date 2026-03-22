local StatRetrieval = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dataFolder = ReplicatedStorage:WaitForChild("PlayerData")

function StatRetrieval.GetPlayerStat(statName: string, player: Player)
	local playerDataFolder = dataFolder:FindFirstChild(player.Name)
	if not playerDataFolder then return nil end
	
	local stat: ValueBase = playerDataFolder:FindFirstChild(statName)
	if not stat then return nil end
	
	return stat.Value
end

function StatRetrieval.GetPlayerStatInstance(statName, player)
	local playerDataFolder = dataFolder:WaitForChild(player.Name)
	if not playerDataFolder then return nil end

	local stat: ValueBase = playerDataFolder:WaitForChild(statName)
	if not stat then return nil end

	return stat
end

return StatRetrieval
