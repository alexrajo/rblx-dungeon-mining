local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local BombConfig = require(ReplicatedStorage.configs.BombConfig)
local ConsumablesConfig = require(ReplicatedStorage.configs.ConsumablesConfig)
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
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

local function getStatValue(itemName: string, slotName: string, statField: string): number?
	if slotName == "Weapon" and statField == "damage" then
		return GearConfig.GetWeaponCombatStats(itemName).damage
	elseif slotName == "Pickaxe" and statField == "pickaxePower" then
		return GearConfig.GetMiningStats(itemName).pickaxePower
	elseif GearConfig.IsArmorSlot(slotName) and statField == "armorDefense" then
		return GearConfig.GetArmorStats(itemName).armorDefense
	end

	local gearInfo = GearConfig.GetItemData(itemName)
	local statValue = gearInfo and gearInfo[statField]
	return type(statValue) == "number" and statValue or nil
end

local function getPrimaryStatData(itemName: string, statsData)
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

	local gearInfo = GearConfig.GetItemData(itemName)
	if gearInfo == nil or gearInfo.category ~= ItemConfig.CATEGORY_GEAR then
		return nil
	end

	local statInfo = SLOT_STAT_INFO[gearInfo.slot]
	if statInfo == nil then
		return nil
	end

	local equippedItemName = getEquippedItemNameForSlot(gearInfo.slot, statsData)
	local equippedStatValue = 0
	local newStatValue = getStatValue(itemName, gearInfo.slot, statInfo.field)
	if newStatValue == nil then
		return nil
	end

	if equippedItemName ~= "" then
		local equippedValue = getStatValue(equippedItemName, gearInfo.slot, statInfo.field)
		if equippedValue ~= nil then
			equippedStatValue = equippedValue
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

local function formatDuration(duration: number?): string
	if type(duration) ~= "number" then
		return ""
	end

	return string.format("Duration: %ds", duration)
end

local function getConsumableDetailLines(itemName: string)
	local consumableData = ConsumablesConfig.GetConsumableData(itemName)
	if consumableData == nil then
		return nil
	end

	local detailLines = {}

	if consumableData.healAmount ~= nil then
		table.insert(detailLines, string.format("Restores: %d HP", consumableData.healAmount or 0))
	elseif consumableData.effectId == "speed" then
		local speedPercent = math.floor((consumableData.speedBonus or 0) * 100 + 0.5)
		table.insert(detailLines, string.format("Move Speed: +%d%%", speedPercent))
		table.insert(detailLines, formatDuration(consumableData.duration))
	elseif consumableData.effectId == "damage" then
		local damagePercent = math.floor(((consumableData.damageMultiplier or 1) - 1) * 100 + 0.5)
		table.insert(detailLines, string.format("Damage: +%d%%", damagePercent))
		table.insert(detailLines, formatDuration(consumableData.duration))
	end

	return detailLines
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
	elseif ConsumablesConfig.IsConsumableItem(itemName) then
		detailLines = getConsumableDetailLines(itemName)
		if detailLines == nil then
			return nil
		end
	elseif gearInfo.slot == "Weapon" then
		local weaponStats = GearConfig.GetWeaponCombatStats(itemName)
		table.insert(detailLines, string.format("Damage: %d", weaponStats.damage))
		table.insert(detailLines, string.format("Cooldown: %.2fs", weaponStats.attackCooldown))
		table.insert(detailLines, string.format("Crit Chance: %d%%", math.floor(weaponStats.criticalHitChance * 100 + 0.5)))
		table.insert(detailLines, string.format("Crit Damage: %.2fx", weaponStats.criticalHitDamage))
		table.insert(detailLines, string.format("Knockback: %d", weaponStats.knockback))
	elseif gearInfo.slot == "Pickaxe" then
		local miningStats = GearConfig.GetMiningStats(itemName)
		table.insert(detailLines, string.format("Mining Power: %d", miningStats.pickaxePower))
	elseif GearConfig.IsArmorSlot(gearInfo.slot) then
		local armorStats = GearConfig.GetArmorStats(itemName)
		table.insert(detailLines, string.format("Defense: %d", armorStats.armorDefense))
		if gearInfo.slot == "Boots" then
			table.insert(detailLines, string.format("Move Speed: +%d", GearConfig.GetMoveSpeedBonus(itemName)))
		end
	end

	return {
		name = itemName,
		slot = gearInfo.slot,
		imageId = ItemConfig.GetImageIdForItem(itemName),
		equippedText = primaryStat and primaryStat.equippedText or "Equipped: None",
		primaryStatText = primaryStat and primaryStat.statText or nil,
		detailLines = detailLines,
	}
end

return GearDetailUtils
