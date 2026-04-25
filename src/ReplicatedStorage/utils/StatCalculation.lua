local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local StatCalculation = {}

local function getWeaponDamage(weapon: any): number
	if type(weapon) == "string" then
		return GearConfig.GetWeaponCombatStats(weapon).damage
	end

	return GearConfig.GetWeaponCombatStats(nil).damage
end

function StatCalculation.GetMiningDamage(pickaxeItemName: string?): number
	return GearConfig.GetMiningStats(pickaxeItemName).pickaxePower
end

function StatCalculation.GetCombatDamage(weapon: any, level: number): number
	local baseDamage = 2 + (level - 1)
	local weaponDamage = getWeaponDamage(weapon)
	return baseDamage + weaponDamage
end

function StatCalculation.GetPlayerDefense(
	helmetItemName: string?,
	chestplateItemName: string?,
	leggingsItemName: string?,
	bootsItemName: string?
): number
	return GearConfig.GetArmorStats(helmetItemName).armorDefense
		+ GearConfig.GetArmorStats(chestplateItemName).armorDefense
		+ GearConfig.GetArmorStats(leggingsItemName).armorDefense
		+ GearConfig.GetArmorStats(bootsItemName).armorDefense
end

function StatCalculation.GetPlayerMaxHealth(_level: number): number
	return 100
end

function StatCalculation.GetPlayerMoveSpeed(bootsItemName: string?): number
	return 16 + GearConfig.GetMoveSpeedBonus(bootsItemName)
end

function StatCalculation.GetLevelUpXPRequirement(currentLevel: number): number
	return 100 * currentLevel * (1.2 ^ (currentLevel - 1))
end

return StatCalculation
