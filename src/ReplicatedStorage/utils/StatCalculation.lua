local StatCalculation = {}

function StatCalculation.GetBurpDistance(level: number, burpCharge: number)
	return 8*(1+level*0.2+(burpCharge-1)*0.5)
end

function StatCalculation.GetBurpForce(level: number, burpCharge: number)
	return (100+math.sqrt(level*1000)*burpCharge)*5
end

function StatCalculation.GetBurpDamage(level: number, burpCharge: number)
	return (33+level*2)*(burpCharge/5)
end

function StatCalculation.GetLevelUpXPRequirement(currentLevel: number)
	return 100 * currentLevel * (1.25^(currentLevel-1))
end

function StatCalculation.GetBurpPower(level: number, burpCharge: number)
	return (10*(burpCharge*0.5))*(1.25^(level-1))
end

function StatCalculation.GetCharacterScale(level: number)
	return math.min(1 + level/50, 3)
end

return StatCalculation
