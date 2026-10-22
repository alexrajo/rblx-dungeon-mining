local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.configs.ActionConfig)
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local ActionFireService = require(ReplicatedStorage.local_services.ActionFireService)
local HotbarService = require(ReplicatedStorage.local_services.HotbarService)
local Runtime = require(ReplicatedStorage.local_services.ActionRuntime)

local player = Players.LocalPlayer
local HotbarActionService = {}
local cachedActions = {}
local callbacks = {}
local readyAt = 0
local invoking = false
local reportedReady = true
local deadlineVersion = 0
local queued = nil
local holdingMine = false
local holdTool = nil
local tryHold: () -> ()

local function emitReady(): ()
	local ready = not invoking and os.clock() >= readyAt
	if ready == reportedReady then return end
	reportedReady = ready
	for _, callback in ipairs(callbacks) do
		local ok, err = pcall(callback, ready)
		if not ok then warn("HotbarActionService: readiness callback failed", err) end
	end
end

function HotbarActionService.IsActionReady(): boolean
	return not invoking and os.clock() >= readyAt
end

local function scheduleReady(): ()
	deadlineVersion += 1
	local version = deadlineVersion
	task.delay(math.max(0, readyAt - os.clock()), function()
		if version ~= deadlineVersion then return end
		emitReady()
		local pending = queued
		queued = nil
		if pending and pending.floor == Runtime.GetFloor()
			and Runtime.IsValid(pending.tool, pending.character) then
			HotbarActionService.ActivateAction(pending.actionName, pending.tool)
		elseif holdingMine then
			tryHold()
		end
	end)
end

function HotbarActionService.ActivateAction(actionName: string, tool: Tool?): boolean
	if not Runtime.IsValid(tool, player.Character) then return false end
	if not HotbarActionService.IsActionReady() then
		if not invoking and readyAt - os.clock() <= Config.INPUT_BUFFER
			and (actionName == "Mine" or actionName == "Attack") then
			queued = {actionName = actionName, tool = tool, character = player.Character, floor = Runtime.GetFloor()}
			return true
		end
		return false
	end
	queued = nil
	invoking = true
	local startedAt = os.clock()
	emitReady()
	local ok, cooldown = xpcall(function()
		if not cachedActions[actionName] then cachedActions[actionName] = ActionFireService.GetAction(actionName) end
		return cachedActions[actionName]:Invoke(tool)
	end, debug.traceback)
	invoking = false
	if not ok then
		warn("HotbarActionService: action failed", cooldown)
		cooldown = 0
		holdingMine = false
		holdTool = nil
	end
	if type(cooldown) ~= "number" or cooldown ~= cooldown or cooldown == math.huge then cooldown = 0 end
	readyAt = startedAt + math.max(0, cooldown)
	emitReady()
	scheduleReady()
	return ok
end

tryHold = function(): ()
	if not holdingMine or not HotbarActionService.IsActionReady() then return end
	local tool = HotbarService.GetSelectedTool()
	if not tool then return end -- Tool/selection signals retry when equipping finishes.
	if tool ~= holdTool and holdTool ~= nil then
		HotbarActionService.StopHoldingMine()
		return
	end
	local itemName = tool:GetAttribute("HotbarItemName")
	if tool:GetAttribute("HotbarActionName") ~= "Mine" or type(itemName) ~= "string"
		or HotbarConfig.GetActionName(itemName) ~= "Mine" then
		HotbarActionService.StopHoldingMine()
		return
	end
	holdTool = tool
	HotbarActionService.ActivateAction("Mine", tool)
end

function HotbarActionService.StartHoldingMine(): boolean
	if holdingMine then return true end
	holdingMine = true
	holdTool = HotbarService.GetSelectedTool()
	tryHold()
	return true
end

function HotbarActionService.StopHoldingMine(): ()
	holdingMine = false
	holdTool = nil
	if queued and queued.actionName == "Mine" then queued = nil end
end

function HotbarActionService.ActivateSelected(): boolean
	local tool = HotbarService.GetSelectedTool()
	if not tool then return false end
	local actionName = tool:GetAttribute("HotbarActionName")
	local itemName = tool:GetAttribute("HotbarItemName")
	if type(actionName) ~= "string" or type(itemName) ~= "string"
		or HotbarConfig.GetActionName(itemName) ~= actionName then return false end
	return HotbarActionService.ActivateAction(actionName, tool)
end

function HotbarActionService.OnActionReadyChanged(callback: (boolean) -> ()): () -> ()
	table.insert(callbacks, callback)
	return function()
		local index = table.find(callbacks, callback)
		if index then table.remove(callbacks, index) end
	end
end

Runtime.OnCancelled(function()
	queued = nil
	HotbarActionService.StopHoldingMine()
end)

task.spawn(function()
	HotbarService.OnChanged(function() if holdingMine then task.defer(tryHold) end end)
	local function watchCharacter(character: Model): ()
		character.ChildAdded:Connect(function(child: Instance)
			if child:IsA("Tool") and holdingMine then task.defer(tryHold) end
		end)
	end
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then watchCharacter(player.Character) end
end)

return HotbarActionService
