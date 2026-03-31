local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local APIService = require(Services.APIService)

local createElement = Roact.createElement

local startTransitionEvent = APIService.GetEvent("StartMineTransition")
local completeTransitionFunction = APIService.GetFunction("CompleteMineTransition")
local finishTransitionEvent = APIService.GetEvent("FinishMineTransition")

local FADE_DURATION = 0.12
local BLACKOUT_HOLD_DURATION = 0.04
local FADE_TWEEN_INFO = TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local MineTransitionOverlay = Roact.Component:extend("MineTransitionOverlay")

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
