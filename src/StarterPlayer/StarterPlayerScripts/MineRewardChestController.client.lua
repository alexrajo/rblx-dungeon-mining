local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local localPlayer = Players.LocalPlayer
local mineChestOpenedEvent = APIService.GetEvent("MineChestOpened")

local OPEN_ANIMATION_ID = "rbxassetid://74713289282918"
local PROMPT_NAME = "MineRewardChestPrompt"
local TRACK_LENGTH_TIMEOUT = 3

type ChestState = {
	track: AnimationTrack?,
	isOpenVisual: boolean,
	openSequence: number,
}

local trackedChests: {[Model]: ChestState} = {}
local openedMineChestsFolder: Folder? = nil
local openedFloorOverrides: {[number]: boolean} = {}
local openAnimation = Instance.new("Animation")
openAnimation.AnimationId = OPEN_ANIMATION_ID

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

local function getPrompt(chestModel: Model): ProximityPrompt?
	local primaryPart = chestModel.PrimaryPart
	if primaryPart == nil then
		return nil
	end

	local prompt = primaryPart:FindFirstChild(PROMPT_NAME)
	if prompt ~= nil and prompt:IsA("ProximityPrompt") then
		return prompt
	end

	return nil
end

local function getAnimationTrack(chestModel: Model, state: ChestState): AnimationTrack?
	if state.track ~= nil then
		return state.track
	end

	local animationController = chestModel:FindFirstChildOfClass("AnimationController")
	if animationController == nil then
		warn("MineRewardChestController: Chest model is missing AnimationController", chestModel:GetFullName())
		return nil
	end

	local animator = animationController:FindFirstChildOfClass("Animator")
	if animator == nil then
		warn("MineRewardChestController: Chest AnimationController is missing Animator", chestModel:GetFullName())
		return nil
	end

	local track = animator:LoadAnimation(openAnimation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	state.track = track

	return track
end

local function waitForTrackLength(track: AnimationTrack): number
	local startTime = os.clock()
	while track.Length <= 0 and os.clock() - startTime < TRACK_LENGTH_TIMEOUT do
		task.wait()
	end

	return track.Length
end

local function holdChestOpen(chestModel: Model, state: ChestState)
	local track = getAnimationTrack(chestModel, state)
	if track == nil then
		return
	end

	state.isOpenVisual = true
	local length = waitForTrackLength(track)
	track:Play(0, 1, 0)
	track.TimePosition = if length > 0 then length else 0
	track:AdjustSpeed(0)
end

local function playChestOpen(chestModel: Model, state: ChestState)
	local track = getAnimationTrack(chestModel, state)
	if track == nil then
		return
	end

	state.openSequence += 1
	local sequence = state.openSequence
	state.isOpenVisual = true

	track:Stop(0)
	track:Play(0, 1, 1)
	track.TimePosition = 0

	task.spawn(function()
		local length = waitForTrackLength(track)
		if length > 0 then
			task.wait(math.max(length - track.TimePosition - 0.03, 0))
		else
			task.wait()
		end

		if trackedChests[chestModel] ~= state or state.openSequence ~= sequence then
			return
		end

		holdChestOpen(chestModel, state)
	end)
end

local function updateChestAppearance(chestModel: Model, shouldAnimateOpen: boolean?)
	local state = trackedChests[chestModel]
	if state == nil then
		return
	end

	local floorNumber = chestModel:GetAttribute("FloorNumber")
	if type(floorNumber) ~= "number" then
		return
	end

	local isOpened = hasOpenedChestForFloor(floorNumber)
	local prompt = getPrompt(chestModel)
	if prompt ~= nil then
		prompt.Enabled = not isOpened
	end

	if isOpened and not state.isOpenVisual then
		if shouldAnimateOpen == true then
			playChestOpen(chestModel, state)
		else
			task.spawn(function()
				if trackedChests[chestModel] == state then
					holdChestOpen(chestModel, state)
				end
			end)
		end
	end
end

local function refreshAllChests()
	for chestModel in pairs(trackedChests) do
		if chestModel.Parent == nil then
			trackedChests[chestModel] = nil
		else
			updateChestAppearance(chestModel, false)
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
	if not instance:IsA("Model") then
		warn("MineRewardChestController: Expected a Model, got", instance:GetFullName())
		return
	end

	local chestModel = instance :: Model
	if trackedChests[chestModel] then
		return
	end

	trackedChests[chestModel] = {
		track = nil,
		isOpenVisual = false,
		openSequence = 0,
	}
	updateChestAppearance(chestModel, false)

	chestModel:GetAttributeChangedSignal("FloorNumber"):Connect(function()
		updateChestAppearance(chestModel, false)
	end)

	local primaryPart = chestModel.PrimaryPart
	if primaryPart ~= nil then
		primaryPart.ChildAdded:Connect(function(child)
			if child.Name == PROMPT_NAME then
				updateChestAppearance(chestModel, false)
			end
		end)
	end

	chestModel:GetPropertyChangedSignal("PrimaryPart"):Connect(function()
		local newPrimaryPart = chestModel.PrimaryPart
		if newPrimaryPart ~= nil then
			updateChestAppearance(chestModel, false)
			newPrimaryPart.ChildAdded:Connect(function(child)
				if child.Name == PROMPT_NAME then
					updateChestAppearance(chestModel, false)
				end
			end)
		end
	end)

	chestModel.Destroying:Connect(function()
		local state = trackedChests[chestModel]
		if state ~= nil and state.track ~= nil then
			state.track:Stop(0)
			state.track:Destroy()
		end
		trackedChests[chestModel] = nil
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
			updateChestAppearance(chestInstance, true)
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
