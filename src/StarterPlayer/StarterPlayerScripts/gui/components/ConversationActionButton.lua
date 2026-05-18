local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local TextLabel = require(ModuleIndex.TextLabel)

local ConversationActionButton = Roact.Component:extend("ConversationActionButton")

local NORMAL_BACKGROUND_TRANSPARENCY = 0.6
local HIGHLIGHTED_BACKGROUND_TRANSPARENCY = 0.35
local NORMAL_TEXT_SCALE = 1
local HIGHLIGHTED_TEXT_SCALE = 1.08
local HOVER_IN_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local HOVER_OUT_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

function ConversationActionButton:init()
	self.buttonRef = Roact.createRef()
	self.textScaleRef = Roact.createRef()
	self.hoverTweens = {}

	self:setState({
		hovering = false,
		selected = false,
	})
end

function ConversationActionButton:shouldUpdate(nextProps)
	return nextProps.text ~= self.props.text
		or nextProps.LayoutOrder ~= self.props.LayoutOrder
		or nextProps.ZIndex ~= self.props.ZIndex
		or nextProps.isMobile ~= self.props.isMobile
		or nextProps.onClick ~= self.props.onClick
end

function ConversationActionButton:didUpdate()
	self:_tweenHighlight(self.state.hovering or self.state.selected)
end

function ConversationActionButton:willUnmount()
	for _, tween in pairs(self.hoverTweens) do
		tween:Cancel()
	end
end

function ConversationActionButton:_tweenHighlight(isHighlighted: boolean)
	for _, tween in pairs(self.hoverTweens) do
		tween:Cancel()
	end

	self.hoverTweens = {}

	local tweenInfo = if isHighlighted then HOVER_IN_TWEEN_INFO else HOVER_OUT_TWEEN_INFO
	local button = self.buttonRef:getValue()
	if button ~= nil then
		local tween = TweenService:Create(button, tweenInfo, {
			BackgroundTransparency = if isHighlighted then HIGHLIGHTED_BACKGROUND_TRANSPARENCY else NORMAL_BACKGROUND_TRANSPARENCY,
		})
		table.insert(self.hoverTweens, tween)
		tween:Play()
	end

	local textScale = self.textScaleRef:getValue()
	if textScale ~= nil then
		local shouldScaleText = isHighlighted and self.props.isMobile ~= true
		local tween = TweenService:Create(textScale, tweenInfo, {
			Scale = if shouldScaleText then HIGHLIGHTED_TEXT_SCALE else NORMAL_TEXT_SCALE,
		})
		table.insert(self.hoverTweens, tween)
		tween:Play()
	end
end

function ConversationActionButton:_setHovering(hovering: boolean)
	local isHighlighted = hovering or self.state.selected

	self:setState({
		hovering = hovering,
	})
	self:_tweenHighlight(isHighlighted)
end

function ConversationActionButton:_setSelected(selected: boolean)
	local isHighlighted = self.state.hovering or selected

	self:setState({
		selected = selected,
	})
	self:_tweenHighlight(isHighlighted)
end

function ConversationActionButton:render()
	local responseText = tostring(self.props.text or "")

	return createElement("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = NORMAL_BACKGROUND_TRANSPARENCY,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Selectable = true,
		Text = "",
		LayoutOrder = self.props.LayoutOrder,
		ZIndex = self.props.ZIndex or 226,
		[Roact.Ref] = self.buttonRef,
		[Roact.Event.Activated] = self.props.onClick,
		[Roact.Event.MouseEnter] = function()
			self:_setHovering(true)
		end,
		[Roact.Event.MouseLeave] = function()
			self:_setHovering(false)
		end,
		[Roact.Event.SelectionGained] = function()
			self:_setSelected(true)
		end,
		[Roact.Event.SelectionLost] = function()
			self:_setSelected(false)
		end,
	}, {
		LabelContainer = createElement("Frame", {
			Size = UDim2.new(1, -18, 1, 0),
			Position = UDim2.new(0, 12, 0, 0),
			BackgroundTransparency = 1,
			ZIndex = self.props.ZIndex or 227,
		}, {
			TextScale = createElement("UIScale", {
				Scale = NORMAL_TEXT_SCALE,
				[Roact.Ref] = self.textScaleRef,
			}),
			Label = createElement(TextLabel, {
				Text = "> " .. responseText,
				Size = UDim2.fromScale(1, 1),
				textSize = 18,
				ZIndex = self.props.ZIndex or 227,
				RichText = false,
				textProps = {
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
				},
			}),
		}),
	})
end

return ConversationActionButton
