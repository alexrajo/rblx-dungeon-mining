local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local QuestConfig = require(configs.QuestConfig)

local services = ReplicatedStorage.services
local APIService = require(services.APIService)

local QuestService = {}

local STATUS_ACTIVE = "active"
local STATUS_COMPLETED = "completed"

local playerConnections: { [Player]: { RBXScriptConnection } } = {}

local function getOrCreateSignalQuestBindable(): BindableEvent
	local folder = ServerStorage:FindFirstChild("CrossScriptCommunicationBindables")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "CrossScriptCommunicationBindables"
		folder.Parent = ServerStorage
	end

	local bindable = folder:FindFirstChild("SignalQuest")
	if bindable == nil or not bindable:IsA("BindableEvent") then
		if bindable ~= nil then
			bindable:Destroy()
		end
		bindable = Instance.new("BindableEvent")
		bindable.Name = "SignalQuest"
		bindable.Parent = folder
	end

	return bindable
end

local function cloneArray(value)
	if type(value) ~= "table" then
		return {}
	end
	return table.clone(value)
end

local function findActiveQuest(activeQuests, questId: string): (number?, table?)
	for index, entry in ipairs(activeQuests) do
		if entry.id == questId then
			return index, entry
		end
	end
	return nil, nil
end

local function getNamedCount(entries, questId: string): number
	for _, entry in ipairs(entries or {}) do
		if entry.name == questId and type(entry.value) == "number" then
			return entry.value
		end
	end
	return 0
end

local function incrementNamedCount(entries, questId: string)
	for index, entry in ipairs(entries) do
		if entry.name == questId then
			entries[index] = {
				name = questId,
				value = (type(entry.value) == "number" and entry.value or 0) + 1,
			}
			return
		end
	end

	table.insert(entries, {
		name = questId,
		value = 1,
	})
end

local function getProgressEntry(progressEntries, questId: string, objectiveId: string): (number?, table?)
	local progressKey = QuestConfig.GetProgressKey(questId, objectiveId)
	for index, entry in ipairs(progressEntries) do
		if entry.id == progressKey then
			return index, entry
		end
	end
	return nil, nil
end

local function getSnapshotProgress(player: Player, objective): number?
	if objective.type == QuestConfig.objectiveTypes.COLLECT_ITEM then
		return PlayerDataHandler.GetItemCount(player, objective.targetName)
	elseif objective.type == QuestConfig.objectiveTypes.REACH_FLOOR then
		return PlayerDataHandler.GetMaxFloorReached(player)
	end

	return nil
end

local function getCollectCountMode(objective): string
	return objective.countMode or QuestConfig.collectCountModes.GAINED_SINCE_START
end

local function buildProgressEntry(questId: string, objective)
	local goal = math.max(1, math.floor(objective.targetAmount or 1))
	return {
		id = QuestConfig.GetProgressKey(questId, objective.id),
		questId = questId,
		objectiveId = objective.id,
		value = 0,
		goal = goal,
		completed = false,
		baseline = 0,
		lastObserved = 0,
	}
end

local function clearTrackedQuest(activeQuests)
	for index, entry in ipairs(activeQuests) do
		if entry.tracked == true then
			local updatedEntry = table.clone(entry)
			updatedEntry.tracked = false
			activeQuests[index] = updatedEntry
		end
	end
end

local function sendNotification(player: Player, title: string, description: string?)
	local notificationEvent = APIService.GetEvent("SendNotification")
	if notificationEvent ~= nil then
		notificationEvent:FireClient(player, {
			Type = "quest",
			Title = title,
			Description = description,
		})
	end
end

