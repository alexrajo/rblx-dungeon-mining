local plr = game.Players.LocalPlayer
local character = plr.Character

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

function startTutorial(tutorialName: string)
	local ref = tutorialsRefFolder:WaitForChild(tutorialName)
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

    if positionIndicator ~= nil then
        positionIndicator:Destroy()
    end
end

function onReceiveNextStep(tutorialStep, tutorialName)
	-- TODO: Implement this
	print(tutorialStep, tutorialName)
    if positionIndicator ~= nil then
        positionIndicator:Destroy()
    end

    local pointToPosition = tutorialStep["pointToPosition"]
    if pointToPosition ~= nil then
        positionIndicator = createPositionIndicator(pointToPosition)
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
