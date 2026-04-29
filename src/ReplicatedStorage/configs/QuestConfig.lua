local QuestConfig = {}

QuestConfig.objectiveTypes = {
	COLLECT_ITEM = "collectItem",
	KILL_ENEMY = "killEnemy",
	REACH_FLOOR = "reachFloor",
}

QuestConfig.quests = {
	mine_stone_01 = {
		id = "mine_stone_01",
		title = "Stone for the Camp",
		description = "Gather stone from the shallow mine so the camp can reinforce paths and workstations.",
		repeatable = false,
		requirements = {},
		objectives = {
			{
				id = "collect_stone",
				type = QuestConfig.objectiveTypes.COLLECT_ITEM,
				targetName = "Stone",
				targetAmount = 10,
				text = "Collect 10 Stone",
			},
		},
		rewards = {
			coins = 25,
			xp = 20,
			items = {
				Copper = 2,
			},
		},
	},
	mine_copper_01 = {
		id = "mine_copper_01",
		title = "A Copper Start",
		description = "Bring back copper from the first layer of the mine. The smith can use it for stronger gear.",
		repeatable = false,
		requirements = {
			completedQuests = { "mine_stone_01" },
		},
		objectives = {
			{
				id = "collect_copper",
				type = QuestConfig.objectiveTypes.COLLECT_ITEM,
				targetName = "Copper",
				targetAmount = 8,
				text = "Collect 8 Copper",
			},
		},
		rewards = {
			coins = 50,
			xp = 35,
			items = {
				["Mini Bomb"] = 2,
			},
		},
	},
	slime_hunter_01 = {
		id = "slime_hunter_01",
		title = "Thin the Slimes",
		description = "Cave Slimes are blocking safe routes through the shallow mine. Clear out a few of them.",
		repeatable = true,
		requirements = {},
		objectives = {
			{
				id = "kill_slimes",
				type = QuestConfig.objectiveTypes.KILL_ENEMY,
				targetName = "Cave Slime",
				targetAmount = 3,
				text = "Defeat 3 Cave Slimes",
			},
		},
		rewards = {
			coins = 40,
			xp = 30,
			items = {
				["Health Potion"] = 1,
			},
		},
	},
	first_descent_01 = {
		id = "first_descent_01",
		title = "Deeper Footing",
		description = "Push deeper into the mine and prove you can safely reach the lower shallow floors.",
		repeatable = false,
		requirements = {},
		objectives = {
			{
				id = "reach_floor_5",
				type = QuestConfig.objectiveTypes.REACH_FLOOR,
				targetAmount = 5,
				text = "Reach Floor 5",
			},
		},
		rewards = {
			coins = 75,
			xp = 50,
			items = {},
		},
	},
}

local questIds = {}
for questId in pairs(QuestConfig.quests) do
	table.insert(questIds, questId)
end
table.sort(questIds)

function QuestConfig.GetQuest(questId: string)
	return QuestConfig.quests[questId]
end

function QuestConfig.GetAllQuestIds(): { string }
	return table.clone(questIds)
end

function QuestConfig.GetObjective(questId: string, objectiveId: string)
	local quest = QuestConfig.GetQuest(questId)
	if quest == nil then
		return nil
	end

	for _, objective in ipairs(quest.objectives or {}) do
		if objective.id == objectiveId then
			return objective
		end
	end

	return nil
end

function QuestConfig.GetProgressKey(questId: string, objectiveId: string): string
	return questId .. ":" .. objectiveId
end

return QuestConfig
