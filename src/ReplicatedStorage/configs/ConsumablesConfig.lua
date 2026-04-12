local ConsumablesConfig = {}

ConsumablesConfig.DEFAULT_IMAGE_ID = "76280156712677"

-- Client-side cooldown returned immediately after activating a consumable.
ConsumablesConfig.USE_COOLDOWN = 1.0

ConsumablesConfig.items = {
	["Health Potion"] = {
		effectType = "heal",
		healAmount = 30,
		imageId = "76280156712677",
	},
	["Speed Potion"] = {
		effectType = "speed",
		-- Fraction of DEFAULT_WALKSPEED (16) added as a flat WalkSpeed bonus.
		-- 0.20 → +3.2 → rounds to +3 studs/s (~20% increase).
		speedBonus = 0.20,
		duration = 30,
		imageId = "76280156712677",
	},
	["Strength Potion"] = {
		effectType = "damage",
		damageMultiplier = 1.25,
		duration = 30,
		imageId = "76280156712677",
	},
}

function ConsumablesConfig.GetConsumableData(itemName: string?)
	return ConsumablesConfig.items[itemName]
end

function ConsumablesConfig.IsConsumableItem(itemName: string?): boolean
	return ConsumablesConfig.items[itemName] ~= nil
end

function ConsumablesConfig.GetImageIdForItem(itemName: string): string
	local item = ConsumablesConfig.items[itemName]
	if item and item.imageId ~= nil then
		return item.imageId
	end
	return ConsumablesConfig.DEFAULT_IMAGE_ID
end

return ConsumablesConfig
