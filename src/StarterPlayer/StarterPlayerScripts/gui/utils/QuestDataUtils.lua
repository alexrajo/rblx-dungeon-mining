local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestConfig = require(ReplicatedStorage.configs.QuestConfig)

local QuestDataUtils = {}

function QuestDataUtils.GetCount(entries, questId: string): number
	for _, entry in ipairs(entries or {}) do
		if entry.name == questId and type(entry.value) == "number" then
			return entry.value
		end
	end
	return 0
end

function QuestDataUtils.GetProgressEntry(statsData, questId: string, objectiveId: string)
	local progressKey = QuestConfig.GetProgressKey(questId, objectiveId)
	for _, entry in ipairs(statsData.QuestObjectiveProgress or {}) do
		if entry.id == progressKey then
			return entry
		end
	end
	return nil
end

function QuestDataUtils.GetActiveQuestEntry(statsData, questId: string)
	for _, entry in ipairs(statsData.ActiveQuests or {}) do
		if entry.id == questId then
			return entry
		end
	end
	return nil
end

function QuestDataUtils.IsCompletedUnclaimed(entry): boolean
	return entry ~= nil and entry.status == "completed"
end

function QuestDataUtils.GetActiveRows(statsData)
	local rows = {}
	for _, entry in ipairs(statsData.ActiveQuests or {}) do
		local quest = QuestConfig.GetQuest(entry.id)
		if quest ~= nil then
			table.insert(rows, {
				quest = quest,
				entry = entry,
			})
		end
	end

	table.sort(rows, function(a, b)
		local aTracked = a.entry.tracked == true
		local bTracked = b.entry.tracked == true
		if aTracked ~= bTracked then
			return aTracked
		end

		local aComplete = QuestDataUtils.IsCompletedUnclaimed(a.entry)
		local bComplete = QuestDataUtils.IsCompletedUnclaimed(b.entry)
		if aComplete ~= bComplete then
			return aComplete
		end

		return a.quest.title < b.quest.title
	end)

	return rows
end

function QuestDataUtils.GetClaimedRows(statsData)
	local rows = {}
	for _, questId in ipairs(QuestConfig.GetAllQuestIds()) do
		local claimCount = QuestDataUtils.GetCount(statsData.QuestClaims, questId)
		if claimCount > 0 then
			local quest = QuestConfig.GetQuest(questId)
			if quest ~= nil then
				table.insert(rows, {
					quest = quest,
					claimCount = claimCount,
				})
			end
		end
	end
	return rows
end

function QuestDataUtils.GetTrackedQuest(statsData)
	for _, entry in ipairs(statsData.ActiveQuests or {}) do
		if entry.tracked == true and entry.status ~= "completed" then
			local quest = QuestConfig.GetQuest(entry.id)
			if quest ~= nil then
				return quest, entry
			end
		end
	end
	return nil, nil
end

function QuestDataUtils.GetObjectiveText(statsData, quest, objective)
	local progress = QuestDataUtils.GetProgressEntry(statsData, quest.id, objective.id)
	local value = progress and progress.value or 0
	local goal = progress and progress.goal or objective.targetAmount or 1
	local text = objective.text or "Objective"
	return string.format("%s (%d/%d)", text, math.floor(value), math.floor(goal))
end

function QuestDataUtils.GetRewardLines(quest)
	local rewards = quest.rewards or {}
	local lines = {}

	if type(rewards.coins) == "number" and rewards.coins > 0 then
		table.insert(lines, tostring(rewards.coins) .. " Coins")
	end
	if type(rewards.xp) == "number" and rewards.xp > 0 then
		table.insert(lines, tostring(rewards.xp) .. " XP")
	end
	if type(rewards.items) == "table" then
		local itemNames = {}
		for itemName in pairs(rewards.items) do
			table.insert(itemNames, itemName)
		end
		table.sort(itemNames)
		for _, itemName in ipairs(itemNames) do
			table.insert(lines, tostring(rewards.items[itemName]) .. "x " .. itemName)
		end
	end

	return lines
end

return QuestDataUtils
