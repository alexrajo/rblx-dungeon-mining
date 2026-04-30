local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
local EffectsConfig = require(ReplicatedStorage.configs.EffectsConfig)

local ConsumablesConfig = {}

ConsumablesConfig.DEFAULT_IMAGE_ID = ItemConfig.DEFAULT_IMAGE_ID

-- Client-side cooldown returned immediately after activating a consumable.
ConsumablesConfig.USE_COOLDOWN = 1.0

ConsumablesConfig.items = {
	["Health Potion"] = {
		healAmount = 30,
	},
	["Speed Potion"] = {
		effectId = "speed",
		-- Fraction of DEFAULT_WALKSPEED (16) added as a flat WalkSpeed bonus.
		-- 0.20 -> +3.2 -> rounds to +3 studs/s (~20% increase).
		speedBonus = 0.20,
		duration = 30,
	},
	["Strength Potion"] = {
		effectId = "damage",
		damageMultiplier = 1.25,
		duration = 30,
	},
}

function ConsumablesConfig.GetConsumableData(itemName: string?)
	return ConsumablesConfig.items[itemName]
end

function ConsumablesConfig.IsConsumableItem(itemName: string?): boolean
	return ItemConfig.IsCategory(itemName, ItemConfig.CATEGORY_CONSUMABLE)
end

function ConsumablesConfig.IsStackable(itemName: string?): boolean
	return ItemConfig.IsStackable(itemName)
end

function ConsumablesConfig.GetEffectData(itemName: string?)
	local consumableData = ConsumablesConfig.GetConsumableData(itemName)
	if consumableData == nil then
		return nil
	end

	return EffectsConfig.GetEffectData(consumableData.effectId)
end

function ConsumablesConfig.GetImageIdForItem(itemName: string): string
	return ItemConfig.GetImageIdForItem(itemName)
end

return ConsumablesConfig
