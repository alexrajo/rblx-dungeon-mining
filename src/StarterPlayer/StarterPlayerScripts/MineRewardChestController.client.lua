local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local localPlayer = Players.LocalPlayer
local mineChestOpenedEvent = APIService.GetEvent("MineChestOpened")

local CLOSED_BRICK_COLOR = BrickColor.new("Reddish brown")
local OPEN_BRICK_COLOR = BrickColor.new("Lime green")
local PROMPT_NAME = "MineRewardChestPrompt"

local trackedChests: {[Instance]: boolean} = {}
local openedMineChestsFolder: Folder? = nil
local openedFloorOverrides: {[number]: boolean} = {}

local function hasOpenedChestForFloor(floorNumber: number): boolean
	if openedFloorOverrides[floorNumber] == true then
		return true
	end

	if openedMineChestsFolder == nil then
		return false
	end

	local entry = openedMineChestsFolder:FindFirstChild(tostring(floorNumber))
	return entry ~= nil and entry:IsA("BoolValue") and entry.Value == true
end

local function updateChestAppearance(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end

	local floorNumber = instance:GetAttribute("FloorNumber")
	if type(floorNumber) ~= "number" then
		return
	end

	local isOpened = hasOpenedChestForFloor(floorNumber)
	instance.BrickColor = if isOpened then OPEN_BRICK_COLOR else CLOSED_BRICK_COLOR

	local prompt = instance:FindFirstChild(PROMPT_NAME)
	if prompt ~= nil and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = not isOpened
	end
end

local function refreshAllChests()
	for chestInstance in pairs(trackedChests) do
		if chestInstance.Parent == nil then
			trackedChests[chestInstance] = nil
		else
			updateChestAppearance(chestInstance)
		end
	end
end

local function trackOpenedMineChests(folder: Folder)
	openedMineChestsFolder = folder

	folder.ChildAdded:Connect(refreshAllChests)
	folder.ChildRemoved:Connect(refreshAllChests)

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BoolValue") then
			child.Changed:Connect(refreshAllChests)
		end
	end

	folder.ChildAdded:Connect(function(child)
		if child:IsA("BoolValue") then
			child.Changed:Connect(refreshAllChests)
		end
	end)

	refreshAllChests()
end

local function trackChest(instance: Instance)
	if trackedChests[instance] then
		return
	end

	trackedChests[instance] = true
	updateChestAppearance(instance)

	instance:GetAttributeChangedSignal("FloorNumber"):Connect(function()
		updateChestAppearance(instance)
	end)

	instance.ChildAdded:Connect(function(child)
		if child.Name == PROMPT_NAME then
			updateChestAppearance(instance)
		end
	end)

	instance.Destroying:Connect(function()
		trackedChests[instance] = nil
	end)
end

for _, chestInstance in ipairs(CollectionService:GetTagged("MineRewardChest")) do
	trackChest(chestInstance)
end

CollectionService:GetInstanceAddedSignal("MineRewardChest"):Connect(trackChest)
CollectionService:GetInstanceRemovedSignal("MineRewardChest"):Connect(function(instance)
	trackedChests[instance] = nil
end)

mineChestOpenedEvent.OnClientEvent:Connect(function(floorNumber: number)
	openedFloorOverrides[floorNumber] = true

	for chestInstance in pairs(trackedChests) do
		if chestInstance:GetAttribute("FloorNumber") == floorNumber then
			updateChestAppearance(chestInstance)
		end
	end
end)

local playerDataFolder = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(localPlayer.Name)
local openedFolder = playerDataFolder:FindFirstChild("OpenedMineChests")
if openedFolder ~= nil and openedFolder:IsA("Folder") then
	trackOpenedMineChests(openedFolder)
else
	playerDataFolder.ChildAdded:Connect(function(child)
		if child.Name == "OpenedMineChests" and child:IsA("Folder") then
			trackOpenedMineChests(child)
		end
	end)
end
