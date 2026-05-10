local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local DragSelect = {}
local DragContext = Roact.createContext(nil)

local DRAG_THRESHOLD = 8
local PULSE_SPEED = 2.2
local PULSE_MIN_TRANSPARENCY = 0.18
local PULSE_MAX_TRANSPARENCY = 0.58
local PREVIEW_SIZE = UDim2.fromOffset(84, 84)

local Manager = Roact.Component:extend("DragSelectManager")
local Source = Roact.Component:extend("DragSelectSource")
local Target = Roact.Component:extend("DragSelectTarget")

local function getInputPosition(inputObject: InputObject?): Vector2
	if inputObject ~= nil and inputObject.Position ~= nil then
		return Vector2.new(inputObject.Position.X, inputObject.Position.Y)
	end

	return UserInputService:GetMouseLocation()
end

local function isDragInput(inputObject: InputObject): boolean
	return inputObject.UserInputType == Enum.UserInputType.MouseButton1
		or inputObject.UserInputType == Enum.UserInputType.Touch
end

local function isPointInside(point: Vector2, guiObject: GuiObject): boolean
	local position = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize

	return point.X >= position.X
		and point.X <= position.X + size.X
		and point.Y >= position.Y
		and point.Y <= position.Y + size.Y
end

function Manager:init()
	self.rootRef = Roact.createRef()
	self.targets = {}

	self:setState({
		activePayload = nil,
		hoveredTargetId = nil,
		pointerPosition = Vector2.zero,
		pulsePhase = 0,
	})
end

function Manager:_findHoveredTargetId(pointerPosition: Vector2, activePayload)
	local hoveredTargetId = nil

	if activePayload ~= nil then
		for targetId, targetInfo in pairs(self.targets) do
			local targetInstance = targetInfo.ref and targetInfo.ref:getValue()
			local canDrop = targetInfo.canDrop

			if targetInstance ~= nil and (canDrop == nil or canDrop(activePayload)) and isPointInside(pointerPosition, targetInstance) then
				hoveredTargetId = targetId
				break
			end
		end
	end

	return hoveredTargetId
end

function Manager:_setPointerPosition(pointerPosition: Vector2, activePayload)
	local hoveredTargetId = self:_findHoveredTargetId(pointerPosition, activePayload or self.state.activePayload)

	self:setState({
		pointerPosition = pointerPosition,
		hoveredTargetId = hoveredTargetId or Roact.None,
	})
end

function Manager:_startPulse()
	if self.pulseConnection ~= nil then
		return
	end

	self.pulseConnection = RunService.RenderStepped:Connect(function()
		if self.state.activePayload == nil then
			return
		end

		local pulsePhase = (math.sin(os.clock() * math.pi * PULSE_SPEED) + 1) / 2
		self:setState({
			pulsePhase = pulsePhase,
		})
	end)
end

function Manager:_stopPulse()
	if self.pulseConnection ~= nil then
		self.pulseConnection:Disconnect()
		self.pulseConnection = nil
	end
end

function Manager:startDrag(payload, pointerPosition: Vector2, renderPreview)
	local hoveredTargetId = self:_findHoveredTargetId(pointerPosition, payload)

	self:setState({
		activePayload = payload,
		renderPreview = renderPreview,
		pointerPosition = pointerPosition,
		hoveredTargetId = hoveredTargetId or Roact.None,
		pulsePhase = 0,
	})

	self:_startPulse()
end

function Manager:updatePointer(pointerPosition: Vector2)
	if self.state.activePayload == nil then
		return
	end

	self:_setPointerPosition(pointerPosition)
end

function Manager:finishDrag(pointerPosition: Vector2)
	local activePayload = self.state.activePayload
	if activePayload == nil then
		return
	end

	local hoveredTargetId = self:_findHoveredTargetId(pointerPosition, activePayload)

	if hoveredTargetId ~= nil then
		local targetInfo = self.targets[hoveredTargetId]
		if targetInfo ~= nil and targetInfo.onDrop ~= nil then
			targetInfo.onDrop(activePayload)
		end
	end

	self:_stopPulse()
	self:setState({
		activePayload = Roact.None,
		renderPreview = Roact.None,
		hoveredTargetId = Roact.None,
	})
end

function Manager:cancelDrag()
	self:_stopPulse()
	self:setState({
		activePayload = Roact.None,
		renderPreview = Roact.None,
		hoveredTargetId = Roact.None,
	})
