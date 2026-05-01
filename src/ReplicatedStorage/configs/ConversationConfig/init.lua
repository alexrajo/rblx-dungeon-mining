local ConversationConfig = {
	conversations = {},
}

for _, moduleScript in pairs(script:GetChildren()) do
	if not moduleScript:IsA("ModuleScript") then
		continue
	end

	if ConversationConfig.conversations[moduleScript.Name] ~= nil then
		warn("ConversationConfig: Conversation is defined multiple times:", moduleScript.Name)
		continue
	end

	ConversationConfig.conversations[moduleScript.Name] = require(moduleScript)
end

function ConversationConfig.GetConversation(conversationId: string)
	return ConversationConfig.conversations[conversationId]
end

return ConversationConfig
