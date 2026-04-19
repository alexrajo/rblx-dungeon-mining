local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local BombConfig = require(ReplicatedStorage.configs.BombConfig)
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)

local GearDetailUtils = {}

local SLOT_STAT_INFO: {[string]: {label: string, field: string}} = {
	Pickaxe = {
		label = "Mining Power",
		field = "pickaxePower",
	},
	Weapon = {
		label = "Damage",
		field = "damage",
	},
	Helmet = {
		label = "Defense",
		field = "armorDefense",
	},
	Chestplate = {
		label = "Defense",
		field = "armorDefense",
	},
	Leggings = {
		label = "Defense",
		field = "armorDefense",
	},
	Boots = {
		label = "Defense",
		field = "armorDefense",
	},
}

local function formatSignedDelta(delta: number): string
	if delta > 0 then
		return string.format(' <font color="#64FF64">(+%d)</font>', delta)
	elseif delta < 0 then
		return string.format(' <font color="#FF6464">(%d)</font>', delta)
	end

	return ""
end

local function getEquippedItemNameForSlot(slotName: string, statsData): string
	local equippedFieldName = GearConfig.slotToField[slotName]
	local equippedEntryId = equippedFieldName and statsData[equippedFieldName] or ""

	if type(equippedEntryId) ~= "string" then
		return ""
	end

	return HotbarConfig.ResolveEntryItemName(equippedEntryId, statsData)
end

local function getPrimaryStatData(itemName: string, statsData)
	local gearInfo = GearConfig.items[itemName]
	if gearInfo == nil then
		return nil
	end

	local statInfo = SLOT_STAT_INFO[gearInfo.slot]
	if BombConfig.IsBombItem(itemName) then
		local bombData = BombConfig.GetBombData(itemName)
		if bombData == nil then
			return nil
		end

		return {
			label = "Enemy Damage",
			value = bombData.enemyDamage,
			equippedItemName = "Hotbar",
			delta = 0,
			statText = string.format("Enemy Damage: %d", bombData.enemyDamage),
			equippedText = "Use from hotbar",
		}
	end

	if statInfo == nil then
		return nil
	end

	local equippedItemName = getEquippedItemNameForSlot(gearInfo.slot, statsData)
	local equippedStatValue = 0
	local newStatValue = 0

	if gearInfo.slot == "Weapon" then
		newStatValue = GearConfig.GetWeaponCombatStats(itemName).damage
		if equippedItemName ~= "" then
			equippedStatValue = GearConfig.GetWeaponCombatStats(equippedItemName).damage
		end
	else
		local tierStats = GearConfig.tiers[gearInfo.tier]
		if tierStats == nil then
			return nil
		end

		local statValue = tierStats[statInfo.field]
		if type(statValue) ~= "number" then
			return nil
		end

		newStatValue = statValue

		if equippedItemName ~= "" then
			local equippedGearInfo = GearConfig.items[equippedItemName]
			local equippedTierStats = equippedGearInfo and GearConfig.tiers[equippedGearInfo.tier]
			local equippedValue = equippedTierStats and equippedTierStats[statInfo.field]
			if type(equippedValue) == "number" then
				equippedStatValue = equippedValue
			end
		end
	end

	local delta = newStatValue - equippedStatValue
	local equippedText = equippedItemName ~= "" and equippedItemName or "None"

	return {
		label = statInfo.label,
		value = newStatValue,
		equippedItemName = equippedText,
		delta = delta,
		statText = string.format("%s: %d%s", statInfo.label, newStatValue, formatSignedDelta(delta)),
		equippedText = string.format("Equipped: %s", equippedText),
	}
end

local function getTierLabel(tier: number?): string
	if type(tier) ~= "number" then
		return "Unknown Tier"
	end

	local tierStats = GearConfig.GetTierStats(tier)
	if tierStats == nil then
		return string.format("Tier %d", tier)
	end

	return string.format("Tier %d %s", tier, tierStats.material)
end

function GearDetailUtils.GetPrimaryComparison(itemName: string, statsData)
	return getPrimaryStatData(itemName, statsData)
end

function GearDetailUtils.GetPopupDetails(itemName: string, statsData)
	local gearInfo = GearConfig.GetItemData(itemName)
	if gearInfo == nil then
		return nil
	end

	local primaryStat = getPrimaryStatData(itemName, statsData)
	local detailLines = {}

	table.insert(detailLines, string.format("Slot: %s", gearInfo.slot))
	if BombConfig.IsBombItem(itemName) then
		local bombData = BombConfig.GetBombData(itemName)
		if bombData == nil then
			return nil
		end

		table.insert(detailLines, "Consumable")
		table.insert(detailLines, string.format("Radius: %d", bombData.radius))
		table.insert(detailLines, "Breaks OreNodes in range")
		table.insert(detailLines, string.format("Max Enemy Damage: %d", bombData.enemyDamage))
		table.insert(detailLines, string.format("Fuse Time: %.1fs", bombData.fuseTime))
	elseif gearInfo.slot == "Weapon" then
		table.insert(detailLines, getTierLabel(gearInfo.tier))
		local weaponStats = GearConfig.GetWeaponCombatStats(itemName)
		table.insert(detailLines, string.format("Damage: %d", weaponStats.damage))
		table.insert(detailLines, string.format("Cooldown: %.2fs", weaponStats.attackCooldown))
		table.insert(detailLines, string.format("Crit Chance: %d%%", math.floor(weaponStats.criticalHitChance * 100 + 0.5)))
		table.insert(detailLines, string.format("Crit Damage: %.2fx", weaponStats.criticalHitDamage))
		table.insert(detailLines, string.format("Knockback: %d", weaponStats.knockback))
	elseif gearInfo.slot == "Pickaxe" then
		table.insert(detailLines, getTierLabel(gearInfo.tier))
		local tierStats = GearConfig.GetTierStats(gearInfo.tier)
		if tierStats ~= nil then
			table.insert(detailLines, string.format("Mining Power: %d", tierStats.pickaxePower))
		end
	else
		table.insert(detailLines, getTierLabel(gearInfo.tier))
		local tierStats = GearConfig.GetTierStats(gearInfo.tier)
		if tierStats ~= nil then
			table.insert(detailLines, string.format("Defense: %d", tierStats.armorDefense))
		end
	end

	return {
		name = itemName,
		slot = gearInfo.slot,
		tier = gearInfo.tier,
		imageId = BombConfig.IsBombItem(itemName)
			and BombConfig.GetImageIdForItem(itemName)
			or GearConfig.GetImageIdForItem(itemName),
		equippedText = primaryStat and primaryStat.equippedText or "Equipped: None",
		primaryStatText = primaryStat and primaryStat.statText or nil,
		detailLines = detailLines,
	}
end

return GearDetailUtils