local function setObjectiveProgress(player: Player, questId: string, objective, nextValue: number): boolean
	local activeQuests = cloneArray(PlayerDataHandler.GetActiveQuests(player))
	local activeIndex, activeQuest = findActiveQuest(activeQuests, questId)
	if activeQuest == nil or activeQuest.status == STATUS_COMPLETED then
		return false
	end

	local progressEntries = cloneArray(PlayerDataHandler.GetQuestObjectiveProgress(player))
	local progressIndex, progressEntry = getProgressEntry(progressEntries, questId, objective.id)
	if progressEntry == nil then
		progressEntry = buildProgressEntry(questId, objective)
		table.insert(progressEntries, progressEntry)
		progressIndex = #progressEntries
	end

	local goal = math.max(1, math.floor(objective.targetAmount or progressEntry.goal or 1))
	nextValue = math.clamp(math.floor(nextValue), 0, goal)
	if progressEntry.value == nextValue and progressEntry.goal == goal and progressEntry.completed == (nextValue >= goal) then
		return false
	end

	local updatedProgress = table.clone(progressEntry)
	updatedProgress.value = nextValue
	updatedProgress.goal = goal
	updatedProgress.completed = nextValue >= goal
	progressEntries[progressIndex] = updatedProgress
	PlayerDataHandler.SetQuestObjectiveProgress(player, progressEntries)

	local quest = QuestConfig.GetQuest(questId)
	if quest == nil then
		return true
	end

	local allCompleted = true
	for _, questObjective in ipairs(quest.objectives or {}) do
		local _, objectiveProgress = getProgressEntry(progressEntries, questId, questObjective.id)
		if objectiveProgress == nil or objectiveProgress.completed ~= true then
			allCompleted = false
			break
		end
	end

	if allCompleted and activeIndex ~= nil then
		local updatedQuest = table.clone(activeQuest)
		updatedQuest.status = STATUS_COMPLETED
		updatedQuest.tracked = false
		updatedQuest.completedAt = os.time()
		activeQuests[activeIndex] = updatedQuest
		PlayerDataHandler.SetActiveQuests(player, activeQuests)

		local completions = cloneArray(PlayerDataHandler.GetQuestCompletions(player))
		incrementNamedCount(completions, questId)
		PlayerDataHandler.SetQuestCompletions(player, completions)

		sendNotification(player, "Quest Complete!", quest.title)
	end

	return true
end

local function refreshSnapshotObjectives(player: Player)
	local activeQuests = PlayerDataHandler.GetActiveQuests(player)
	for _, activeQuest in ipairs(activeQuests or {}) do
		if activeQuest.status ~= STATUS_ACTIVE then
			continue
		end

		local quest = QuestConfig.GetQuest(activeQuest.id)
		if quest == nil then
			continue
		end

		for _, objective in ipairs(quest.objectives or {}) do
			if objective.type == QuestConfig.objectiveTypes.COLLECT_ITEM then
				local currentCount = PlayerDataHandler.GetItemCount(player, objective.targetName)
				local progressEntries = cloneArray(PlayerDataHandler.GetQuestObjectiveProgress(player))
				local progressIndex, progressEntry = getProgressEntry(progressEntries, activeQuest.id, objective.id)
				if progressEntry == nil then
					progressEntry = buildProgressEntry(activeQuest.id, objective)
					progressEntry.baseline = currentCount
					progressEntry.lastObserved = currentCount
					table.insert(progressEntries, progressEntry)
					progressIndex = #progressEntries
					PlayerDataHandler.SetQuestObjectiveProgress(player, progressEntries)
				end

				local mode = getCollectCountMode(objective)
				if mode == QuestConfig.collectCountModes.CURRENT_TOTAL then
					setObjectiveProgress(player, activeQuest.id, objective, currentCount)
				else
					local baseline = type(progressEntry.baseline) == "number" and progressEntry.baseline or currentCount
					local lastObserved = type(progressEntry.lastObserved) == "number" and progressEntry.lastObserved or currentCount
					local gainedAmount = math.max(0, currentCount - lastObserved)
					local nextValue = (type(progressEntry.value) == "number" and progressEntry.value or 0) + gainedAmount

					progressEntries = cloneArray(PlayerDataHandler.GetQuestObjectiveProgress(player))
					progressIndex, progressEntry = getProgressEntry(progressEntries, activeQuest.id, objective.id)
					if progressEntry ~= nil and progressIndex ~= nil then
						local updatedProgress = table.clone(progressEntry)
						updatedProgress.baseline = baseline
						updatedProgress.lastObserved = currentCount
						progressEntries[progressIndex] = updatedProgress
						PlayerDataHandler.SetQuestObjectiveProgress(player, progressEntries)
					end

					setObjectiveProgress(player, activeQuest.id, objective, nextValue)
				end
			else
				local snapshotValue = getSnapshotProgress(player, objective)
				if snapshotValue ~= nil then
					setObjectiveProgress(player, activeQuest.id, objective, snapshotValue)
				end
			end
		end
	end
end

