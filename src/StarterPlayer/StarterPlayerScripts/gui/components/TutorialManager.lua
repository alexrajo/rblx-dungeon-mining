local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Roact = require(ReplicatedStorage.services.Roact)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local nextTutorialStepEvent = APIService.GetEvent("SendNextTutorialStep")

local createElement = Roact.createElement
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Panel = require(ModuleIndex.Panel)
local TextLabel = require(ModuleIndex.TextLabel)

local TutorialManager = Roact.Component:extend("TutorialManager")
local OPEN_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local CLOSE_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local OPEN_POSITION = UDim2.fromScale(0.5, 0.05)
local topLeft = GuiService:GetGuiInset()
local CLOSED_POSITION = UDim2.new(0.5, 0, -1, -topLeft.Y - 16)

function TutorialManager:init()
	self.panelRef = Roact.createRef()
	self.connections = {}
	self.transitionToken = 0
	self.movementTween = nil
	self.isVisible = false

	self:setState({
		currentTutorial = nil,
		currentStep = nil,
	})
end

function TutorialManager:_cancelCurrentTween()
	if self.movementTween ~= nil then
		self.movementTween:Cancel()
		self.movementTween = nil
	end
end

function TutorialManager:_playTween(targetPosition: UDim2, tweenInfo: TweenInfo): Tween?
	local panel = self.panelRef:getValue()
	if panel == nil then
		return nil
	end

	self:_cancelCurrentTween()

	local tween = TweenService:Create(panel, tweenInfo, {Position = targetPosition})
	self.movementTween = tween
	tween:Play()

	return tween
end

function TutorialManager:_hidePanel(token: number)
	if not self.isVisible then
		return true
	end

	local tween = self:_playTween(CLOSED_POSITION, CLOSE_TWEEN_INFO)
	if tween == nil then
		self.isVisible = false
		return true
	end

	tween.Completed:Wait()
	if self.transitionToken ~= token then
		return false
	end

	self.isVisible = false
	return true
end

function TutorialManager:_showPanel(token: number)
	local tween = self:_playTween(OPEN_POSITION, OPEN_TWEEN_INFO)
	if tween == nil then
		return
	end

	tween.Completed:Wait()
	if self.transitionToken ~= token then
		return
	end

	self.isVisible = true
end

function TutorialManager:_moveToStep(step, tutorialName)
	self.transitionToken += 1
	local transitionToken = self.transitionToken

	task.spawn(function()
		if not self:_hidePanel(transitionToken) then
			return
		end

		if step.completed then
			self:setState({
				currentTutorial = nil,
				currentStep = nil,
			})
			return
		end

		self:setState({
			currentTutorial = tutorialName,
			currentStep = step,
		})

		task.wait()
		if self.transitionToken ~= transitionToken then
			return
		end

		self:_showPanel(transitionToken)
	end)
end

function TutorialManager:didMount()
	local panel = self.panelRef:getValue()
	if panel == nil then
		return
	end

	panel.Position = CLOSED_POSITION

	self.connections.nextTutorialStep = nextTutorialStepEvent.OnClientEvent:Connect(function(...)
		self:_moveToStep(...)
	end)
end

function TutorialManager:render()
    local descriptionText = ""
    if self.state.currentStep ~= nil then
        descriptionText = self.state.currentStep.description
	end

	return createElement("Frame", { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 0), BackgroundTransparency = 1, ZIndex = 200 }, {
        TutorialTextBox = createElement("Frame", {
			[Roact.Ref] = self.panelRef,
			Size = UDim2.new(0.3, 0, 0.15, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = CLOSED_POSITION,
			BackgroundTransparency = 1,
		}, {
			Panel = createElement(Panel, {Size = UDim2.fromScale(1, 1)}, {
				Title = createElement(TextLabel, {Text = "Tutorial", Size = UDim2.new(1, -16, 0, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), textSize = 24}),
				-- Disable RichText so the foreground label and shadow label wrap identically for multi-line tutorial text.
				Description = createElement(TextLabel, {Text = descriptionText, Size = UDim2.new(1, -16, 1, -20), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), textSize = 16, RichText = false, textProps = {TextWrapped = true}})
			})
		})
    })
end

function TutorialManager:willUnmount()
	self.transitionToken += 1
	self:_cancelCurrentTween()

	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
end

return TutorialManager
