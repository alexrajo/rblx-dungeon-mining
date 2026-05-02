local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local APIService = require(Services.APIService)
local configs = ReplicatedStorage.configs
local MineLayerConfig = require(configs.MineLayerConfig)
local MineRewardFloorConfig = require(configs.MineRewardFloorConfig)

local createElement = Roact.createElement

local startTransitionEvent = APIService.GetEvent("StartMineTransition")
local completeTransitionFunction = APIService.GetFunction("CompleteMineTransition")
local readyTransitionEvent = APIService.GetEvent("MineTransitionReady")
local finishTransitionEvent = APIService.GetEvent("FinishMineTransition")

local FADE_DURATION = 0.12
local BLACKOUT_HOLD_DURATION = 0.04
local FLOOR_READY_WAIT_TIMEOUT = 4
local FADE_TWEEN_INFO = TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local MineTransitionOverlay = Roact.Component:extend("MineTransitionOverlay")

local function isBossFloor(floorNumber: number): boolean
	local layerNumber = MineLayerConfig.GetLayerForFloor(floorNumber)
	local layerData = if layerNumber ~= nil then MineLayerConfig[layerNumber] else nil
	return layerData ~= nil and floorNumber == layerData.floors.max
end

local function getExpectedReadyInstance(floorNumber: number): (string, string)
	if isBossFloor(floorNumber) then
		return "BossRoom", "Floor"
	end

	if MineRewardFloorConfig.IsRewardFloor(floorNumber) then
		return "RewardRoom", "Floor"
	end

	return "Cave", "Baseplate"
end

function MineTransitionOverlay:init()
	self.coverRef = Roact.createRef()
	self.connections = {}
	self.currentTween = nil
	self.phase = "idle"

	self:setState({
		isActive = false,
	})
end

function MineTransitionOverlay:playFade(targetTransparency: number)
	local cover = self.coverRef:getValue()
	if cover == nil then
		return false
	end

	if self.currentTween ~= nil then
		self.currentTween:Cancel()
		self.currentTween = nil
	end

	local tween = TweenService:Create(cover, FADE_TWEEN_INFO, {
		BackgroundTransparency = targetTransparency,
	})
	self.currentTween = tween
	tween:Play()

	local playbackState = tween.Completed:Wait()
	if self.currentTween == tween then
		self.currentTween = nil
	end

	return playbackState == Enum.PlaybackState.Completed
end

function MineTransitionOverlay:getFloorFolder(floorNumber: number): Instance?
	return workspace:FindFirstChild("MineFloor_" .. floorNumber)
end

function MineTransitionOverlay:isMineFloorReady(floorNumber: number): boolean
	local floorFolder = self:getFloorFolder(floorNumber)
	if floorFolder == nil then
		return false
	end

	local rootName, readyInstanceName = getExpectedReadyInstance(floorNumber)
	local floorRoot = floorFolder:FindFirstChild(rootName)
	if floorRoot == nil then
		return false
	end

	return floorRoot:FindFirstChild(readyInstanceName) ~= nil
end

function MineTransitionOverlay:waitForMineFloorReady(floorNumber: number): boolean
	if self:isMineFloorReady(floorNumber) then
		return true
	end

	local bindable = Instance.new("BindableEvent")
	local resolved = false
	local connections = {}

	local function cleanup()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		bindable:Destroy()
	end

	local function resolveIfReady()
		if resolved then
			return
		end

		if self:isMineFloorReady(floorNumber) then
			resolved = true
			bindable:Fire()
		end
	end

	local function watchFloorFolder(folder: Instance)
		table.insert(connections, folder.DescendantAdded:Connect(function()
			resolveIfReady()
		end))
	end

	local existingFloorFolder = self:getFloorFolder(floorNumber)
	if existingFloorFolder ~= nil then
		watchFloorFolder(existingFloorFolder)
	end

	table.insert(connections, workspace.ChildAdded:Connect(function(child: Instance)
		if child.Name == "MineFloor_" .. floorNumber then
			watchFloorFolder(child)
			resolveIfReady()
		end
	end))

	task.delay(FLOOR_READY_WAIT_TIMEOUT, function()
		if resolved then
			return
		end

		resolved = true
		bindable:Fire()
	end)

	resolveIfReady()

	if not resolved then
		bindable.Event:Wait()
	end

	local wasReady = self:isMineFloorReady(floorNumber)
	cleanup()
	return wasReady
end

function MineTransitionOverlay:runTransition(payload)
	if self.phase ~= "idle" then
		return
	end

	if type(payload) ~= "table" then
		return
	end

	local transitionId = payload.transitionId
	if type(transitionId) ~= "string" then
		return
	end

	self.phase = "fading_in"
	self:setState({
		isActive = true,
	})

	task.defer(function()
		local cover = self.coverRef:getValue()
		if cover == nil then
			self.phase = "idle"
			self:setState({
				isActive = false,
			})
			return
		end

		cover.BackgroundTransparency = 1

		local fadeInCompleted = self:playFade(0)
		if not fadeInCompleted then
			self.phase = "idle"
			self:setState({
				isActive = false,
			})
			return
		end

		self.phase = "waiting_for_server"
		local result = completeTransitionFunction:InvokeServer(transitionId)
		if type(result) ~= "table" or result.success ~= true then
			self.phase = "fading_out"
			self:playFade(1)
			self.phase = "idle"
			self:setState({
				isActive = false,
			})
			return
		end

		if result.destinationType == "mine" and type(result.targetFloor) == "number" then
			self.phase = "waiting_for_ready"
			local isReady = self:waitForMineFloorReady(result.targetFloor)
			if isReady then
				readyTransitionEvent:FireServer(transitionId, result.targetFloor)
			end
		end

		RunService.RenderStepped:Wait()
		task.wait(BLACKOUT_HOLD_DURATION)

		self.phase = "fading_out"
		self:playFade(1)
		finishTransitionEvent:FireServer(transitionId)

		self.phase = "idle"
		self:setState({
			isActive = false,
		})
	end)
end

function MineTransitionOverlay:didMount()
	self.connections.startTransition = startTransitionEvent.OnClientEvent:Connect(function(payload)
		self:runTransition(payload)
	end)
end

function MineTransitionOverlay:willUnmount()
	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end

	if self.currentTween ~= nil then
		self.currentTween:Cancel()
		self.currentTween = nil
	end
end

function MineTransitionOverlay:render()
	return createElement("ScreenGui", {
		DisplayOrder = 999,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		Cover = createElement("Frame", {
			Active = self.state.isActive,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0),
			Selectable = false,
			Size = UDim2.fromScale(1, 1),
			Visible = self.state.isActive,
			ZIndex = 999,
			[Roact.Ref] = self.coverRef,
		}),
	})
end

return MineTransitionOverlay
