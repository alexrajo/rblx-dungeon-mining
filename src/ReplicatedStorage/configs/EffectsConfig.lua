local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)

local EffectsConfig = {}

EffectsConfig.DEFAULT_IMAGE_ID = ItemConfig.DEFAULT_IMAGE_ID

EffectsConfig.effects = {
	speed = {
		displayName = "Speed Boost",
		imageId = EffectsConfig.DEFAULT_IMAGE_ID,
		modifierType = "speed_additive",
		modifierKey = "speedBonus",
	},
	damage = {
		displayName = "Strength Boost",
		imageId = EffectsConfig.DEFAULT_IMAGE_ID,
		modifierType = "damage_multiplier",
		modifierKey = "damageMultiplier",
	},
}

function EffectsConfig.GetEffectData(effectId: string?)
	return EffectsConfig.effects[effectId]
end

function EffectsConfig.GetImageIdForEffect(effectId: string?): string
	local effectData = EffectsConfig.GetEffectData(effectId)
	if effectData ~= nil and effectData.imageId ~= nil then
		return effectData.imageId
	end

	return EffectsConfig.DEFAULT_IMAGE_ID
end

return EffectsConfig
