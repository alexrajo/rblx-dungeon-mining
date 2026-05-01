return {
	promptActionText = "Talk",
	preConversationChecks = {
		{
			conditionType = "questCompleted",
			questId = "mine_stone_01",
			message = "You have already completed this quest",
		},
		{
			conditionType = "questActive",
			questId = "mine_stone_01",
			message = "You are already working on this quest",
		},
	},
	steps = {
		{
			id = "greeting",
			text = "The mine has been restless lately.",
			nextStepId = "offer",
		},
		{
			id = "offer",
			text = "Can you bring back stone for the camp?",
			responses = {
				{
					id = "accept",
					text = "I accept the quest.",
					response = "Good. Start with stone from the shallow mine.",
					actions = {
						{ actionType = "startQuest", questId = "mine_stone_01" },
					},
					endsConversation = true,
				},
				{
					id = "decline",
					text = "Not right now.",
					response = "Come back when you are ready.",
					endsConversation = true,
				},
			},
		},
	},
}
