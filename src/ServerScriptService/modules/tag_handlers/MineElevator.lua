local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local TagHandler = {}

local debounce = {}
local PROMPT_ATTRIBUTE = "MineElevatorPrompt"

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
		warn("MineElevator: Could not find prompt parent for", instance:GetFullName())
		return
	end

	local existingPrompt = promptParent:FindFirstChild(PROMPT_ATTRIBUTE)
	if existingPrompt ~= nil then
		existingPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_ATTRIBUTE
	prompt.ActionText = "Choose floor"
	prompt.ObjectText = "Mine Elevator"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptParent

	prompt.Triggered:Connect(function(player: Player)
		if Players:GetPlayerFromCharacter(player.Character) ~= player then return end
		if debounce[player] then return end

		debounce[player] = true
		APIService.GetEvent("OpenMineElevator"):FireClient(player)

		task.delay(0.5, function()
			debounce[player] = nil
		end)
	end)
end

return TagHandler
