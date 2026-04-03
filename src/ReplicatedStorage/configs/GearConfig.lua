local GearConfig = {}

GearConfig.DEFAULT_IMAGE_ID = "76280156712677"
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

-- Each item maps to a slot and tier
GearConfig.items = {
	-- Tier 1 (Wood) - starting gear
	["Wood Pickaxe"]    = { slot = "Pickaxe", tier = 1 },
	["Wood Sword"]      = { slot = "Weapon", tier = 1, damage = 5, attackCooldown = 0.55, criticalHitChance = 0.1, criticalHitDamage = 1.5, knockback = 40 },
	["Wood Helmet"]     = { slot = "Helmet", tier = 1 },
	["Wood Chestplate"] = { slot = "Chestplate", tier = 1 },
	["Wood Leggings"]   = { slot = "Leggings", tier = 1 },
	["Wood Boots"]      = { slot = "Boots", tier = 1 },

	-- Tier 2 (Copper)
	["Copper Pickaxe"]    = { slot = "Pickaxe", tier = 2 },
	["Copper Sword"]      = { slot = "Weapon", tier = 2, damage = 10, attackCooldown = 0.52, criticalHitChance = 0.1, criticalHitDamage = 1.55, knockback = 48 },
	["Copper Helmet"]     = { slot = "Helmet", tier = 2 },
	["Copper Chestplate"] = { slot = "Chestplate", tier = 2 },
	["Copper Leggings"]   = { slot = "Leggings", tier = 2 },
	["Copper Boots"]      = { slot = "Boots", tier = 2 },

	-- Tier 3 (Iron)
	["Iron Pickaxe"]    = { slot = "Pickaxe", tier = 3 },
	["Iron Sword"]      = { slot = "Weapon", tier = 3, damage = 18, attackCooldown = 0.48, criticalHitChance = 0.1, criticalHitDamage = 1.65, knockback = 56 },
	["Iron Helmet"]     = { slot = "Helmet", tier = 3 },
	["Iron Chestplate"] = { slot = "Chestplate", tier = 3 },
	["Iron Leggings"]   = { slot = "Leggings", tier = 3 },
	["Iron Boots"]      = { slot = "Boots", tier = 3 },

	-- Tier 4 (Gold)
	["Gold Pickaxe"]    = { slot = "Pickaxe", tier = 4 },
	["Gold Sword"]      = { slot = "Weapon", tier = 4, damage = 28, attackCooldown = 0.45, criticalHitChance = 0.14, criticalHitDamage = 1.8, knockback = 64 },
	["Gold Helmet"]     = { slot = "Helmet", tier = 4 },
	["Gold Chestplate"] = { slot = "Chestplate", tier = 4 },
	["Gold Leggings"]   = { slot = "Leggings", tier = 4 },
	["Gold Boots"]      = { slot = "Boots", tier = 4 },

	-- Tier 5 (Diamond)
	["Diamond Pickaxe"]    = { slot = "Pickaxe", tier = 5 },
	["Diamond Sword"]      = { slot = "Weapon", tier = 5, damage = 40, attackCooldown = 0.42, criticalHitChance = 0.18, criticalHitDamage = 2, knockback = 76 },
	["Diamond Helmet"]     = { slot = "Helmet", tier = 5 },
	["Diamond Chestplate"] = { slot = "Chestplate", tier = 5 },
	["Diamond Leggings"]   = { slot = "Leggings", tier = 5 },
	["Diamond Boots"]      = { slot = "Boots", tier = 5 },

	-- Tier 6 (Obsidian)
	["Obsidian Pickaxe"]    = { slot = "Pickaxe", tier = 6 },
	["Obsidian Sword"]      = { slot = "Weapon", tier = 6, damage = 55, attackCooldown = 0.38, criticalHitChance = 0.22, criticalHitDamage = 2.2, knockback = 90 },
	["Obsidian Helmet"]     = { slot = "Helmet", tier = 6 },
	["Obsidian Chestplate"] = { slot = "Chestplate", tier = 6 },
	["Obsidian Leggings"]   = { slot = "Leggings", tier = 6 },
	["Obsidian Boots"]      = { slot = "Boots", tier = 6 },

	-- Bombs
	["Mini Bomb"] = { slot = "Bomb", tier = 1 },
	["Big Bomb"] = { slot = "Bomb", tier = 1 },
	["Mega Bomb"] = { slot = "Bomb", tier = 1 },
}

-- Map slot names to ProfileTemplate field names
GearConfig.slotToField = {
	Pickaxe = "EquippedPickaxe",
	Weapon = "EquippedWeapon",
	Helmet = "EquippedHelmet",
	Chestplate = "EquippedChestplate",
	Leggings = "EquippedLeggings",
	Boots = "EquippedBoots",
}

function GearConfig.GetTierForItem(itemName: string): number?
	local item = GearConfig.items[itemName]
	if item then
		return item.tier
	end
	return nil
end

function GearConfig.GetSlotForItem(itemName: string): string?
	local item = GearConfig.items[itemName]
	if item then
		return item.slot
	end
	return nil
end

function GearConfig.GetImageIdForItem(itemName: string): string
	local item = GearConfig.items[itemName]
	if item and item.imageId ~= nil then
		return item.imageId
	end

	return GearConfig.DEFAULT_IMAGE_ID
end

function GearConfig.GetItemsForSlot(slotName: string): {string}
	local items = {}
	for itemName, itemData in pairs(GearConfig.items) do
		if itemData.slot == slotName then
			table.insert(items, itemName)
		end
	end
	table.sort(items)
	return items
end

function GearConfig.IsArmorSlot(slotName: string): boolean
	return slotName == "Helmet"
		or slotName == "Chestplate"
		or slotName == "Leggings"
		or slotName == "Boots"
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
