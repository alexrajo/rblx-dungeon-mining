local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local QuestService = require(modules.QuestService)
local BossEnemyService = require(modules.BossEnemyService)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local ItemLookupService = require(Services.ItemLookupService)

local configs = ReplicatedStorage.configs
local EnemyConfig = require(configs.EnemyConfig)

local RE_ItemDrop = APIService.GetEvent("DropItems")

local EnemyLootHandler = {}

local function rollRewards(enemyData): {[string]: number}
	local itemRewards = {}

	for _, drop in ipairs(enemyData.drops or {}) do
		if drop.name == "Coins" then
			continue
		end

		local chance = drop.chance or 1.0
		if math.random() <= chance then
			local amount = drop.amount or 1
			if itemRewards[drop.name] then
				itemRewards[drop.name] += amount
			else
				itemRewards[drop.name] = amount
			end
		end
	end

	return itemRewards
end

local function awardEnemyDeath(player: Player, enemyType: string, enemyData, dropPosition: Vector3)
	PlayerDataHandler.GiveXP(player, enemyData.xpReward or 10)
	QuestService.Signal(player, "killEnemy", {
		enemyType = enemyType,
	})

	local itemRewards = rollRewards(enemyData)
	if next(itemRewards) then
		PlayerDataHandler.GiveItems(player, itemRewards)
		if RE_ItemDrop then
			for itemName, amount in pairs(itemRewards) do
				local itemDefinition = ItemLookupService.GetItemDefinitionFromName(itemName)
				if itemDefinition then
					RE_ItemDrop:FireClient(player, amount, dropPosition, itemDefinition)
				end
			end
		end
	end
end

function EnemyLootHandler.HandleDeath(enemyModel: Model)
	local enemyType = enemyModel:GetAttribute("EnemyType")
	if enemyType == nil then return end

	local enemyData = EnemyConfig[enemyType]
	if enemyData == nil then return end

	local dropPosition = enemyModel:GetPivot().Position

	if BossEnemyService.IsBossEnemy(enemyModel) then
		local floorNumber = enemyModel:GetAttribute("FloorNumber")
		if type(floorNumber) ~= "number" then
			return
		end

		for _, player in ipairs(BossEnemyService.GetContributors(enemyModel)) do
			if PlayerDataHandler.GetCurrentFloor(player) == floorNumber then
				awardEnemyDeath(player, enemyType, enemyData, dropPosition)
				PlayerDataHandler.SetLatestCompletedBossFloor(player, floorNumber)
			end
		end
		return
	end

	local lastAttackerRef = enemyModel:FindFirstChild("LastAttacker")
	if lastAttackerRef == nil or lastAttackerRef.Value == nil then return end

	local player = lastAttackerRef.Value
	if not player:IsA("Player") or player.Parent == nil then return end

	awardEnemyDeath(player, enemyType, enemyData, dropPosition)
end

return EnemyLootHandler
