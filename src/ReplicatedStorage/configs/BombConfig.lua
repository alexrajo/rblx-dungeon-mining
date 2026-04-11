local BombConfig = {}

BombConfig.DEFAULT_IMAGE_ID = "76280156712677"

BombConfig.items = {
	["Mini Bomb"] = {
		radius = 10,
		enemyDamage = 30,
		fuseTime = 2.0,
		placementCooldown = 1.0,
		imageId = BombConfig.DEFAULT_IMAGE_ID,
	},
	["Big Bomb"] = {
		radius = 16,
		enemyDamage = 60,
		fuseTime = 2.5,
		placementCooldown = 1.5,
		imageId = BombConfig.DEFAULT_IMAGE_ID,
	},
	["Mega Bomb"] = {
		radius = 24,
		enemyDamage = 100,
		fuseTime = 3.0,
		placementCooldown = 2.0,
		imageId = BombConfig.DEFAULT_IMAGE_ID,
	},
}

function BombConfig.GetBombData(itemName: string?)
	return BombConfig.items[itemName]
end

function BombConfig.IsBombItem(itemName: string?): boolean
	return BombConfig.items[itemName] ~= nil
end

function BombConfig.GetImageIdForItem(itemName: string): string
	local item = BombConfig.items[itemName]
	if item and item.imageId ~= nil then
		return item.imageId
	end

	return BombConfig.DEFAULT_IMAGE_ID
end

return BombConfig
