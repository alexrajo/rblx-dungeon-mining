local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local configs = ReplicatedStorage.configs
local EnemyConfig = require(configs.EnemyConfig)
local dropsConfig = require(configs.DropsConfig)

local RE_CoinDrop = APIService.GetEvent("DropCoins")
local RE_ItemDrop = APIService.GetEvent("DropItems")

local EnemyLootHandler = {}

function EnemyLootHandler.HandleDeath(enemyModel: Model)
	-- Find the player who killed this enemy
	local lastAttackerRef = enemyModel:FindFirstChild("LastAttacker")
	if lastAttackerRef == nil or lastAttackerRef.Value == nil then return end

	local player = lastAttackerRef.Value
	if not player:IsA("Player") or player.Parent == nil then return end

	local enemyType = enemyModel:GetAttribute("EnemyType")
	if enemyType == nil then return end

	local enemyData = EnemyConfig[enemyType]
	if enemyData == nil then return end

	local dropPosition = enemyModel:GetPivot().Position

	-- Award XP
	PlayerDataHandler.GiveXP(player, enemyData.xpReward or 10)

	-- Process drops
	local itemRewards = {}

	for _, drop in ipairs(enemyData.drops) do
		if drop.name == "Coins" then continue end

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

	-- Award items
	if next(itemRewards) then
		PlayerDataHandler.GiveItems(player, itemRewards)
		if RE_ItemDrop then
			for itemName, amount in pairs(itemRewards) do
				local itemDefinition = dropsConfig.itemDefinitions[itemName]
				if itemDefinition then
					RE_ItemDrop:FireClient(player, amount, dropPosition, itemDefinition)
				end
			end
		end
	end
end

return EnemyLootHandler
