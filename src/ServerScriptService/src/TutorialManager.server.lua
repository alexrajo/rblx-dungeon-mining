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
local RECENT_SIGNAL_LIMIT = 10
local NON_REPLAYABLE_SIGNALS = {
	click = true,
}
local COMPLETED_STEP = {
	id = "Completed",
	completed = true,
}

function getOrCreateTutorialState(player: Player)
	local state = playerTutorialStates[player]
	if not state then
		state = {
			currentTutorial = nil,
			currentStep = 1,
			recentSignals = {},
		}
		playerTutorialStates[player] = state
	end
	return state
end

function preprocessStep(player: Player, step)
	step["pointToPosition"] = nil

	if step["pointToPositionFunction"] ~= nil and type(step["pointToPositionFunction"]) == "function" then
		step["pointToPosition"] = step["pointToPositionFunction"](player)
	end
end

function recordRecentSignal(playerState, signal: string)
	local recentSignals = playerState.recentSignals
	local existingIndex = table.find(recentSignals, signal)
	if existingIndex ~= nil then
		table.remove(recentSignals, existingIndex)
	end

	table.insert(recentSignals, signal)

	while #recentSignals > RECENT_SIGNAL_LIMIT do
		table.remove(recentSignals, 1)
	end
end

function stepWasCompletedRecently(playerState, step): boolean
	local completeOn = step.completeOn
	if completeOn == nil or NON_REPLAYABLE_SIGNALS[completeOn] then
		return false
	end

	return table.find(playerState.recentSignals, completeOn) ~= nil
end

function activateTutorialStep(player: Player, tutorialName: string, stepIndex: number)
	local playerState = getOrCreateTutorialState(player)
	local tutorial = tutorials[tutorialName]
	local tutorialSteps = tutorial.steps
	local stepToActivate = stepIndex

	while stepToActivate <= #tutorialSteps do
		local tutorialStep = tutorialSteps[stepToActivate]
		if not stepWasCompletedRecently(playerState, tutorialStep) then
			playerState.currentStep = stepToActivate

			preprocessStep(player, tutorialStep)
			sendNextStepClientEvent:FireClient(player, tutorialStep, tutorialName)
			return
		end

		stepToActivate += 1
	end

	completeTutorial(player, tutorialName)
	sendNextStepClientEvent:FireClient(player, COMPLETED_STEP, tutorialName)
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

	activateTutorialStep(player, tutorialName, 1)
end

function signalReceived(player: Player, signal: string)
	local playerState = getOrCreateTutorialState(player)
	recordRecentSignal(playerState, signal)

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
	activateTutorialStep(player, playerState.currentTutorial, newStep)
end

function skipTutorial(player: Player)
	local playerState = playerTutorialStates[player]
	if playerState == nil or playerState.currentTutorial == nil then
		return
	end

	local activeTutorialName = playerState.currentTutorial
	PlayerDataHandler.CompleteTutorial(player, activeTutorialName, nil)
	sendNextStepClientEvent:FireClient(player, COMPLETED_STEP, activeTutorialName)

	playerState.currentTutorial = nil
	playerState.currentStep = 0
end

function completeTutorial(player: Player, tutorialName: string?)
	local playerState = playerTutorialStates[player]
	if playerState == nil or playerState.currentTutorial == nil then
		return
	end

	local activeTutorialName = tutorialName or playerState.currentTutorial
	if activeTutorialName == nil then
		return
	end

	local tutorial = tutorials[activeTutorialName]
	local tutorialSteps = tutorial.steps
	local playerIsAtLastStep = playerState.currentStep >= #tutorialSteps
	local playerHasCompletedTutorialBefore =
		PlayerDataHandler.GetTutorialIsCompleted(player, activeTutorialName)

	if playerIsAtLastStep and not playerHasCompletedTutorialBefore then
		PlayerDataHandler.CompleteTutorial(player, activeTutorialName, tutorial.rewards)
	end

	playerState.currentTutorial = nil
	playerState.currentStep = 0
end

function onPlayerCharacterAdded(player: Player)
	local playerState = playerTutorialStates[player]
	if playerState == nil or playerState.currentTutorial == nil then
		return
	end

	activateTutorialStep(player, playerState.currentTutorial, playerState.currentStep)
end

game.Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function()
		onPlayerCharacterAdded(player)
	end)
end)

game.Players.PlayerRemoving:Connect(playerRemoving)
startTutorialEvent.Event:Connect(startTutorial)
skipTutorialEvent.Event:Connect(skipTutorial)
signalTutorialEvent.Event:Connect(signalReceived)