end

function Manager:registerTarget(targetId: string, targetInfo)
	self.targets[targetId] = targetInfo

	return function()
		self.targets[targetId] = nil
	end
end

function Manager:updateTarget(targetId: string, targetInfo)
	self.targets[targetId] = targetInfo
end

function Manager:willUnmount()
	self:_stopPulse()
end

function Manager:renderPreview()
	local activePayload = self.state.activePayload
	local renderPreview = self.state.renderPreview
	if activePayload == nil or renderPreview == nil then
		return nil
	end

	local root = self.rootRef:getValue()
	local pointerPosition = self.state.pointerPosition
	local localPosition = pointerPosition
	if root ~= nil then
		localPosition = pointerPosition - root.AbsolutePosition
	end

	return createElement("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(localPosition.X, localPosition.Y),
		Size = self.props.previewSize or PREVIEW_SIZE,
		ZIndex = self.props.previewZIndex or 1000,
	}, {
		Content = renderPreview(activePayload),
	})
end

function Manager:render()
	local contextValue = {
		activePayload = self.state.activePayload,
		hoveredTargetId = self.state.hoveredTargetId,
		pulsePhase = self.state.pulsePhase,
		startDrag = function(payload, pointerPosition, renderPreview)
			self:startDrag(payload, pointerPosition, renderPreview)
		end,
		updatePointer = function(pointerPosition)
			self:updatePointer(pointerPosition)
		end,
		finishDrag = function(pointerPosition)
			self:finishDrag(pointerPosition)
		end,
		cancelDrag = function()
			self:cancelDrag()
		end,
		registerTarget = function(targetId, targetInfo)
			return self:registerTarget(targetId, targetInfo)
		end,
		updateTarget = function(targetId, targetInfo)
			self:updateTarget(targetId, targetInfo)
		end,
	}

	return createElement(DragContext.Provider, {
		value = contextValue,
	}, {
		Root = createElement("Frame", {
			BackgroundTransparency = self.props.BackgroundTransparency or 1,
			BackgroundColor3 = self.props.BackgroundColor3,
			Size = self.props.Size or UDim2.fromScale(1, 1),
			Position = self.props.Position,
			AnchorPoint = self.props.AnchorPoint,
			LayoutOrder = self.props.LayoutOrder,
			Visible = self.props.Visible,
			ZIndex = self.props.ZIndex,
			ClipsDescendants = self.props.ClipsDescendants,
			[Roact.Ref] = self.rootRef,
		}, {
			Content = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = self.props.ZIndex,
			}, self.props[Roact.Children]),
			Preview = self:renderPreview(),
		}),
	})
end

function Source:init()
	self.inputChangedConnection = nil
	self.inputEndedConnection = nil
	self.candidate = nil
end

function Source:disconnectInput()
	if self.inputChangedConnection ~= nil then
		self.inputChangedConnection:Disconnect()
		self.inputChangedConnection = nil
	end
	if self.inputEndedConnection ~= nil then
		self.inputEndedConnection:Disconnect()
		self.inputEndedConnection = nil
	end
	self.candidate = nil
end

function Source:startCandidate(context, inputObject: InputObject)
	self:disconnectInput()

	self.candidate = {
		startPosition = getInputPosition(inputObject),
		hasStartedDrag = false,
		context = context,
	}

	self.inputChangedConnection = UserInputService.InputChanged:Connect(function(changedInput: InputObject)
		if self.candidate == nil then
			return
		end

		local userInputType = changedInput.UserInputType
		if userInputType ~= Enum.UserInputType.MouseMovement and userInputType ~= Enum.UserInputType.Touch then
			return
		end

		local pointerPosition = getInputPosition(changedInput)
		local movement = pointerPosition - self.candidate.startPosition
		if not self.candidate.hasStartedDrag and movement.Magnitude >= (self.props.dragThreshold or DRAG_THRESHOLD) then
			self.candidate.hasStartedDrag = true
			if self.props.onDragStart ~= nil then
				self.props.onDragStart(self.props.payload)
			end
			context.startDrag(self.props.payload, pointerPosition, self.props.renderPreview)
		elseif self.candidate.hasStartedDrag then
			context.updatePointer(pointerPosition)
		end
	end)

	self.inputEndedConnection = UserInputService.InputEnded:Connect(function(endedInput: InputObject)
		if self.candidate == nil or not isDragInput(endedInput) then
			return
		end

		local pointerPosition = getInputPosition(endedInput)
		if self.candidate.hasStartedDrag then
			context.finishDrag(pointerPosition)
		elseif self.props.onClick ~= nil then
			self.props.onClick(self.props.payload)
		end

		self:disconnectInput()
	end)
