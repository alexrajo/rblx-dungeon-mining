local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
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
local OUTLINE_Z_INDEX = 350
local OUTLINE_PADDING = 8
local OUTLINE_COLOR = Color3.fromRGB(255, 153, 0)
local OUTLINE_BORDER_COLOR = Color3.fromRGB(0, 0, 0)
local OUTLINE_INNER_INSET = 3
local OUTLINE_PULSE_PIXELS = 4
local OUTLINE_PULSE_SPEED = 3
local topLeft = GuiService:GetGuiInset()
local CLOSED_POSITION = UDim2.new(0.5, 0, -1, -topLeft.Y - 16)
local localPlayer = Players.LocalPlayer

function TutorialManager:init()
	self.panelRef = Roact.createRef()
	self.overlayRef = Roact.createRef()
	self.connections = {}
	self.transitionToken = 0
	self.movementTween = nil
	self.isVisible = false
	self.activeOutlineTags = nil
	self.outlineConnection = nil
	self.outlineFrames = {}

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

function TutorialManager:_getPlayerGui(): PlayerGui?
	return localPlayer:FindFirstChildOfClass("PlayerGui")
end

function TutorialManager:_isOutlineTargetValid(instance: Instance): boolean
	local playerGui = self:_getPlayerGui()
	if playerGui == nil then
		return false
	end

	return instance:IsA("GuiObject") and instance.Parent ~= nil and instance:IsDescendantOf(playerGui)
end

function TutorialManager:_createOutlineFrame(target: GuiObject): Frame?
	local overlay = self.overlayRef:getValue()
	if overlay == nil then
		return nil
	end

	local outlineFrame = Instance.new("Frame")
	outlineFrame.Name = target.Name .. "_TutorialOutline"
	outlineFrame.BackgroundTransparency = 1
	outlineFrame.BorderSizePixel = 0
	outlineFrame.Active = false
	outlineFrame.ZIndex = OUTLINE_Z_INDEX
	outlineFrame.Parent = overlay

	local outerStroke = Instance.new("UIStroke")
	outerStroke.Name = "OuterStroke"
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outerStroke.Color = OUTLINE_BORDER_COLOR
	outerStroke.Thickness = 6
	outerStroke.Parent = outlineFrame

	local innerOutlineFrame = Instance.new("Frame")
	innerOutlineFrame.Name = "InnerOutline"
	innerOutlineFrame.BackgroundTransparency = 1
	innerOutlineFrame.BorderSizePixel = 0
	innerOutlineFrame.Active = false
	innerOutlineFrame.ZIndex = OUTLINE_Z_INDEX
	innerOutlineFrame.Position = UDim2.fromOffset(OUTLINE_INNER_INSET, OUTLINE_INNER_INSET)
	innerOutlineFrame.Size = UDim2.new(1, -OUTLINE_INNER_INSET * 2, 1, -OUTLINE_INNER_INSET * 2)
	innerOutlineFrame.Parent = outlineFrame

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = 3
	stroke.Parent = innerOutlineFrame

	return outlineFrame
end

function TutorialManager:_clearOutlineFrames()
	for target, outlineFrame in pairs(self.outlineFrames) do
		if outlineFrame ~= nil then
			outlineFrame:Destroy()
		end

		self.outlineFrames[target] = nil
	end
end

function TutorialManager:_collectOutlineTargets(): {[GuiObject]: true}
	local targets = {}
	local outlineTags = self.activeOutlineTags
	if type(outlineTags) ~= "table" then
		return targets
	end

	for _, tagName in ipairs(outlineTags) do
		if type(tagName) ~= "string" then
			continue
		end

		for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
			if self:_isOutlineTargetValid(instance) then
				targets[instance :: GuiObject] = true
			end
		end
	end

	return targets
end

function TutorialManager:_syncOutlineFrames()
	local overlay = self.overlayRef:getValue()
	if overlay == nil then
		return
	end

	local activeTargets = self:_collectOutlineTargets()
	local pulseOffset = math.abs(math.sin(time() * OUTLINE_PULSE_SPEED)) * OUTLINE_PULSE_PIXELS

	for target, outlineFrame in pairs(self.outlineFrames) do
		if not activeTargets[target] or not self:_isOutlineTargetValid(target) then
			outlineFrame:Destroy()
			self.outlineFrames[target] = nil
		end
	end

	for target, _ in pairs(activeTargets) do
		local outlineFrame = self.outlineFrames[target]
		if outlineFrame == nil then
			outlineFrame = self:_createOutlineFrame(target)
			if outlineFrame == nil then
				continue
			end

			self.outlineFrames[target] = outlineFrame
		end

		local absolutePosition = target.AbsolutePosition
		local absoluteSize = target.AbsoluteSize
		local totalPadding = OUTLINE_PADDING + pulseOffset

		outlineFrame.Position = UDim2.fromOffset(
			absolutePosition.X - totalPadding,
			absolutePosition.Y - totalPadding
		)
		outlineFrame.Size = UDim2.fromOffset(
			absoluteSize.X + totalPadding * 2,
			absoluteSize.Y + totalPadding * 2
		)
		outlineFrame.Visible = absoluteSize.X > 0 and absoluteSize.Y > 0
	end
end

function TutorialManager:_stopOutlineTracking()
	if self.outlineConnection ~= nil then
		self.outlineConnection:Disconnect()
		self.outlineConnection = nil
	end

	self.activeOutlineTags = nil
	self:_clearOutlineFrames()
end

function TutorialManager:_setOutlineTags(outlineTags)
	self:_stopOutlineTracking()

	if type(outlineTags) ~= "table" or #outlineTags == 0 then
		return
	end

	self.activeOutlineTags = outlineTags
	self:_syncOutlineFrames()
	self.outlineConnection = RunService.RenderStepped:Connect(function()
		self:_syncOutlineFrames()
	end)
end

function TutorialManager:_moveToStep(step, tutorialName)
	self.transitionToken += 1
	local transitionToken = self.transitionToken
	local nextOutlineTags = nil
	if not step.completed then
		nextOutlineTags = step.outlineTags
	end

	task.spawn(function()
		self:_setOutlineTags(nextOutlineTags)

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
		OutlineOverlay = createElement("Frame", {
			[Roact.Ref] = self.overlayRef,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = false,
			ZIndex = OUTLINE_Z_INDEX,
		}),
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
	self:_stopOutlineTracking()

	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
end

return TutorialManager
