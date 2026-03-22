local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local StatCalculation = {}

function StatCalculation.GetMiningDamage(pickaxeTier: number): number
	local tierStats = GearConfig.GetTierStats(pickaxeTier)
	if tierStats then
		return tierStats.pickaxePower
	end
	return 1
end

function StatCalculation.GetCombatDamage(weaponTier: number, level: number): number
	local baseDamage = 2 + (level - 1)
	local tierStats = GearConfig.GetTierStats(weaponTier)
	local weaponDamage = 0
	if tierStats then
		weaponDamage = tierStats.weaponDamage
	end
	return baseDamage + weaponDamage
end

function StatCalculation.GetPlayerDefense(helmetTier: number, chestplateTier: number, bootsTier: number): number
	local total = 0
	if helmetTier > 0 then
		local stats = GearConfig.GetTierStats(helmetTier)
		if stats then total += stats.armorDefense end
	end
	if chestplateTier > 0 then
		local stats = GearConfig.GetTierStats(chestplateTier)
		if stats then total += stats.armorDefense end
	end
	if bootsTier > 0 then
		local stats = GearConfig.GetTierStats(bootsTier)
		if stats then total += stats.armorDefense end
	end
	return total
end

function StatCalculation.GetPlayerMaxHealth(level: number): number
	return 100 + 5 * (level - 1)
end

function StatCalculation.GetPlayerMoveSpeed(bootsTier: number): number
	local baseSpeed = 16
	if bootsTier > 0 then
		baseSpeed += bootsTier
	end
	return baseSpeed
end

function StatCalculation.GetLevelUpXPRequirement(currentLevel: number): number
	return 100 * currentLevel * (1.2 ^ (currentLevel - 1))
end

return StatCalculation
