local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local APIFolderName = "APIServiceEndpoints"
local APIFolder = ReplicatedStorage:FindFirstChild(APIFolderName)
local randomSeed = tick()
local eventFolder, functionFolder

local events: {RemoteEvent} = {}
local functions: {RemoteFunction} = {}

if APIFolder == nil then
	local folder = Instance.new("Folder")
	folder.Name = APIFolderName
	
	eventFolder = Instance.new("Folder")
	eventFolder.Name = "Events"
	eventFolder.Parent = folder
	
	functionFolder = Instance.new("Folder")
	functionFolder.Name = "Functions"
	functionFolder.Parent = folder
	
	folder.Parent = ReplicatedStorage
	APIFolder = folder
else
	-- If the API folder already exists, initialize the data fields in the module
	if eventFolder == nil then
		eventFolder = APIFolder:WaitForChild("Events")
	end
	if functionFolder == nil then
		functionFolder = APIFolder:WaitForChild("Functions")
	end
	
	for _, event in pairs(eventFolder:GetChildren()) do
		local name = event.Name
		events[name] = event
	end
	for _, func in pairs(functionFolder:GetChildren()) do
		local name = func.Name
		functions[name] = func
	end
end

local APIService = {}

function APIService._createEvent(name: string)
	if events[name] ~= nil then
		return nil
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = eventFolder
	events[name] = event
	return event
end

function APIService._createFunction(name: string)
	if functions[name] ~= nil then
		return nil
	end
	local func = Instance.new("RemoteFunction")
	func.Name = name
	func.Parent = functionFolder
	functions[name] = func
	return func
end

function APIService:CreateEventEndpoint(name: string, serverHandler: (Player, ...any) -> ()?)
	if not RunService:IsServer() then
		error("Can only create endpoints on the server")
	end
	local event: RemoteEvent = self._createEvent(name)
	if event ~= nil and serverHandler ~= nil then
		event.OnServerEvent:Connect(serverHandler)
	else
		return false
	end
	return true
end

function APIService:CreateFunctionEndpoint(name: string, serverHandler: (Player, ...any) -> ()?)
	if not RunService:IsServer() then
		error("Can only create endpoints on the server")
	end
	local func: RemoteFunction = self._createFunction(name)
	if func ~= nil and serverHandler ~= nil then
		func.OnServerInvoke = serverHandler
	else
		return false
	end
	return true
end

function APIService.GetEvent(name: string)
	local event
	for i = 1, 50 do
		event = events[name]
		if event ~= nil then break end
		task.wait(0.1)
	end
	if event == nil then
		error("Event "..name.." does not exist!")
	end
	return event
end

function APIService.GetFunction(name: string)
	local func
	for i = 1, 50 do
		func = functions[name]
		if func ~= nil then break end
		task.wait(0.1)
	end
	if func == nil then
		error("Function "..name.." does not exist!")
	end
	return func
end

local function onRemoteEventAdded(event: RemoteEvent)
	local name = event.Name
	if events[name] ~= nil then
		warn("onRemoteEventAdded: The remote event "..name.." is being overwritten!")
	end
	events[name] = event
end

local function onRemoteEventRemoved(event: RemoteEvent)
	local name = event.Name
	if events[name] ~= nil then
		events[name] = nil
	end
end

local function onRemoteFunctionAdded(func: RemoteFunction)
	local name = func.Name
	if functions[name] ~= nil then
		warn("onRemoteFunctionAdded: The remote function "..name.." is being overwritten!")
	end
	functions[name] = func
end

local function onRemoteFunctionRemoved(func: RemoteFunction)
	local name = func.Name
	if functions[name] ~= nil then
		functions[name] = nil
	end
end

eventFolder.ChildAdded:Connect(onRemoteEventAdded)
eventFolder.ChildRemoved:Connect(onRemoteEventRemoved)
functionFolder.ChildAdded:Connect(onRemoteFunctionAdded)
functionFolder.ChildRemoved:Connect(onRemoteFunctionRemoved)

return APIService
