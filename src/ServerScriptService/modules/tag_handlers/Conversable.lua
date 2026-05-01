local ServerScriptService = game:GetService("ServerScriptService")

local ConversationService = require(ServerScriptService.modules.ConversationService)

local TagHandler = {}

local PROMPT_NAME = "ConversationPrompt"
local DEFAULT_ACTION_TEXT = "Talk"
local READ_ACTION_TEXT = "Read"
local debounce = {}

local function getConversationId(instance: Instance): string?
	local conversationId = instance:GetAttribute("conversationId")
	if type(conversationId) ~= "string" or conversationId == "" then
		return nil
	end

	return conversationId
end

local function getPromptActionText(conversation): string
	if type(conversation.promptActionText) == "string" and conversation.promptActionText ~= "" then
		return conversation.promptActionText
	end

	if conversation.conversationKind == "readable" then
		return READ_ACTION_TEXT
	end

	return DEFAULT_ACTION_TEXT
end

function TagHandler.Apply(instance: Instance)
	local promptParent = ConversationService.GetPromptParent(instance)
	if promptParent == nil then
		warn("Conversable: Could not find prompt parent for", instance:GetFullName())
		return
	end

	local conversationId = getConversationId(instance)
	if conversationId == nil then
		warn("Conversable: Missing conversationId attribute for", instance:GetFullName())
		return
	end

	local conversation = ConversationService.GetConversation(conversationId)
	if conversation == nil then
		warn("Conversable: Unknown conversationId", conversationId, "for", instance:GetFullName())
		return
	end

	local existingPrompt = promptParent:FindFirstChild(PROMPT_NAME)
	if existingPrompt ~= nil then
		existingPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = getPromptActionText(conversation)
	prompt.ObjectText = instance.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptParent

	prompt.Triggered:Connect(function(player: Player)
		if debounce[player] then
			return
		end

		debounce[player] = true
		ConversationService.StartConversation(player, instance)

		task.delay(0.5, function()
			debounce[player] = nil
		end)
	end)
end

return TagHandler
