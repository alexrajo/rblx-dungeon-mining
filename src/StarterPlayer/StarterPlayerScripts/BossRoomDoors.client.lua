local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerDataFolder = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(localPlayer.Name)
local latestCompletedBossFloorValue = playerDataFolder:WaitForChild("LatestCompletedBossFloor")

local HIDDEN_DOORS_FOLDER_NAME = "LocalHiddenBossRoomDoors"

local hiddenDoorsFolder = ReplicatedStorage:FindFirstChild(HIDDEN_DOORS_FOLDER_NAME)
if hiddenDoorsFolder == nil then
	hiddenDoorsFolder = Instance.new("Folder")
	hiddenDoorsFolder.Name = HIDDEN_DOORS_FOLDER_NAME
	hiddenDoorsFolder.Parent = ReplicatedStorage
end

local hiddenDoorOpenByRoom: {[Model]: Model} = {}
local originalDoorOpenParentByDoor: {[Model]: Instance} = {}
local bossRoomConnections: {[Model]: {RBXScriptConnection}} = {}

local function getFloorNumberForInstance(instance: Instance?): number?
	local current = instance
	while current ~= nil do
		local floorNumber = current:GetAttribute("FloorNumber")
		if type(floorNumber) == "number" then
			return floorNumber
		end

		current = current.Parent
	end

	return nil
end

local function findDoorModel(root: Instance, doorName: string): Model?
	local door = root:FindFirstChild(doorName, true)
	if door ~= nil and door:IsA("Model") then
		return door
	end

	return nil
end

local function getDoorOpen(bossRoom: Model): Model?
	local hiddenDoor = hiddenDoorOpenByRoom[bossRoom]
	if hiddenDoor ~= nil and hiddenDoor.Parent ~= nil then
		return hiddenDoor
	end

	hiddenDoorOpenByRoom[bossRoom] = nil
	return findDoorModel(bossRoom, "DoorOpen")
end

local function restoreDoorOpen(bossRoom: Model)
	local doorOpen = getDoorOpen(bossRoom)
	if doorOpen == nil then
		return
	end

	local originalParent = originalDoorOpenParentByDoor[doorOpen]
	if originalParent == nil or originalParent.Parent == nil then
		originalParent = bossRoom
	end

	if doorOpen.Parent ~= originalParent then
		doorOpen.Parent = originalParent
	end

	hiddenDoorOpenByRoom[bossRoom] = nil
	originalDoorOpenParentByDoor[doorOpen] = nil
end

local function hideDoorOpen(bossRoom: Model)
	local doorOpen = getDoorOpen(bossRoom)
	if doorOpen == nil then
		return
	end

	if doorOpen.Parent ~= hiddenDoorsFolder then
		originalDoorOpenParentByDoor[doorOpen] = doorOpen.Parent
		hiddenDoorOpenByRoom[bossRoom] = doorOpen
		doorOpen.Parent = hiddenDoorsFolder
	end
end

local function destroyDoorClosed(bossRoom: Model)
	local doorClosed = findDoorModel(bossRoom, "DoorClosed")
	if doorClosed ~= nil then
		doorClosed:Destroy()
	end
end

local function applyDoorState(bossRoom: Model)
	if bossRoom.Parent == nil then
		return
	end

	local floorNumber = getFloorNumberForInstance(bossRoom)
	if floorNumber == nil then
		return
	end

	if latestCompletedBossFloorValue.Value >= floorNumber then
		restoreDoorOpen(bossRoom)
		destroyDoorClosed(bossRoom)
	else
		hideDoorOpen(bossRoom)
	end
end

local function applyAllDoorStates()
	for bossRoom in pairs(bossRoomConnections) do
		applyDoorState(bossRoom)
	end

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and descendant.Name == "BossRoom" then
			applyDoorState(descendant)
		end
	end
end

local function cleanupBossRoom(bossRoom: Model)
	local connections = bossRoomConnections[bossRoom]
	if connections ~= nil then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	local hiddenDoor = hiddenDoorOpenByRoom[bossRoom]
	if hiddenDoor ~= nil then
		originalDoorOpenParentByDoor[hiddenDoor] = nil
		if hiddenDoor.Parent ~= nil then
			hiddenDoor:Destroy()
		end
	end

	hiddenDoorOpenByRoom[bossRoom] = nil
	bossRoomConnections[bossRoom] = nil
end

local function watchBossRoom(bossRoom: Model)
	if bossRoomConnections[bossRoom] ~= nil then
		applyDoorState(bossRoom)
		return
	end

	bossRoomConnections[bossRoom] = {
		bossRoom.DescendantAdded:Connect(function(descendant: Instance)
			if descendant.Name == "DoorOpen" or descendant.Name == "DoorClosed" then
				task.defer(applyDoorState, bossRoom)
			end
		end),
		bossRoom.AncestryChanged:Connect(function(_, parent: Instance?)
			if parent == nil then
				cleanupBossRoom(bossRoom)
			end
		end),
	}

	applyDoorState(bossRoom)
end

local function scanBossRooms()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and descendant.Name == "BossRoom" then
			watchBossRoom(descendant)
		end
	end
end

scanBossRooms()

Workspace.DescendantAdded:Connect(function(descendant: Instance)
	if descendant:IsA("Model") and descendant.Name == "BossRoom" then
		task.defer(watchBossRoom, descendant)
	end
end)

latestCompletedBossFloorValue:GetPropertyChangedSignal("Value"):Connect(function()
	task.defer(applyAllDoorStates)
end)
