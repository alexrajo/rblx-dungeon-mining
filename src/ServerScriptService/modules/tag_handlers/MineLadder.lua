local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local MineTransitionService = require(modules.MineTransitionService)

local TagHandler = {}

local debounce = {}
local PROMPT_ATTRIBUTE = "MineLadderPrompt"

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

local function getLadderAction(instance: Instance): string
	local ladderAction = instance:GetAttribute("LadderAction")
	if ladderAction == "exit" then
		return "exit"
	end

	return "descend"
end

function TagHandler.Apply(instance: Instance)
	local promptParent = getPromptParent(instance)
	if promptParent == nil then
		warn("MineLadder: Could not find prompt parent for", instance:GetFullName())
		return
	end

	local existingPrompt = promptParent:FindFirstChild(PROMPT_ATTRIBUTE)
	if existingPrompt then
		existingPrompt:Destroy()
	end

	local ladderAction = getLadderAction(instance)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_ATTRIBUTE
	prompt.ActionText = if ladderAction == "exit" then "Go to surface" else "Descend"
	prompt.ObjectText = "Ladder"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptParent

	prompt.Triggered:Connect(function(player: Player)
		if Players:GetPlayerFromCharacter(player.Character) ~= player then return end

		if debounce[player] then return end
		debounce[player] = true

		if ladderAction == "exit" then
			MineTransitionService.StartExitTransition(player)
		else
			MineTransitionService.StartDescendTransition(player)
		end

		task.delay(2, function()
			debounce[player] = nil
		end)
	end)
end

return TagHandler
