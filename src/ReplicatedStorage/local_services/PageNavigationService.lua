local PageNavigationService = {}

local openQuestLogEvent = Instance.new("BindableEvent")

function PageNavigationService.OpenQuestLog(questId: string?)
	openQuestLogEvent:Fire(questId)
end

function PageNavigationService.OnOpenQuestLog(callback: (questId: string?) -> ())
	return openQuestLogEvent.Event:Connect(callback)
end

return PageNavigationService
