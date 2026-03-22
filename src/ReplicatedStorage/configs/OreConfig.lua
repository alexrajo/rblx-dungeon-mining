local OreConfig = {
	{
		name = "Stone",
		layer = 1,
		minPickaxeTier = 1,
		rarity = "Common",
		baseValue = 1,
		nodeHP = 2,
	},
	{
		name = "Copper",
		layer = 1,
		minPickaxeTier = 1,
		rarity = "Common",
		baseValue = 5,
		nodeHP = 4,
	},
	{
		name = "Iron",
		layer = 2,
		minPickaxeTier = 2,
		rarity = "Common",
		baseValue = 12,
		nodeHP = 6,
	},
	{
		name = "Gold",
		layer = 3,
		minPickaxeTier = 3,
		rarity = "Uncommon",
		baseValue = 25,
		nodeHP = 8,
	},
	{
		name = "Diamond",
		layer = 4,
		minPickaxeTier = 4,
		rarity = "Rare",
		baseValue = 60,
		nodeHP = 12,
	},
	{
		name = "Obsidian",
		layer = 5,
		minPickaxeTier = 5,
		rarity = "Rare",
		baseValue = 120,
		nodeHP = 15,
	},
	{
		name = "Mythril",
		layer = 6,
		minPickaxeTier = 6,
		rarity = "Very Rare",
		baseValue = 250,
		nodeHP = 18,
	},
}

-- Lookup by name for fast access
local byName = {}
for _, ore in ipairs(OreConfig) do
	byName[ore.name] = ore
end

return {
	ores = OreConfig,
	byName = byName,
}
