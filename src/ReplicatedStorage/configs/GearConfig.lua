local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)

local GearConfig = {}

GearConfig.DEFAULT_IMAGE_ID = ItemConfig.DEFAULT_IMAGE_ID
GearConfig.DEFAULT_ATTACK_COOLDOWN = 0.5
GearConfig.DEFAULT_CRITICAL_HIT_CHANCE = 0
GearConfig.DEFAULT_CRITICAL_HIT_DAMAGE = 1.5
GearConfig.DEFAULT_KNOCKBACK = 0

local gearStats = {
	["Wood Pickaxe"] = { pickaxePower = 1 },
	["Wood Sword"] = { damage = 5, attackCooldown = 0.55, criticalHitChance = 0.1, criticalHitDamage = 1.5, knockback = 40 },
	["Wood Helmet"] = { armorDefense = 2 },
	["Wood Chestplate"] = { armorDefense = 2 },
	["Wood Leggings"] = { armorDefense = 2 },
	["Wood Boots"] = { armorDefense = 2, moveSpeedBonus = 1 },

	["Copper Pickaxe"] = { pickaxePower = 2 },
	["Copper Sword"] = { damage = 10, attackCooldown = 0.52, criticalHitChance = 0.1, criticalHitDamage = 1.55, knockback = 48 },
	["Copper Helmet"] = { armorDefense = 5 },
	["Copper Chestplate"] = { armorDefense = 5 },
	["Copper Leggings"] = { armorDefense = 5 },
	["Copper Boots"] = { armorDefense = 5, moveSpeedBonus = 2 },

	["Iron Pickaxe"] = { pickaxePower = 3 },
	["Iron Sword"] = { damage = 18, attackCooldown = 0.48, criticalHitChance = 0.1, criticalHitDamage = 1.65, knockback = 56 },
	["Iron Helmet"] = { armorDefense = 10 },
	["Iron Chestplate"] = { armorDefense = 10 },
	["Iron Leggings"] = { armorDefense = 10 },
	["Iron Boots"] = { armorDefense = 10, moveSpeedBonus = 3 },

	["Gold Pickaxe"] = { pickaxePower = 4 },
	["Gold Sword"] = { damage = 28, attackCooldown = 0.45, criticalHitChance = 0.14, criticalHitDamage = 1.8, knockback = 64 },
	["Gold Helmet"] = { armorDefense = 16 },
	["Gold Chestplate"] = { armorDefense = 16 },
	["Gold Leggings"] = { armorDefense = 16 },
	["Gold Boots"] = { armorDefense = 16, moveSpeedBonus = 4 },

	["Diamond Pickaxe"] = { pickaxePower = 5 },
	["Diamond Sword"] = { damage = 40, attackCooldown = 0.42, criticalHitChance = 0.18, criticalHitDamage = 2, knockback = 76 },
	["Diamond Helmet"] = { armorDefense = 24 },
	["Diamond Chestplate"] = { armorDefense = 24 },
	["Diamond Leggings"] = { armorDefense = 24 },
	["Diamond Boots"] = { armorDefense = 24, moveSpeedBonus = 5 },

	["Obsidian Pickaxe"] = { pickaxePower = 6 },
	["Obsidian Sword"] = { damage = 55, attackCooldown = 0.38, criticalHitChance = 0.22, criticalHitDamage = 2.2, knockback = 90 },
	["Obsidian Helmet"] = { armorDefense = 34 },
	["Obsidian Chestplate"] = { armorDefense = 34 },
	["Obsidian Leggings"] = { armorDefense = 34 },
	["Obsidian Boots"] = { armorDefense = 34, moveSpeedBonus = 6 },
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

function GearConfig.GetItemData(itemName: string?)
	return GearConfig.items[itemName]
end

function GearConfig.GetMiningStats(itemName: string?): {[string]: number}
	local item = GearConfig.items[itemName]
	if item == nil or item.slot ~= "Pickaxe" then
		return {
			pickaxePower = 1,
		}
	end

	return {
		pickaxePower = item.pickaxePower or 1,
	}
end

function GearConfig.GetArmorStats(itemName: string?): {[string]: number}
	local item = GearConfig.items[itemName]
	if item == nil or not GearConfig.IsArmorSlot(item.slot) then
		return {
			armorDefense = 0,
		}
	end

	return {
		armorDefense = item.armorDefense or 0,
	}
end

function GearConfig.GetMoveSpeedBonus(itemName: string?): number
	local item = GearConfig.items[itemName]
	if item == nil or item.slot ~= "Boots" then
		return 0
	end

	return item.moveSpeedBonus or 0
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
