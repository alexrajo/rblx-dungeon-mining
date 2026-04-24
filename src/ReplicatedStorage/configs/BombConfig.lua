local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)

local BombConfig = {}

BombConfig.DEFAULT_IMAGE_ID = ItemConfig.DEFAULT_IMAGE_ID

BombConfig.items = {
	["Mini Bomb"] = {
		radius = 10,
		enemyDamage = 30,
		fuseTime = 2.0,
		placementCooldown = 1.0,
	},
	["Big Bomb"] = {
		radius = 16,
		enemyDamage = 60,
		fuseTime = 2.5,
		placementCooldown = 1.5,
	},
	["Mega Bomb"] = {
		radius = 24,
		enemyDamage = 100,
		fuseTime = 3.0,
		placementCooldown = 2.0,
	},
}

function BombConfig.GetBombData(itemName: string?)
	return BombConfig.items[itemName]
end

function BombConfig.IsBombItem(itemName: string?): boolean
	return ItemConfig.IsCategory(itemName, ItemConfig.CATEGORY_BOMB)
end

function BombConfig.GetImageIdForItem(itemName: string): string
	return ItemConfig.GetImageIdForItem(itemName)
end

return BombConfig
