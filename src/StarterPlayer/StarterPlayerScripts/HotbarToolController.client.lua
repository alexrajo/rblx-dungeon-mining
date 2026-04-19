local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localServices = ReplicatedStorage:WaitForChild("local_services")
local HotbarActionService = require(localServices.HotbarActionService)
local HotbarService = require(localServices.HotbarService)

local player = Players.LocalPlayer

local trackedTools: {[Tool]: {RBXScriptConnection}} = {}

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
			HotbarActionService.ActivateAction(actionName, tool)
		end
	end))

	table.insert(connections, tool.Destroying:Connect(function()
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
	connectContainer(character)
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
