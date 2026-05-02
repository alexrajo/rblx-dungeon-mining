local MineLayerConfig = {
	-- Global default ore density: fraction of available floor positions that spawn an ore node.
	-- Individual layers may override this with their own oreDensity field.
	defaultOreDensity = 0.04,
	-- Global default enemy density: fraction of available floor positions that spawn an enemy.
	-- Individual layers may override this with their own enemyDensity field.
	defaultEnemyDensity = 0.005,
	defaultBossEnemy = "Cave Slime",
	checkpointInterval = 5,
	-- Optional per-layer field: bossRoom = "RoomModelName".
	-- Layer-end floors use ServerStorage.BossRooms.Default when omitted.

	[1] = {
		name = "Shallow Mines",
		theme = "shallow_mines",
		floors = { min = 1, max = 15 },
		primaryOre = "Stone",
		secondaryOre = "Copper",
		enemies = { "Cave Slime", "Cave Bat" },
		floorCompletionBonus = 10,
        enemyDensity = 0.003, -- Override default enemy density for this layer
	},
	[2] = {
		name = "Copper Caves",
		theme = "copper_caves",
		floors = { min = 16, max = 30 },
		primaryOre = "Stone",
		secondaryOre = "Iron",
		tertiaryOre = "Copper",
		enemies = { "Goblin", "Shadow Bat" },
		floorCompletionBonus = 10,
	},
	[3] = {
		name = "Iron Depths",
		theme = "iron_depths",
		floors = { min = 31, max = 50 },
		primaryOre = "Stone",
		secondaryOre = "Gold",
		tertiaryOre = "Iron",
		enemies = { "Skeleton", "Rock Golem" },
		floorCompletionBonus = 10,
	},
	[4] = {
		name = "Golden Caverns",
		theme = "golden_caverns",
		floors = { min = 51, max = 70 },
		primaryOre = "Diamond",
		secondaryOre = "Gold",
		tertiaryOre = "Iron",
		enemies = { "Gold Guardian", "Crystal Spider" },
		floorCompletionBonus = 10,
	},
	[5] = {
		name = "Crystal Hollows",
		theme = "crystal_hollows",
		floors = { min = 71, max = 90 },
		primaryOre = "Obsidian",
		secondaryOre = "Diamond",
		tertiaryOre = "Gold",
		enemies = { "Lava Slime", "Obsidian Knight" },
		floorCompletionBonus = 10,
	},
	[6] = {
		name = "Obsidian Core",
		theme = "obsidian_core",
		floors = { min = 91, max = 120 },
		primaryOre = "Mythril",
		secondaryOre = "Obsidian",
		tertiaryOre = "Diamond",
		enemies = { "Fire Elemental", "Magma Wyrm" },
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

function MineLayerConfig.IsCheckpointFloor(floor: number): boolean
	if type(floor) ~= "number" then
		return false
	end

	local sanitizedFloor = math.floor(floor)
	return floor == sanitizedFloor and sanitizedFloor > 0 and sanitizedFloor % MineLayerConfig.checkpointInterval == 0
end

function MineLayerConfig.GetCheckpointFloorsUpTo(latestFloor: number): {number}
	local floors = {}
	if type(latestFloor) ~= "number" then
		return floors
	end

	local sanitizedLatestFloor = math.floor(latestFloor)
	for floor = MineLayerConfig.checkpointInterval, sanitizedLatestFloor, MineLayerConfig.checkpointInterval do
		table.insert(floors, floor)
	end

	return floors
end

return MineLayerConfig
