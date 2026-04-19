local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local ActionFireService = require(ReplicatedStorage.local_services.ActionFireService)
local HotbarService = require(ReplicatedStorage.local_services.HotbarService)

local HotbarActionService = {}

local cachedActions: {[string]: BindableFunction} = {}
local actionReady = true
local callbacks = {}

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
