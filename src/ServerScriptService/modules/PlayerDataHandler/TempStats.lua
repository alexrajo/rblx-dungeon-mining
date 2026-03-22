local ReplicatedStorage = game:GetService("ReplicatedStorage")
local utils = ReplicatedStorage.utils

local tableUtils = require(utils.TableUtils)

local tempStatsNames = {
	"CurrentFloor",
	"InMine"
}

local module = {}

module.DataFolderMapping = {}

function module:InitializePlayer(player: Player)
	local playerDataFolder
	local allPlayerData = ReplicatedStorage:WaitForChild("PlayerData")
	if allPlayerData then
		playerDataFolder = allPlayerData:WaitForChild(player.Name)
	end

	if playerDataFolder == nil then
		error("TempStats - InitializePlayer: No player data folder found!")
		return
	end

	self.DataFolderMapping[player] = playerDataFolder

	local currentFloor = Instance.new("IntValue")
	currentFloor.Name = "CurrentFloor"
	currentFloor.Parent = playerDataFolder
	currentFloor.Value = 0

	local inMine = Instance.new("BoolValue")
	inMine.Name = "InMine"
	inMine.Parent = playerDataFolder
	inMine.Value = false
end

function module:GetTempStat(player: Player, tempStatName: string): ValueBase
	-- Prevent getting non temp stats using this method
	if not tableUtils.TableContains(tempStatsNames, tempStatName) then return end

	local playerDataFolder = self.DataFolderMapping[player]
	if not playerDataFolder then
		local allPlayerData = ReplicatedStorage:FindFirstChild("PlayerData")
		if allPlayerData then
			playerDataFolder = allPlayerData:FindFirstChild(player.Name)
		end
	end
	if not playerDataFolder then return end

	return playerDataFolder:FindFirstChild(tempStatName)
end

return module
