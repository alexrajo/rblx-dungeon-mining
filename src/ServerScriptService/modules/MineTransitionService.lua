local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local modules = ServerScriptService.modules
local MineFloorManager = require(modules.MineFloorManager)
local PlayerDataHandler = require(modules.PlayerDataHandler)

local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial

local PROTECTION_ATTRIBUTE = "TeleportProtected"
local TRANSITION_TIMEOUT = 4

local activeTransitions: { [Player]: {
	transitionId: string,
	kind: string,
	state: string,
	startedAt: number,
	startFloor: number?,
	targetFloor: number?,
} } = {}

local MineTransitionService = {}

local function generateTransitionId(player: Player): string
	return string.format(
		"%d_%d_%d",
		player.UserId,
		math.floor(os.clock() * 1000),
		math.random(100000, 999999)
	)
end

local function setProtectionAttribute(player: Player, isProtected: boolean)
	player:SetAttribute(PROTECTION_ATTRIBUTE, isProtected)

	local character = player.Character
	if character ~= nil then
		character:SetAttribute(PROTECTION_ATTRIBUTE, isProtected)
	end
end

local function clearTransition(player: Player)
	activeTransitions[player] = nil
	setProtectionAttribute(player, false)
end

local function scheduleTimeout(player: Player, transitionId: string)
	task.delay(TRANSITION_TIMEOUT, function()
		local transition = activeTransitions[player]
		if transition == nil or transition.transitionId ~= transitionId then
			return
		end

		clearTransition(player)
	end)
end

local function fireStartEvent(player: Player, transition)
	APIService.GetEvent("StartMineTransition"):FireClient(player, {
		transitionId = transition.transitionId,
		kind = transition.kind,
	})
end

local function beginTransition(player: Player, kind: string, startFloor: number?, targetFloor: number?): boolean
	if activeTransitions[player] ~= nil then
		return false
	end

	local transition = {
		transitionId = generateTransitionId(player),
		kind = kind,
		state = "pending_blackout",
		startedAt = os.clock(),
		startFloor = startFloor,
		targetFloor = targetFloor,
	}

	activeTransitions[player] = transition
	setProtectionAttribute(player, true)
	fireStartEvent(player, transition)
	scheduleTimeout(player, transition.transitionId)

	return true
end

local function runTransitionAction(player: Player, transition): boolean
	if transition.kind == "enter" then
		return MineFloorManager.EnterMine(player, transition.startFloor or 1)
	elseif transition.kind == "checkpoint" then
		local targetFloor = transition.targetFloor or 1
		if PlayerDataHandler.GetInMine(player) then
			return MineFloorManager.TravelToCheckpoint(player, targetFloor)
		end
		return MineFloorManager.EnterMine(player, targetFloor)
	elseif transition.kind == "descend" then
		return MineFloorManager.DescendFloor(player)
	elseif transition.kind == "exit" then
		return MineFloorManager.ExitMine(player)
	end

	return false
end

local function signalTransitionTutorialStep(player: Player, transition)
	if transition.kind == "enter" then
		signalTutorialEvent:Fire(player, "enterMine")
	elseif transition.kind == "descend" then
		signalTutorialEvent:Fire(player, "descend")
	end
end

function MineTransitionService.StartEnterTransition(player: Player, startFloor: number?): boolean
	local sanitizedFloor = 1
	if type(startFloor) == "number" then
		sanitizedFloor = math.max(1, math.floor(startFloor))
	end

	return beginTransition(player, "enter", sanitizedFloor)
end

function MineTransitionService.StartCheckpointTransition(player: Player, targetFloor: number): boolean
	local sanitizedFloor = math.max(1, math.floor(targetFloor))
	return beginTransition(player, "checkpoint", nil, sanitizedFloor)
end

function MineTransitionService.StartDescendTransition(player: Player): boolean
	return beginTransition(player, "descend")
end

function MineTransitionService.StartExitTransition(player: Player): boolean
	return beginTransition(player, "exit")
end

function MineTransitionService.CompleteTransition(player: Player, transitionId: string)
	local transition = activeTransitions[player]
	if transition == nil then
		return { success = false, reason = "no_active_transition" }
	end

	if transition.transitionId ~= transitionId then
		return { success = false, reason = "invalid_transition" }
	end

	if transition.state ~= "pending_blackout" then
		return { success = false, reason = "transition_already_completed" }
	end

	transition.state = "teleporting"

	local success = runTransitionAction(player, transition)
	if not success then
		clearTransition(player)
		return { success = false, reason = "teleport_failed" }
	end

	signalTransitionTutorialStep(player, transition)

	transition.state = "waiting_for_finish"
	scheduleTimeout(player, transition.transitionId)

	return { success = true }
end

function MineTransitionService.FinishTransition(player: Player, transitionId: string)
	local transition = activeTransitions[player]
	if transition == nil then
		return
	end

	if transition.transitionId ~= transitionId then
		return
	end

	if transition.state ~= "waiting_for_finish" then
		return
	end

	clearTransition(player)
end

function MineTransitionService.IsPlayerProtected(player: Player): boolean
	return activeTransitions[player] ~= nil
end

function MineTransitionService.Init()
	Players.PlayerRemoving:Connect(function(player: Player)
		clearTransition(player)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			character:SetAttribute(PROTECTION_ATTRIBUTE, MineTransitionService.IsPlayerProtected(player))
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function(character: Model)
			character:SetAttribute(PROTECTION_ATTRIBUTE, MineTransitionService.IsPlayerProtected(player))
		end)
	end
end

return MineTransitionService