local function questRequirementsMet(player: Player, quest): boolean
	local requirements = quest.requirements or {}
	local completedQuests = requirements.completedQuests or {}
	local completions = PlayerDataHandler.GetQuestCompletions(player)

	for _, requiredQuestId in ipairs(completedQuests) do
		if getNamedCount(completions, requiredQuestId) <= 0 then
			return false
		end
	end

	return true
end

function QuestService.StartQuest(player: Player, questId: string)
	if type(questId) ~= "string" then
		return { success = false, reason = "invalid_quest_id" }
	end

	local quest = QuestConfig.GetQuest(questId)
	if quest == nil then
		return { success = false, reason = "quest_not_found" }
	end

	local activeQuests = cloneArray(PlayerDataHandler.GetActiveQuests(player))
	if findActiveQuest(activeQuests, questId) ~= nil then
		return { success = false, reason = "already_active" }
	end

	local claims = PlayerDataHandler.GetQuestClaims(player)
	if quest.repeatable ~= true and getNamedCount(claims, questId) > 0 then
		return { success = false, reason = "already_claimed" }
	end

	if not questRequirementsMet(player, quest) then
		return { success = false, reason = "requirements_not_met" }
	end

	clearTrackedQuest(activeQuests)
	table.insert(activeQuests, {
		id = questId,
		status = STATUS_ACTIVE,
		tracked = true,
		startedAt = os.time(),
		completedAt = 0,
	})
	PlayerDataHandler.SetActiveQuests(player, activeQuests)

	local progressEntries = cloneArray(PlayerDataHandler.GetQuestObjectiveProgress(player))
	for index = #progressEntries, 1, -1 do
		if progressEntries[index].questId == questId then
			table.remove(progressEntries, index)
		end
	end

	for _, objective in ipairs(quest.objectives or {}) do
		local progressEntry = buildProgressEntry(questId, objective)
		if objective.type == QuestConfig.objectiveTypes.COLLECT_ITEM then
			local currentCount = PlayerDataHandler.GetItemCount(player, objective.targetName)
			progressEntry.baseline = currentCount
			progressEntry.lastObserved = currentCount
		end
		table.insert(progressEntries, progressEntry)
	end
	PlayerDataHandler.SetQuestObjectiveProgress(player, progressEntries)

	refreshSnapshotObjectives(player)

	return { success = true }
end

function QuestService.TrackQuest(player: Player, questId: string)
	if type(questId) ~= "string" then
		return { success = false, reason = "invalid_quest_id" }
	end

	local activeQuests = cloneArray(PlayerDataHandler.GetActiveQuests(player))
	local activeIndex, activeQuest = findActiveQuest(activeQuests, questId)
	if activeQuest == nil then
		return { success = false, reason = "not_active" }
	end
	if activeQuest.status == STATUS_COMPLETED then
		return { success = false, reason = "completed" }
	end

	clearTrackedQuest(activeQuests)
	local updatedQuest = table.clone(activeQuest)
	updatedQuest.tracked = true
	activeQuests[activeIndex] = updatedQuest
	PlayerDataHandler.SetActiveQuests(player, activeQuests)

	return { success = true }
end

function QuestService.UntrackQuest(player: Player, questId: string?)
	local activeQuests = cloneArray(PlayerDataHandler.GetActiveQuests(player))
	local changed = false

	for index, activeQuest in ipairs(activeQuests) do
		if activeQuest.tracked == true and (questId == nil or questId == "" or activeQuest.id == questId) then
			local updatedQuest = table.clone(activeQuest)
			updatedQuest.tracked = false
			activeQuests[index] = updatedQuest
			changed = true
		end
	end

	if changed then
		PlayerDataHandler.SetActiveQuests(player, activeQuests)
	end

	return { success = true }
end

function QuestService.AbandonQuest(player: Player, questId: string)
	if type(questId) ~= "string" then
		return { success = false, reason = "invalid_quest_id" }
	end

	local activeQuests = cloneArray(PlayerDataHandler.GetActiveQuests(player))
	local activeIndex, activeQuest = findActiveQuest(activeQuests, questId)
	if activeQuest == nil then
		return { success = false, reason = "not_active" }
	end
	if activeQuest.status == STATUS_COMPLETED then
		return { success = false, reason = "completed" }
	end

	table.remove(activeQuests, activeIndex)
	PlayerDataHandler.SetActiveQuests(player, activeQuests)

	local progressEntries = cloneArray(PlayerDataHandler.GetQuestObjectiveProgress(player))
	for index = #progressEntries, 1, -1 do
		if progressEntries[index].questId == questId then
			table.remove(progressEntries, index)
		end
	end
	PlayerDataHandler.SetQuestObjectiveProgress(player, progressEntries)

	return { success = true }