end

function Source:willUnmount()
	if self.candidate ~= nil and self.candidate.hasStartedDrag and self.candidate.context ~= nil then
		self.candidate.context.cancelDrag()
	end
	self:disconnectInput()
end

function Source:renderWithContext(context)
	local children = self.props[Roact.Children]

	return createElement("Frame", {
		BackgroundTransparency = 1,
		Size = self.props.Size or UDim2.fromScale(1, 1),
		Position = self.props.Position,
		AnchorPoint = self.props.AnchorPoint,
		LayoutOrder = self.props.LayoutOrder,
		Visible = self.props.Visible,
		ZIndex = self.props.ZIndex,
	}, {
		Content = Roact.createFragment(children),
		Catcher = context ~= nil and createElement("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			ZIndex = self.props.CatcherZIndex or 50,
			[Roact.Event.InputBegan] = function(_, inputObject: InputObject)
				if isDragInput(inputObject) then
					self:startCandidate(context, inputObject)
				end
			end,
		}) or nil,
	})
end

function Source:render()
	return createElement(DragContext.Consumer, {
		render = function(context)
			return self:renderWithContext(context)
		end,
	})
end

function Target:init()
	self.targetRef = Roact.createRef()
	self.targetId = self.props.targetId or tostring(self)
end

function Target:getTargetInfo()
	return {
		ref = self.targetRef,
		canDrop = self.props.canDrop,
		onDrop = self.props.onDrop,
	}
end

function Target:didMount()
	if self.contextValue ~= nil then
		self.unregisterTarget = self.contextValue.registerTarget(self.targetId, self:getTargetInfo())
	end
end

function Target:didUpdate()
	if self.contextValue ~= nil then
		if self.unregisterTarget == nil then
			self.unregisterTarget = self.contextValue.registerTarget(self.targetId, self:getTargetInfo())
		else
			self.contextValue.updateTarget(self.targetId, self:getTargetInfo())
		end
	end
end

function Target:willUnmount()
	if self.unregisterTarget ~= nil then
		self.unregisterTarget()
		self.unregisterTarget = nil
	end
end

function Target:renderOutline(context)
	if context == nil or context.activePayload == nil or self.props.canDrop == nil or not self.props.canDrop(context.activePayload) then
		return nil
	end

	local isHovered = context.hoveredTargetId == self.targetId
	local pulsePhase = context.pulsePhase or 0
	local outwardInset = isHovered and 8 or (2 + pulsePhase * 4)
	local transparency = isHovered and 0 or (PULSE_MAX_TRANSPARENCY - (PULSE_MAX_TRANSPARENCY - PULSE_MIN_TRANSPARENCY) * pulsePhase)
	local thickness = isHovered and 3 or (2 + pulsePhase * 1.5)

	return createElement("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(-outwardInset, -outwardInset),
		Size = UDim2.new(1, outwardInset * 2, 1, outwardInset * 2),
		ZIndex = self.props.outlineZIndex or 200,
	}, {
		Corner = createElement("UICorner", {
			CornerRadius = self.props.outlineCornerRadius or UDim.new(0, 10),
		}),
		Stroke = createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.new(1, 1, 1),
			Thickness = thickness,
			Transparency = transparency,
		}),
	})
end

function Target:renderWithContext(context)
	self.contextValue = context

	return createElement("Frame", {
		BackgroundTransparency = 1,
		Size = self.props.Size or UDim2.fromScale(1, 1),
		Position = self.props.Position,
		AnchorPoint = self.props.AnchorPoint,
		LayoutOrder = self.props.LayoutOrder,
		Visible = self.props.Visible,
		ZIndex = self.props.ZIndex,
		[Roact.Ref] = self.targetRef,
	}, {
		Content = Roact.createFragment(self.props[Roact.Children]),
		Outline = self:renderOutline(context),
	})
end

function Target:render()
	return createElement(DragContext.Consumer, {
		render = function(context)
			return self:renderWithContext(context)
		end,
	})
end

DragSelect.Manager = Manager
DragSelect.Source = Source
DragSelect.Target = Target

return DragSelect
