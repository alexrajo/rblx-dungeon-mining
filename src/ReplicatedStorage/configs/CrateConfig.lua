local CrateConfig = {
	defaultCrateDensity = 0.0025,
	defaultHealth = 1,

	loot = {
		{
			itemName = "Wood",
			minAmount = 2,
			maxAmount = 5,
			chance = 1.0,
		},
		{
			itemName = "Health Potion",
			minAmount = 1,
			maxAmount = 1,
			chance = 1.0,
		},
	},
}

function CrateConfig.RollLoot(): {[string]: number}
	local rewards = {}

	for _, entry in ipairs(CrateConfig.loot) do
		local itemName = entry.itemName
		if type(itemName) ~= "string" or itemName == "" then
			continue
		end

		local chance = if type(entry.chance) == "number" then entry.chance else 1
		if math.random() > chance then
			continue
		end

		local minAmount = if type(entry.minAmount) == "number" then entry.minAmount else 1
		local maxAmount = if type(entry.maxAmount) == "number" then entry.maxAmount else minAmount
		minAmount = math.max(1, math.floor(minAmount))
		maxAmount = math.max(minAmount, math.floor(maxAmount))

		local amount = math.random(minAmount, maxAmount)
		rewards[itemName] = (rewards[itemName] or 0) + amount
	end

	return rewards
end

return CrateConfig
