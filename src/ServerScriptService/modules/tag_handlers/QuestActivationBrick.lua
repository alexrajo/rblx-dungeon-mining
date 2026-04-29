local ServerScriptService = game:GetService("ServerScriptService")

local QuestService = require(ServerScriptService.modules.QuestService)

local TagHandler = {}

local PROMPT_NAME = "QuestActivationPrompt"
local debounce = {}

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

function TagHandler.Apply(instance: Instance)
	local promptParent = getPromptParent(instance)
	if promptParent == nil then
		warn("QuestActivationBrick: Could not find prompt parent for", instance:GetFullName())
		return
	end

	local existingPrompt = promptParent:FindFirstChild(PROMPT_NAME)
	if existingPrompt ~= nil then
		existingPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = "Start Quest"
	prompt.ObjectText = "Quest"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptParent

	prompt.Triggered:Connect(function(player: Player)
		if debounce[player] then
			return
		end

		local questId = instance:GetAttribute("questId")
		if type(questId) ~= "string" or questId == "" then
			warn("QuestActivationBrick: Missing questId attribute for", instance:GetFullName())
			return
		end

		debounce[player] = true
		QuestService.StartQuest(player, questId)

		task.delay(0.5, function()
			debounce[player] = nil
		end)
	end)
end

return TagHandler
