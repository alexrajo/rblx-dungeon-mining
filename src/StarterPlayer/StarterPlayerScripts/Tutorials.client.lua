local plr = game.Players.LocalPlayer
local character = plr.Character

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tutorialsRefFolder = ReplicatedStorage.tutorials

local services = ReplicatedStorage.services
local MaidClass = require(services.Maid)
local APIService = require(services.APIService)

local UserInputService = game:GetService("UserInputService")

local startTutorialEvent = APIService.GetEvent("StartTutorial")
local signalTutorialEvent = APIService.GetEvent("SignalTutorial")

local nextTutorialStepEvent = APIService.GetEvent("SendNextTutorialStep")

local maid = MaidClass.new()

local Tutorials = {
	INTRO = "Intro",
}

local positionIndicator: Part? = nil
local activeIndicatorToken = 0

local INDICATOR_REFRESH_INTERVAL = 0.25

function getHasCompletedTutorial(tutorialName: string): boolean | nil
	local allPlayerData = ReplicatedStorage:WaitForChild("PlayerData")
	local playerData = allPlayerData:WaitForChild(plr.Name)
	local tutorialStates = playerData:WaitForChild("TutorialStates")
	local hasCompletedTutorialValue: BoolValue? = tutorialStates:WaitForChild(tutorialName)
	if hasCompletedTutorialValue == nil then
		return nil
	end

	local hasCompletedTutorial = hasCompletedTutorialValue.Value

	return hasCompletedTutorial
end

local function getPlayerPosition(): Vector3?
	if character == nil then
		return nil
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart == nil or not humanoidRootPart:IsA("BasePart") then
		return nil
	end

	return humanoidRootPart.Position
end

local function getInstancePosition(instance: Instance): Vector3?
	if instance:IsA("Model") then
		local model = instance :: Model
		local primaryPart = model.PrimaryPart
		if primaryPart ~= nil then
			return primaryPart.Position
		end

		return model:GetPivot().Position
	end

	if instance:IsA("BasePart") then
		return (instance :: BasePart).Position
	end

	return nil
end

local function getClosestTaggedPosition(tagName: string): Vector3?
	local playerPosition = getPlayerPosition()
	if playerPosition == nil then
		return nil
	end

	local closestPosition = nil
	local closestDistance = math.huge

	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
		if instance.Parent == nil or not instance:IsDescendantOf(workspace) then
			continue
		end

		local instancePosition = getInstancePosition(instance)
		if instancePosition == nil then
			continue
		end

		local distance = (instancePosition - playerPosition).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestPosition = instancePosition
		end
	end

	return closestPosition
end

local function resolveStepTargetPosition(tutorialStep): Vector3?
	local pointToTags = tutorialStep["pointToTags"]
	if type(pointToTags) == "table" then
		for _, tagName in ipairs(pointToTags) do
			if type(tagName) ~= "string" then
				continue
			end

			local targetPosition = getClosestTaggedPosition(tagName)
			if targetPosition ~= nil then
				return targetPosition
			end
		end
	end

	local pointToPosition = tutorialStep["pointToPosition"]
	if typeof(pointToPosition) == "Vector3" then
		return pointToPosition
	end

	return nil
end

local function destroyPositionIndicator()
	activeIndicatorToken += 1

	if positionIndicator ~= nil then
		positionIndicator:Destroy()
		positionIndicator = nil
	end
end

function createPositionIndicator(targetPoint: Vector3)
	-- Creates a straight beam with arrows from the player's root attachment to an attachment at the target point.
	local playerAttachment = character:WaitForChild("HumanoidRootPart"):WaitForChild("RootAttachment")
	local targetPointPVInstance = Instance.new("Part")
	targetPointPVInstance.Anchored = true
	targetPointPVInstance.CanCollide = false
	targetPointPVInstance.Transparency = 1
	targetPointPVInstance.Size = Vector3.new(1, 1, 1)
	targetPointPVInstance:PivotTo(CFrame.new(targetPoint))

	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Position = Vector3.zero
	targetAttachment.Parent = targetPointPVInstance

	local beam = Instance.new("Beam")
	beam.Attachment0 = playerAttachment
	beam.Attachment1 = targetAttachment
	beam.FaceCamera = true
	beam.Texture = "rbxassetid://97567878064959" -- Arrow texture
	beam.TextureMode = Enum.TextureMode.Static
	beam.Width0 = 4
	beam.Width1 = 4
	beam.TextureLength = 4
	beam.TextureSpeed = 3
	beam.Color = ColorSequence.new(Color3.new(1, 0.5, 0))
	beam.LightEmission = 0.25
	beam.LightInfluence = 0
	beam.Transparency = NumberSequence.new(0)
	beam.Parent = targetPointPVInstance

	targetPointPVInstance.Parent = workspace
	return targetPointPVInstance
end

local function updatePositionIndicatorTarget(targetPoint: Vector3)
	if positionIndicator == nil then
		positionIndicator = createPositionIndicator(targetPoint)
		return
	end

	positionIndicator:PivotTo(CFrame.new(targetPoint))
end

local function startPositionIndicator(tutorialStep)
	local token = activeIndicatorToken

	task.spawn(function()
		while token == activeIndicatorToken do
			local targetPoint = resolveStepTargetPosition(tutorialStep)
			if targetPoint ~= nil then
				updatePositionIndicatorTarget(targetPoint)
			elseif positionIndicator ~= nil then
				positionIndicator:Destroy()
				positionIndicator = nil
			end

			task.wait(INDICATOR_REFRESH_INTERVAL)
		end
	end)
end

function startTutorial(tutorialName: string)
	tutorialsRefFolder:WaitForChild(tutorialName)
	startTutorialEvent:FireServer(tutorialName)
end

function skipTutorial()
	-- TODO: Implement this
end

function sendTutorialSignal(signal)
	signalTutorialEvent:FireServer(signal)
end

function characterAdded(newCharacter)
	character = newCharacter
	maid:DoCleaning()
	destroyPositionIndicator()
end

function onReceiveNextStep(tutorialStep, tutorialName)
	destroyPositionIndicator()

	if tutorialStep.completed then
		return
	end

	local targetPoint = resolveStepTargetPosition(tutorialStep)
	if targetPoint ~= nil then
		positionIndicator = createPositionIndicator(targetPoint)
	end

	if tutorialStep["pointToTags"] ~= nil then
		startPositionIndicator(tutorialStep)
	end
end

function handleScreenTapOrClick(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sendTutorialSignal("click")
	end
end

function main()
	local hasCompletedIntroTutorial = getHasCompletedTutorial(Tutorials.INTRO)
	if hasCompletedIntroTutorial == nil then
		warn("Could not load Intro tutorial state from player data.")
		return
	end

	if not hasCompletedIntroTutorial then
		startTutorial(Tutorials.INTRO)
	end
end

UserInputService.InputBegan:Connect(handleScreenTapOrClick)
plr.CharacterAdded:Connect(characterAdded)
nextTutorialStepEvent.OnClientEvent:Connect(onReceiveNextStep)
main()
