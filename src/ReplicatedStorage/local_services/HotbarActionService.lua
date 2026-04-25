local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local ActionFireService = require(ReplicatedStorage.local_services.ActionFireService)
local HotbarService = require(ReplicatedStorage.local_services.HotbarService)

local HotbarActionService = {}

local cachedActions: {[string]: BindableFunction} = {}
local actionReady = true
local callbacks = {}
local holdingMine = false
local mineHoldVersion = 0

local function emitChanged()
	for _, callback in ipairs(callbacks) do
		callback(actionReady)
	end
end

local function setActionReady(nextValue: boolean)
	if actionReady == nextValue then
		return
	end

	actionReady = nextValue
	emitChanged()
end

local function getAction(name: string): BindableFunction?
	if cachedActions[name] == nil then
		cachedActions[name] = ActionFireService.GetAction(name)
	end
	return cachedActions[name]
end

function HotbarActionService.IsActionReady(): boolean
	return actionReady
end

function HotbarActionService.ActivateAction(actionName: string, tool: Tool?): boolean
	if not actionReady then
		return false
	end

	local action = getAction(actionName)
	if action == nil then
		return false
	end

	setActionReady(false)
	local cooldownTime = action:Invoke(tool)
	if cooldownTime == nil then
		cooldownTime = 0
	end

	task.delay(cooldownTime, function()
		setActionReady(true)
	end)

	return true
end

local function isMineTool(actionName: string, tool: Tool?): boolean
	if actionName ~= "Mine" or tool == nil then
		return false
	end

	local itemName = tool:GetAttribute("HotbarItemName")
	return type(itemName) == "string" and HotbarConfig.GetActionName(itemName) == "Mine"
end

local function getSelectedMineTool(): (Tool?, boolean)
	local tool = HotbarService.GetSelectedTool()
	if tool == nil then
		return nil, true
	end

	local actionName = tool:GetAttribute("HotbarActionName")
	if type(actionName) ~= "string" or not isMineTool(actionName, tool) then
		return nil, false
	end

	return tool, true
end

function HotbarActionService.StartHoldingMine(): boolean
	if holdingMine then
		return true
	end

	holdingMine = true
	mineHoldVersion += 1
	local version = mineHoldVersion

	task.spawn(function()
		while holdingMine and mineHoldVersion == version do
			local tool, canKeepWaiting = getSelectedMineTool()
			if tool == nil then
				if HotbarService.GetSelectedSlot() == 0 or not canKeepWaiting then
					holdingMine = false
					break
				end

				task.wait(0.03)
				continue
			end

			if actionReady then
				HotbarActionService.ActivateAction("Mine", tool)
			end

			task.wait(0.03)
		end
	end)

	return true
end

function HotbarActionService.StopHoldingMine()
	holdingMine = false
	mineHoldVersion += 1
end

function HotbarActionService.ActivateSelected(): boolean
	local tool = HotbarService.GetSelectedTool()
	if tool == nil then
		return false
	end

	local actionName = tool:GetAttribute("HotbarActionName")
	local itemName = tool:GetAttribute("HotbarItemName")
	if type(actionName) ~= "string" or actionName == "" then
		return false
	end
	if type(itemName) ~= "string" or HotbarConfig.GetActionName(itemName) ~= actionName then
		return false
	end

	return HotbarActionService.ActivateAction(actionName, tool)
end

function HotbarActionService.OnActionReadyChanged(callback: (boolean) -> ()): () -> ()
	table.insert(callbacks, callback)
	return function()
		for index, existingCallback in ipairs(callbacks) do
			if existingCallback == callback then
				table.remove(callbacks, index)
				break
			end
		end
	end
end

return HotbarActionService
