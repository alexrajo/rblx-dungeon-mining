local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local services = ReplicatedStorage.services
local APIService = require(services.APIService)

local configs = ReplicatedStorage.configs
local ConversationConfig = require(configs.ConversationConfig)
local GlobalConfig = require(ReplicatedStorage.GlobalConfig)

local modules = ServerScriptService.modules
local QuestService = require(modules.QuestService)
local PlayerDataHandler = require(modules.PlayerDataHandler)

local ConversationService = {}

local activeSessions: {[Player]: table} = {}
local DEFAULT_QUEST_COMPLETED_MESSAGE = "You have already completed this quest"
local DEFAULT_QUEST_ACTIVE_MESSAGE = "You are already working on this quest"

local function getPromptParent(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Model") then
		local model = instance :: Model
		if model.PrimaryPart ~= nil then
			return model.PrimaryPart
		end

		local firstPart = model:FindFirstChildWhichIsA("BasePart", true)
		if firstPart ~= nil then
			model.PrimaryPart = firstPart
			return firstPart
		end
	end

	return nil
end

local function getCharacterRoot(player: Player): BasePart?
	local character = player.Character
	if character == nil then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root ~= nil and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function getConversationId(instance: Instance): string?
	local conversationId = instance:GetAttribute("conversationId")
	if type(conversationId) ~= "string" or conversationId == "" then
		return nil
	end

	return conversationId
end

local function getStepIndexById(conversation, stepId: string): number?
	for index, step in ipairs(conversation.steps or {}) do
		if step.id == stepId then
			return index
		end
	end

	return nil
end

local function getStepById(conversation, stepId: string)
	local stepIndex = getStepIndexById(conversation, stepId)
	if stepIndex == nil then
		return nil, nil
	end

	return conversation.steps[stepIndex], stepIndex
end

local function getFirstStep(conversation)
	local steps = conversation.steps
	if type(steps) ~= "table" or steps[1] == nil then
		return nil, nil
	end

	return steps[1], 1
end

local function getNextStepId(conversation, step, stepIndex: number?): string?
	if type(step.nextStepId) == "string" and step.nextStepId ~= "" then
		return step.nextStepId
	end

	if stepIndex ~= nil and conversation.steps[stepIndex + 1] ~= nil then
		return conversation.steps[stepIndex + 1].id
	end

	return nil
end

local function sanitizeResponses(responses)
	if type(responses) ~= "table" then
		return {}
	end

	local sanitizedResponses = {}
	for _, response in ipairs(responses) do
		if type(response.id) == "string" and response.id ~= "" and type(response.text) == "string" then
			table.insert(sanitizedResponses, {
				id = response.id,
				text = response.text,
			})
		end
	end

	return sanitizedResponses
end

local function getNamedCount(entries, entryName: string): number
	for _, entry in ipairs(entries or {}) do
		if entry.name == entryName and type(entry.value) == "number" then
			return entry.value
		end
	end

	return 0
end

local preConversationCheckHandlers = {}

function preConversationCheckHandlers.questCompleted(player: Player, check)
	if type(check.questId) ~= "string" or check.questId == "" then
		return nil
	end

	local completions = PlayerDataHandler.GetQuestCompletions(player)
	if getNamedCount(completions, check.questId) <= 0 then
		return nil
	end

	return {
		message = if type(check.message) == "string" and check.message ~= "" then check.message else DEFAULT_QUEST_COMPLETED_MESSAGE,
	}
end

function preConversationCheckHandlers.questActive(player: Player, check)
	if type(check.questId) ~= "string" or check.questId == "" then
		return nil
	end

	local activeQuests = PlayerDataHandler.GetActiveQuests(player)
	for _, activeQuest in ipairs(activeQuests or {}) do
		if activeQuest.id == check.questId and activeQuest.status == "active" then
			return {
				message = if type(check.message) == "string" and check.message ~= "" then check.message else DEFAULT_QUEST_ACTIVE_MESSAGE,
			}
		end
	end

	return nil
end

local function evaluatePreConversationChecks(player: Player, conversation)
	if type(conversation.preConversationChecks) ~= "table" then
		return nil
	end

	-- Config order is priority order; the first matching check wins.
	for _, check in ipairs(conversation.preConversationChecks) do
		if type(check) ~= "table" or type(check.conditionType) ~= "string" then
			continue
		end

		local handler = preConversationCheckHandlers[check.conditionType]
		if handler == nil then
			warn("ConversationService: Unsupported preConversationCheck conditionType:", check.conditionType)
			continue
		end

		local result = handler(player, check)
		if result ~= nil then
			return result
		end
	end

	return nil
end

local function fireStep(player: Player, session, text: string, responses)
	local showConversationStepEvent = APIService.GetEvent("ShowConversationStep")
	showConversationStepEvent:FireClient(player, {
		entityName = session.entityName,
		text = text,
		responses = sanitizeResponses(responses),
	})
end

local function isSessionInRange(player: Player, session): boolean
	local root = getCharacterRoot(player)
	local promptParent = getPromptParent(session.instance)
	if root == nil or promptParent == nil then
		return false
	end

	local distance = (root.Position - promptParent.Position).Magnitude
	return distance <= GlobalConfig.CONVERSABLE_ENTITY_MAX_DISTANCE
end

local function endSession(player: Player)
	if activeSessions[player] == nil then
		return
	end

	activeSessions[player] = nil
	APIService.GetEvent("EndConversation"):FireClient(player)
end

local function executeActions(player: Player, actions)
	if type(actions) ~= "table" then
		return
	end

	for _, action in ipairs(actions) do
		if type(action) ~= "table" then
			continue
		end

		if action.actionType == "startQuest" then
			QuestService.StartQuest(player, action.questId)
		else
			warn("ConversationService: Unsupported conversation actionType:", action.actionType)
		end
	end
end

local function sendCurrentStep(player: Player, session)
	if session.preConversationMessage ~= nil then
		session.mode = "preConversationCheck"
		session.pendingNextStepId = nil
		session.pendingEndsConversation = true
		session.canAdvance = true
		fireStep(player, session, session.preConversationMessage, {})
		return
	end

	local step, stepIndex = getStepById(session.conversation, session.currentStepId)
	if step == nil then
		endSession(player)
		return
	end

	local responses = sanitizeResponses(step.responses)
	session.currentStepIndex = stepIndex
	session.mode = "step"
	session.pendingNextStepId = getNextStepId(session.conversation, step, stepIndex)
	session.pendingEndsConversation = false
	session.canAdvance = #responses == 0

	fireStep(player, session, step.text or "", responses)
end

local function monitorDistance(player: Player, token: number)
	while activeSessions[player] ~= nil and activeSessions[player].token == token do
		if not isSessionInRange(player, activeSessions[player]) then
			endSession(player)
			return
		end

		task.wait(0.25)
	end
end

function ConversationService.GetConversation(conversationId: string)
	return ConversationConfig.GetConversation(conversationId)
end

function ConversationService.GetPromptParent(instance: Instance): BasePart?
	return getPromptParent(instance)
end

function ConversationService.StartConversation(player: Player, instance: Instance)
	local conversationId = getConversationId(instance)
	if conversationId == nil then
		warn("ConversationService: Missing conversationId attribute for", instance:GetFullName())
		return
	end

	local conversation = ConversationConfig.GetConversation(conversationId)
	if conversation == nil then
		warn("ConversationService: Unknown conversationId", conversationId, "for", instance:GetFullName())
		return
	end

	local promptParent = getPromptParent(instance)
	local root = getCharacterRoot(player)
	if promptParent == nil or root == nil then
		return
	end

	if (root.Position - promptParent.Position).Magnitude > GlobalConfig.CONVERSABLE_ENTITY_MAX_DISTANCE then
		return
	end

	endSession(player)

	local preConversationCheckResult = evaluatePreConversationChecks(player, conversation)
	local firstStep = nil
	if preConversationCheckResult == nil then
		firstStep = getFirstStep(conversation)
		if firstStep == nil then
			warn("ConversationService: Conversation has no steps:", conversationId)
			return
		end
	end

	local token = os.clock()
	local session = {
		token = token,
		instance = instance,
		entityName = instance.Name,
		conversationId = conversationId,
		conversation = conversation,
		currentStepId = firstStep and firstStep.id or nil,
		preConversationMessage = preConversationCheckResult and preConversationCheckResult.message or nil,
	}
	activeSessions[player] = session

	sendCurrentStep(player, session)
	task.spawn(monitorDistance, player, token)
end

function ConversationService.AdvanceConversation(player: Player)
	local session = activeSessions[player]
	if session == nil then
		return
	end

	if not isSessionInRange(player, session) then
		endSession(player)
		return
	end

	if session.pendingEndsConversation == true then
		endSession(player)
		return
	end

	if session.canAdvance ~= true then
		return
	end

	local nextStepId = session.pendingNextStepId
	if type(nextStepId) ~= "string" or nextStepId == "" then
		endSession(player)
		return
	end

	session.currentStepId = nextStepId
	sendCurrentStep(player, session)
end

function ConversationService.SelectResponse(player: Player, responseId: string)
	local session = activeSessions[player]
	if session == nil or type(responseId) ~= "string" then
		return
	end

	if not isSessionInRange(player, session) then
		endSession(player)
		return
	end

	local step = getStepById(session.conversation, session.currentStepId)
	if step == nil or type(step.responses) ~= "table" then
		endSession(player)
		return
	end

	for _, response in ipairs(step.responses) do
		if response.id ~= responseId then
			continue
		end

		executeActions(player, response.actions)

		if type(response.response) ~= "string" or response.response == "" then
			if response.endsConversation == true then
				endSession(player)
				return
			end

			local nextStepId = response.nextStepId or session.pendingNextStepId
			if type(nextStepId) ~= "string" or nextStepId == "" then
				endSession(player)
				return
			end

			session.currentStepId = nextStepId
			sendCurrentStep(player, session)
			return
		end

		session.mode = "response"
		session.pendingNextStepId = response.nextStepId or session.pendingNextStepId
		session.pendingEndsConversation = response.endsConversation == true
		session.canAdvance = true
		fireStep(player, session, response.response, {})
		return
	end
end

function ConversationService.LeaveConversation(player: Player)
	endSession(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	activeSessions[player] = nil
end)

return ConversationService
