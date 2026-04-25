local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local localPlayer = Players.LocalPlayer
local mineChestOpenedEvent = APIService.GetEvent("MineChestOpened")

local OPEN_ANIMATION_ID = "rbxassetid://74713289282918"
local OPENED_ANIMATION_ID = "rbxassetid://94346372242641"
local PROMPT_NAME = "MineRewardChestPrompt"

type ChestState = {
	openingTrack: AnimationTrack?,
	openedTrack: AnimationTrack?,
	finishConnection: RBXScriptConnection?,
	isOpenVisual: boolean,
	openSequence: number,
}

local trackedChests: {[Model]: ChestState} = {}
local openedMineChestsFolder: Folder? = nil
local openedFloorOverrides: {[number]: boolean} = {}
local openAnimation = Instance.new("Animation")
openAnimation.AnimationId = OPEN_ANIMATION_ID
local openedAnimation = Instance.new("Animation")
openedAnimation.AnimationId = OPENED_ANIMATION_ID

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

local function getAnimator(chestModel: Model): Animator?
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

	return animator
end

local function getOpeningTrack(chestModel: Model, state: ChestState): AnimationTrack?
	if state.openingTrack ~= nil then
		return state.openingTrack
	end

	local animator = getAnimator(chestModel)
	if animator == nil then
		return nil
	end

	local track = animator:LoadAnimation(openAnimation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	state.openingTrack = track

	return track
end

local function getOpenedTrack(chestModel: Model, state: ChestState): AnimationTrack?
	if state.openedTrack ~= nil then
		return state.openedTrack
	end

	local animator = getAnimator(chestModel)
	if animator == nil then
		return nil
	end

	local track = animator:LoadAnimation(openedAnimation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	state.openedTrack = track

	return track
end

local function disconnectFinishConnection(state: ChestState)
	if state.finishConnection ~= nil then
		state.finishConnection:Disconnect()
		state.finishConnection = nil
	end
end

local function stopChestAnimations(state: ChestState)
	disconnectFinishConnection(state)
	state.openSequence += 1
	state.isOpenVisual = false

	if state.openingTrack ~= nil then
		state.openingTrack:Stop(0)
	end
	if state.openedTrack ~= nil then
		state.openedTrack:Stop(0)
	end
end

local function destroyChestState(state: ChestState)
	disconnectFinishConnection(state)

	if state.openingTrack ~= nil then
		state.openingTrack:Stop(0)
		state.openingTrack:Destroy()
	end
	if state.openedTrack ~= nil then
		state.openedTrack:Stop(0)
		state.openedTrack:Destroy()
	end
end

local function playOpenedLoop(chestModel: Model, state: ChestState)
	disconnectFinishConnection(state)
	state.isOpenVisual = true

	if state.openingTrack ~= nil then
		state.openingTrack:Stop(0)
	end

	local openedTrack = getOpenedTrack(chestModel, state)
	if openedTrack == nil then
		return
	end

	if not openedTrack.IsPlaying then
		openedTrack:Play(0)
	end
end

local function playOpeningThenOpenedLoop(chestModel: Model, state: ChestState)
	local openingTrack = getOpeningTrack(chestModel, state)
	if openingTrack == nil then
		return
	end

	state.openSequence += 1
	local sequence = state.openSequence
	state.isOpenVisual = true

	disconnectFinishConnection(state)
	if state.openedTrack ~= nil then
		state.openedTrack:Stop(0)
	end

	openingTrack:Stop(0)
	state.finishConnection = openingTrack.Stopped:Connect(function()
		if trackedChests[chestModel] ~= state or state.openSequence ~= sequence then
			return
		end

		playOpenedLoop(chestModel, state)
	end)
	openingTrack:Play(0)
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

	if not isOpened then
		if state.isOpenVisual then
			stopChestAnimations(state)
		end
	elseif shouldAnimateOpen == true then
		playOpeningThenOpenedLoop(chestModel, state)
	elseif not state.isOpenVisual then
		playOpenedLoop(chestModel, state)
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
		openingTrack = nil,
		openedTrack = nil,
		finishConnection = nil,
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
		if state ~= nil then
			destroyChestState(state)
		end
		trackedChests[chestModel] = nil
	end)
end

for _, chestInstance in ipairs(CollectionService:GetTagged("MineRewardChest")) do
	trackChest(chestInstance)
end

CollectionService:GetInstanceAddedSignal("MineRewardChest"):Connect(trackChest)
CollectionService:GetInstanceRemovedSignal("MineRewardChest"):Connect(function(instance)
	local state = trackedChests[instance]
	if state ~= nil then
		destroyChestState(state)
	end
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
