local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local createElement = Roact.createElement
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Panel = require(ModuleIndex.Panel)
local TextLabel = require(ModuleIndex.TextLabel)
local TextButton = require(ModuleIndex.TextButton)
local ScreenContext = require(ModuleIndex.ScreenContext)
local ConversationActionButton = require(ModuleIndex.ConversationActionButton)

local ConversationManager = Roact.Component:extend("ConversationManager")

local DESKTOP_SIZE = UDim2.fromOffset(620, 260)
local MOBILE_SIZE = UDim2.new(0.92, 0, 0, 270)
local DESKTOP_POSITION = UDim2.new(0.5, 0, 1, -118)
local MOBILE_POSITION = UDim2.new(0.5, 0, 1, -100)

local function normalizeConversationPayload(payload)
	if type(payload) ~= "table" then
		return {
			active = false,
			entityName = "",
			text = "",
			responses = {},
		}
	end

	return {
		active = if payload.active == nil then true else payload.active == true,
		entityName = tostring(payload.entityName or ""),
		text = tostring(payload.text or ""),
		responses = if type(payload.responses) == "table" then payload.responses else {},
	}
end

function ConversationManager:init()
	self.connections = {}
	self.remoteEvents = {}

	self:setState(normalizeConversationPayload(self.props.initialConversation))
end

function ConversationManager:didMount()
	if self.props.disableRemoteEvents then
		return
	end

	self.remoteEvents.showConversationStep = APIService.GetEvent("ShowConversationStep")
	self.remoteEvents.endConversation = APIService.GetEvent("EndConversation")
	self.remoteEvents.advanceConversation = APIService.GetEvent("AdvanceConversation")
	self.remoteEvents.selectConversationResponse = APIService.GetEvent("SelectConversationResponse")
	self.remoteEvents.leaveConversation = APIService.GetEvent("LeaveConversation")

	self.connections.showConversationStep = self.remoteEvents.showConversationStep.OnClientEvent:Connect(function(payload)
		self:setState(normalizeConversationPayload(payload))
	end)

	self.connections.endConversation = self.remoteEvents.endConversation.OnClientEvent:Connect(function()
		self:setState({
			active = false,
			entityName = "",
			text = "",
			responses = {},
		})
	end)
end

function ConversationManager:didUpdate(previousProps)
	if previousProps.initialConversation ~= self.props.initialConversation then
		self:setState(normalizeConversationPayload(self.props.initialConversation))
	end
end

function ConversationManager:willUnmount()
	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
end

function ConversationManager:_advanceConversation()
	if self.props.onAdvanceConversation then
		self.props.onAdvanceConversation()
	elseif self.remoteEvents.advanceConversation then
		self.remoteEvents.advanceConversation:FireServer()
	end
end

function ConversationManager:_selectConversationResponse(responseId: string)
	if self.props.onSelectConversationResponse then
		self.props.onSelectConversationResponse(responseId)
	elseif self.remoteEvents.selectConversationResponse then
		self.remoteEvents.selectConversationResponse:FireServer(responseId)
	end
end

function ConversationManager:_leaveConversation()
	if self.props.onLeaveConversation then
		self.props.onLeaveConversation()
	elseif self.remoteEvents.leaveConversation then
		self.remoteEvents.leaveConversation:FireServer()
	end
end

function ConversationManager:_renderActionButton(text: string, onClick, layoutOrder: number, isMobile: boolean)
	return createElement(ConversationActionButton, {
		text = text,
		LayoutOrder = layoutOrder,
		isMobile = isMobile,
		onClick = onClick,
	})
end

function ConversationManager:_renderActions(responses, isMobile: boolean)
	local buttons = {}
	local hasResponses = type(responses) == "table" and #responses > 0
	local buttonWidth = hasResponses and 260 or 120

	if hasResponses then
		for responseIndex, response in ipairs(responses) do
			if type(response) ~= "table" or type(response.id) ~= "string" then
				continue
			end

			buttons["Response" .. tostring(responseIndex)] = self:_renderActionButton(tostring(response.text or ""), function()
				self:_selectConversationResponse(response.id)
			end, responseIndex, isMobile)
		end
	else
		buttons.Next = createElement(TextButton, {
			text = "Next",
			size = "xs",
			color = "green",
			customSize = UDim2.fromOffset(buttonWidth, 30),
			LayoutOrder = 1,
			disableHoverScaleTween = true,
			onClick = function()
				self:_advanceConversation()
			end,
		})
	end

	buttons.Leave = createElement(TextButton, {
		text = "Leave",
		size = "xs",
		color = "gray",
		customSize = UDim2.fromOffset(buttonWidth, 30),
		LayoutOrder = 999,
		disableHoverScaleTween = true,
		onClick = function()
			self:_leaveConversation()
		end,
	})

	return buttons
end

function ConversationManager:_renderPanel(screenData)
	if not self.state.active then
		return nil
	end

	local isMobile = screenData.Device == "mobile"
	local responses = self.state.responses or {}
	local hasResponses = #responses > 0
	local actionHeight = if hasResponses then math.min(148, (#responses + 1) * 42) else 36

	return createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = isMobile and MOBILE_POSITION or DESKTOP_POSITION,
		Size = isMobile and MOBILE_SIZE or DESKTOP_SIZE,
		BackgroundTransparency = 1,
		ZIndex = 220,
	}, {
		Panel = createElement(Panel, {
			Size = UDim2.fromScale(1, 1),
			ZIndex = 220,
		}, {
			EntityName = createElement(TextLabel, {
				Text = self.state.entityName,
				Size = UDim2.new(1, -20, 0, 30),
				Position = UDim2.new(0.5, 0, 0, 6),
				AnchorPoint = Vector2.new(0.5, 0),
				textSize = 24,
				ZIndex = 225,
				textProps = {
					TextScaled = true,
					TextWrapped = true,
				},
			}),
			Message = createElement(TextLabel, {
				Text = self.state.text,
				Size = UDim2.new(1, -24, 1, -(actionHeight + 58)),
				Position = UDim2.new(0.5, 0, 0, 42),
				AnchorPoint = Vector2.new(0.5, 0),
				textSize = 18,
				RichText = false,
				ZIndex = 225,
				textProps = {
					TextWrapped = true,
					TextYAlignment = Enum.TextYAlignment.Top,
				},
			}),
			Actions = createElement("Frame", {
				Size = UDim2.new(1, -24, 0, actionHeight),
				Position = UDim2.new(0.5, 0, 1, -8),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				ZIndex = 225,
			}, {
				UIListLayout = createElement("UIListLayout", {
					FillDirection = if #responses > 0 then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}),
				Buttons = Roact.createFragment(self:_renderActions(responses, isMobile)),
			}),
		}),
	})
end

function ConversationManager:render()
	return createElement(ScreenContext.context.Consumer, {
		render = function(screenData)
			return self:_renderPanel(screenData)
		end,
	})
end

return ConversationManager
