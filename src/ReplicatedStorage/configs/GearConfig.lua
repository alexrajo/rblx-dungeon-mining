local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)

local GearConfig = {}

GearConfig.DEFAULT_IMAGE_ID = ItemConfig.DEFAULT_IMAGE_ID
GearConfig.DEFAULT_ATTACK_COOLDOWN = 0.5
GearConfig.DEFAULT_CRITICAL_HIT_CHANCE = 0
GearConfig.DEFAULT_CRITICAL_HIT_DAMAGE = 1.5
GearConfig.DEFAULT_KNOCKBACK = 0

GearConfig.tiers = {
	[1] = { material = "Wood", pickaxePower = 1, armorDefense = 2 },
	[2] = { material = "Copper", pickaxePower = 2, armorDefense = 5 },
	[3] = { material = "Iron", pickaxePower = 3, armorDefense = 10 },
	[4] = { material = "Gold", pickaxePower = 4, armorDefense = 16 },
	[5] = { material = "Diamond", pickaxePower = 5, armorDefense = 24 },
	[6] = { material = "Obsidian", pickaxePower = 6, armorDefense = 34 },
}

local gearStats = {
	["Wood Sword"] = { damage = 5, attackCooldown = 0.55, criticalHitChance = 0.1, criticalHitDamage = 1.5, knockback = 40 },
	["Copper Sword"] = { damage = 10, attackCooldown = 0.52, criticalHitChance = 0.1, criticalHitDamage = 1.55, knockback = 48 },
	["Iron Sword"] = { damage = 18, attackCooldown = 0.48, criticalHitChance = 0.1, criticalHitDamage = 1.65, knockback = 56 },
	["Gold Sword"] = { damage = 28, attackCooldown = 0.45, criticalHitChance = 0.14, criticalHitDamage = 1.8, knockback = 64 },
	["Diamond Sword"] = { damage = 40, attackCooldown = 0.42, criticalHitChance = 0.18, criticalHitDamage = 2, knockback = 76 },
	["Obsidian Sword"] = { damage = 55, attackCooldown = 0.38, criticalHitChance = 0.22, criticalHitDamage = 2.2, knockback = 90 },
}

GearConfig.items = {}

for itemName, itemData in pairs(ItemConfig.items) do
	local mergedItem = {}
	local itemStats = gearStats[itemName]

	for key, value in pairs(itemData) do
		mergedItem[key] = value
	end

	if itemStats ~= nil then
		for key, value in pairs(itemStats) do
			mergedItem[key] = value
		end
	end

	GearConfig.items[itemName] = mergedItem
end

-- Map slot names to ProfileTemplate field names
GearConfig.slotToField = {
	Helmet = "EquippedHelmet",
	Chestplate = "EquippedChestplate",
	Leggings = "EquippedLeggings",
	Boots = "EquippedBoots",
}

function GearConfig.GetTierForItem(itemName: string): number?
	local item = ItemConfig.GetItemData(itemName)
	if item then
		return item.tier
	end
	return nil
end

function GearConfig.GetSlotForItem(itemName: string): string?
	return ItemConfig.GetSlotForItem(itemName)
end

function GearConfig.GetImageIdForItem(itemName: string): string
	return ItemConfig.GetImageIdForItem(itemName)
end

function GearConfig.GetItemsForSlot(slotName: string): {string}
	return ItemConfig.GetItemsForSlot(slotName)
end

function GearConfig.IsArmorSlot(slotName: string): boolean
	return slotName == "Helmet"
		or slotName == "Chestplate"
		or slotName == "Leggings"
		or slotName == "Boots"
end

function GearConfig.IsStackable(itemName: string): boolean
	return ItemConfig.IsStackable(itemName)
end

function GearConfig.GetTierStats(tier: number)
	return GearConfig.tiers[tier]
end

function GearConfig.GetItemData(itemName: string?)
	return GearConfig.items[itemName]
end

function GearConfig.GetWeaponCombatStats(itemName: string?): {[string]: number}
	local item = GearConfig.items[itemName]
	if item == nil or item.slot ~= "Weapon" then
		return {
			damage = 0,
			attackCooldown = GearConfig.DEFAULT_ATTACK_COOLDOWN,
			criticalHitChance = GearConfig.DEFAULT_CRITICAL_HIT_CHANCE,
			criticalHitDamage = GearConfig.DEFAULT_CRITICAL_HIT_DAMAGE,
			knockback = GearConfig.DEFAULT_KNOCKBACK,
		}
	end

	return {
		damage = item.damage or 0,
		attackCooldown = item.attackCooldown or GearConfig.DEFAULT_ATTACK_COOLDOWN,
		criticalHitChance = item.criticalHitChance or GearConfig.DEFAULT_CRITICAL_HIT_CHANCE,
		criticalHitDamage = item.criticalHitDamage or GearConfig.DEFAULT_CRITICAL_HIT_DAMAGE,
		knockback = item.knockback or GearConfig.DEFAULT_KNOCKBACK,
	}
end

return GearConfig
