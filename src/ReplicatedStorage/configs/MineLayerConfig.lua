local MineLayerConfig = {
	-- Global default ore density: fraction of available floor positions that spawn an ore node.
	-- Individual layers may override this with their own oreDensity field.
	defaultOreDensity = 0.08,

	[1] = {
		name = "Shallow Mines",
		theme = "shallow_mines",
		floors = { min = 1, max = 15 },
		minGearTier = 1,
		primaryOre = "Stone",
		secondaryOre = "Copper",
		enemies = { "Cave Slime", "Cave Bat" },
		checkpointInterval = 5,
		floorCompletionBonus = 10,
	},
	[2] = {
		name = "Copper Caves",
		theme = "copper_caves",
		floors = { min = 16, max = 30 },
		minGearTier = 2,
		primaryOre = "Stone",
		secondaryOre = "Iron",
        tertiaryOre = "Copper",
		enemies = { "Goblin", "Shadow Bat" },
		checkpointInterval = 5,
		floorCompletionBonus = 10,
	},
	[3] = {
		name = "Iron Depths",
		theme = "iron_depths",
		floors = { min = 31, max = 50 },
		minGearTier = 3,
		primaryOre = "Stone",
		secondaryOre = "Gold",
		tertiaryOre = "Iron",
		enemies = { "Skeleton", "Rock Golem" },
		checkpointInterval = 5,
		floorCompletionBonus = 10,
	},
	[4] = {
		name = "Golden Caverns",
		theme = "golden_caverns",
		floors = { min = 51, max = 70 },
		minGearTier = 4,
		primaryOre = "Diamond",
		secondaryOre = "Gold",
		tertiaryOre = "Iron",
		enemies = { "Gold Guardian", "Crystal Spider" },
		checkpointInterval = 5,
		floorCompletionBonus = 10,
	},
	[5] = {
		name = "Crystal Hollows",
		theme = "crystal_hollows",
		floors = { min = 71, max = 90 },
		minGearTier = 5,
		primaryOre = "Obsidian",
		secondaryOre = "Diamond",
		tertiaryOre = "Gold",
		enemies = { "Lava Slime", "Obsidian Knight" },
		checkpointInterval = 5,
		floorCompletionBonus = 10,
	},
	[6] = {
		name = "Obsidian Core",
		theme = "obsidian_core",
		floors = { min = 91, max = 120 },
		minGearTier = 6,
		primaryOre = "Mythril",
		secondaryOre = "Obsidian",
		tertiaryOre = "Diamond",
		enemies = { "Fire Elemental", "Magma Wyrm" },
		checkpointInterval = 5,
		floorCompletionBonus = 10,
	},
}

function MineLayerConfig.GetLayerForFloor(floor: number): number?
	for layerNum, layer in pairs(MineLayerConfig) do
		if type(layerNum) == "number" and floor >= layer.floors.min and floor <= layer.floors.max then
			return layerNum
		end
	end
	return nil
end

return MineLayerConfig