end

function QuestService.ClaimQuestReward(player: Player, questId: string)
	if type(questId) ~= "string" then
		return { success = false, reason = "invalid_quest_id" }
	end

	local quest = QuestConfig.GetQuest(questId)
	if quest == nil then
		return { success = false, reason = "quest_not_found" }
	end

	local activeQuests = cloneArray(PlayerDataHandler.GetActiveQuests(player))
	local activeIndex, activeQuest = findActiveQuest(activeQuests, questId)
	if activeQuest == nil then
		return { success = false, reason = "not_active" }
	end
	if activeQuest.status ~= STATUS_COMPLETED then
		return { success = false, reason = "not_completed" }
	end

	table.remove(activeQuests, activeIndex)
	PlayerDataHandler.SetActiveQuests(player, activeQuests)

	local rewards = quest.rewards or {}
	if type(rewards.coins) == "number" and rewards.coins > 0 then
		PlayerDataHandler.GiveCoins(player, rewards.coins)
	end
	if type(rewards.xp) == "number" and rewards.xp > 0 then
		PlayerDataHandler.GiveXP(player, rewards.xp)
	end
	if type(rewards.items) == "table" and next(rewards.items) ~= nil then
		PlayerDataHandler.GiveItems(player, rewards.items)
	end

	local claims = cloneArray(PlayerDataHandler.GetQuestClaims(player))
	incrementNamedCount(claims, questId)
	PlayerDataHandler.SetQuestClaims(player, claims)

	return { success = true }
end

function QuestService.Signal(player: Player, signalName: string, payload)
	if player == nil or player.Parent == nil or type(signalName) ~= "string" then
		return
	end

	local activeQuests = PlayerDataHandler.GetActiveQuests(player)
	for _, activeQuest in ipairs(activeQuests or {}) do
		if activeQuest.status ~= STATUS_ACTIVE then
			continue
		end

		local quest = QuestConfig.GetQuest(activeQuest.id)
		if quest == nil then
			continue
		end

		for _, objective in ipairs(quest.objectives or {}) do
			if objective.type == QuestConfig.objectiveTypes.KILL_ENEMY and signalName == "killEnemy" then
				local enemyType = payload and payload.enemyType
				if enemyType == objective.targetName then
					local progressEntries = PlayerDataHandler.GetQuestObjectiveProgress(player)
					local _, progressEntry = getProgressEntry(progressEntries, activeQuest.id, objective.id)
					local currentValue = progressEntry and progressEntry.value or 0
					setObjectiveProgress(player, activeQuest.id, objective, currentValue + 1)
				end
			elseif objective.type == QuestConfig.objectiveTypes.REACH_FLOOR and signalName == "reachFloor" then
				local floor = payload and payload.floor
				if type(floor) == "number" then
					setObjectiveProgress(player, activeQuest.id, objective, floor)
				end
			end
		end
	end

	refreshSnapshotObjectives(player)
end

local function disconnectPlayer(player: Player)
	local connections = playerConnections[player]
	if connections ~= nil then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end
	playerConnections[player] = nil
end

local function initializePlayer(player: Player)
	disconnectPlayer(player)
	playerConnections[player] = {}

	local inventoryConnection = PlayerDataHandler.ListenToStatUpdate("Inventory", player, function()
		refreshSnapshotObjectives(player)
	end)
	if inventoryConnection ~= nil then
		table.insert(playerConnections[player], inventoryConnection)
	end

	local maxFloorConnection = PlayerDataHandler.ListenToStatUpdate("MaxFloorReached", player, function()
		refreshSnapshotObjectives(player)
	end)
	if maxFloorConnection ~= nil then
		table.insert(playerConnections[player], maxFloorConnection)
	end

	refreshSnapshotObjectives(player)
end

function QuestService.Init()
	local signalQuestBindable = getOrCreateSignalQuestBindable()
	signalQuestBindable.Event:Connect(function(player: Player, signalName: string, payload)
		QuestService.Signal(player, signalName, payload)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		task.defer(function()
			initializePlayer(player)
		end)
	end)

	Players.PlayerRemoving:Connect(disconnectPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		task.defer(function()
			initializePlayer(player)
		end)
	end
end

return QuestService
