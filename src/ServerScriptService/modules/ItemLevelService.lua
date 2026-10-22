local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
local APIService = require(ReplicatedStorage.services.APIService)
local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)

local ItemLevelService = {}

export type LevelFailure = {
	success: boolean,
	reason: string,
	cooldown: number,
	requiredLevel: number,
	currentLevel: number,
}

local NOTIFICATION_COOLDOWN = 2
local lastNotification: {[Player]: number} = {}

Players.PlayerRemoving:Connect(function(player: Player)
	lastNotification[player] = nil
end)

function ItemLevelService.Check(player: Player, itemName: string, notify: boolean?): LevelFailure?
	local currentLevel = PlayerDataHandler.GetLevel(player)
	if ItemConfig.MeetsLevelRequirement(itemName, currentLevel) then
		return nil
	end

	local requiredLevel = ItemConfig.GetRequiredLevel(itemName)
	local now = os.clock()
	if notify and (lastNotification[player] == nil or now - lastNotification[player] >= NOTIFICATION_COOLDOWN) then
		lastNotification[player] = now
		APIService.GetEvent("SendNotification"):FireClient(player, {
			Type = "info",
			Title = string.format("%s requires level %d. Your level: %d.", itemName, requiredLevel, currentLevel),
		})
	end

	return {
		success = false,
		reason = "level_required",
		cooldown = 0.1,
		requiredLevel = requiredLevel,
		currentLevel = currentLevel,
	}
end

return ItemLevelService
