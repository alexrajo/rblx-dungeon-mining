local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localServices = ReplicatedStorage:WaitForChild("local_services")
local HotbarActionService = require(localServices.HotbarActionService)

local player = Players.LocalPlayer

local trackedTools: {[Tool]: {RBXScriptConnection}} = {}

local function isMineAction(actionName: any): boolean
	return type(actionName) == "string" and actionName == "Mine"
end

local function isPrimaryActionEnded(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.ButtonR2
end

local function disconnectTool(tool: Tool)
	local connections = trackedTools[tool]
	if connections == nil then
		return
	end

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	trackedTools[tool] = nil
end

local function trackTool(tool: Tool)
	if trackedTools[tool] ~= nil then
		return
	end

	local connections = {}
	trackedTools[tool] = connections

	table.insert(connections, tool.Activated:Connect(function()
		local actionName = tool:GetAttribute("HotbarActionName")
		if type(actionName) == "string" and actionName ~= "" then
			if isMineAction(actionName) then
				HotbarActionService.StartHoldingMine()
			else
				HotbarActionService.ActivateAction(actionName, tool)
			end
		end
	end))

	table.insert(connections, tool.Destroying:Connect(function()
		HotbarActionService.StopHoldingMine()
		disconnectTool(tool)
	end))
end

local function connectContainer(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") then
			trackTool(child)
		end
	end

	container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			trackTool(child)
		end
	end)

	container.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(function()
				if child.Parent == nil then
					disconnectTool(child)
				end
			end)
		end
	end)
end

local backpack = player:WaitForChild("Backpack")
connectContainer(backpack)

local function onCharacterAdded(character: Model)
	HotbarActionService.StopHoldingMine()
	connectContainer(character)
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(function()
	HotbarActionService.StopHoldingMine()
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if isPrimaryActionEnded(input) then
		HotbarActionService.StopHoldingMine()
	end
end)
