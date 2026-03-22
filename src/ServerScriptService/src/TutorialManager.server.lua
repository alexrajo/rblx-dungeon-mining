local ServerScriptService = game:GetService("ServerScriptService")
local serverModules = ServerScriptService.modules
local PlayerDataHandler = require(serverModules.PlayerDataHandler)

local ServerStorage = game:GetService("ServerStorage")
local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local startTutorialEvent = crossScriptCommunicationBindables.StartTutorial
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial
local skipTutorialEvent = crossScriptCommunicationBindables.SkipTutorial

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.utils.ModuleLoader)
local services = ReplicatedStorage.services
local APIService = require(services.APIService)

local sendNextStepClientEvent = APIService.GetEvent("SendNextTutorialStep")

local tutorialRefFolder = ReplicatedStorage.tutorials
local tutorials = ModuleLoader.shallowLoad(tutorialRefFolder)

local playerTutorialStates = {}

function getOrCreateTutorialState(player: Player)
	local state = playerTutorialStates[player]
	if not state then
		state = {
			currentTutorial = nil,
			currentStep = 1,
		}
		playerTutorialStates[player] = state
	end
	return state
end

function preprocessStep(step)
    -- In place update of step
    if step["pointToPositionFunction"] ~= nil and type(step["pointToPositionFunction"]) == "function" then
        step["pointToPosition"] = step["pointToPositionFunction"]()
    end
end

function playerRemoving(player: Player)
	playerTutorialStates[player] = nil
end

function startTutorial(player: Player, tutorialName: string)
	local playerState = getOrCreateTutorialState(player)
	if playerState.currentTutorial ~= nil then
		return
	end
	playerState.currentTutorial = tutorialName
	playerState.currentStep = 1

	local tutorial = tutorials[tutorialName]
	local steps = tutorial.steps
    local stepToSend = steps[1]
    preprocessStep(stepToSend)
	sendNextStepClientEvent:FireClient(player, stepToSend, tutorialName)
end

function signalReceived(player: Player, signal: string)
	local playerState = playerTutorialStates[player]
	if playerState.currentTutorial == nil then
		return
	end
	-- Do validation (check if the step completeOn matches the signal)
	local tutorial = tutorials[playerState.currentTutorial]
	local tutorialStep = tutorial.steps[playerState.currentStep]
	local completeOn = tutorialStep.completeOn
	if signal ~= completeOn then
		return
	end
	local newStep = playerState.currentStep + 1
	playerState.currentStep = newStep
	if playerState.currentStep > #tutorial.steps then
		-- Tutorial is finished
		completeTutorial(player)
		-- Fire event to client to notify of completed tutorial
		sendNextStepClientEvent:FireClient(player, { id = "Completed" }, playerState.currentTutorial)
		return
	end
	-- Fire event to client with new step information
    local stepToSend = tutorial.steps[newStep]
    preprocessStep(stepToSend)
	sendNextStepClientEvent:FireClient(player, stepToSend, playerState.currentTutorial)
end

function skipTutorial(player: Player)
	local playerState = playerTutorialStates[player]
	if playerState.currentTutorial == nil then
		return
	end

	local playerHasCompletedTutorialBefore =
		PlayerDataHandler.GetTutorialIsCompleted(player, playerState.currentTutorial)
	if not playerHasCompletedTutorialBefore then
		PlayerDataHandler.CompleteTutorial(player)
	end

	playerState.currentTutorial = nil
	playerState.currentStep = 0
end

function completeTutorial(player: Player)
	local playerState = playerTutorialStates[player]
	if playerState.currentTutorial == nil then
		return
	end

	local tutorial = tutorials[playerState.currentTutorial]
	local tutorialSteps = tutorial.steps
	local playerIsAtLastStep = #tutorialSteps
	local playerHasCompletedTutorialBefore =
		PlayerDataHandler.GetTutorialIsCompleted(player, playerState.currentTutorial)

	if playerIsAtLastStep and not playerHasCompletedTutorialBefore then
		-- Give reward and save tutorial completion to player data
		PlayerDataHandler.CompleteTutorial(player, playerState.currentTutorial, tutorial.rewards)
	end

	playerState.currentTutorial = nil
	playerState.currentStep = 0
end

game.Players.PlayerRemoving:Connect(playerRemoving)
startTutorialEvent.Event:Connect(startTutorial)
skipTutorialEvent.Event:Connect(skipTutorial)
signalTutorialEvent.Event:Connect(signalReceived)
