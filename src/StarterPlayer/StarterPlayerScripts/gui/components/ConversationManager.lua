local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local showConversationStepEvent = APIService.GetEvent("ShowConversationStep")
local endConversationEvent = APIService.GetEvent("EndConversation")
local advanceConversationEvent = APIService.GetEvent("AdvanceConversation")
local selectConversationResponseEvent = APIService.GetEvent("SelectConversationResponse")
local leaveConversationEvent = APIService.GetEvent("LeaveConversation")

local createElement = Roact.createElement
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Panel = require(ModuleIndex.Panel)
local TextLabel = require(ModuleIndex.TextLabel)
local TextButton = require(ModuleIndex.TextButton)
local ScreenContext = require(ModuleIndex.ScreenContext)

local ConversationManager = Roact.Component:extend("ConversationManager")

local DESKTOP_SIZE = UDim2.fromOffset(620, 260)
local MOBILE_SIZE = UDim2.new(0.92, 0, 0, 270)
local DESKTOP_POSITION = UDim2.new(0.5, 0, 1, -118)
local MOBILE_POSITION = UDim2.new(0.5, 0, 1, -100)

local function quoteResponseText(text: string): string
	return '"' .. text .. '"'
end

function ConversationManager:init()
	self.connections = {}

	self:setState({
		active = false,
		entityName = "",
		text = "",
		responses = {},
	})
end

function ConversationManager:didMount()
	self.connections.showConversationStep = showConversationStepEvent.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end

		self:setState({
			active = true,
			entityName = tostring(payload.entityName or ""),
			text = tostring(payload.text or ""),
			responses = if type(payload.responses) == "table" then payload.responses else {},
		})
	end)

	self.connections.endConversation = endConversationEvent.OnClientEvent:Connect(function()
		self:setState({
			active = false,
			entityName = "",
			text = "",
			responses = {},
		})
	end)
end

function ConversationManager:willUnmount()
	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
end

function ConversationManager:_renderActions(responses)
	local buttons = {}
	local hasResponses = type(responses) == "table" and #responses > 0
	local buttonWidth = hasResponses and 260 or 120

	if hasResponses then
		for index, response in ipairs(responses) do
			if type(response) ~= "table" or type(response.id) ~= "string" then
				continue
			end

			buttons["Response" .. tostring(index)] = createElement(TextButton, {
				text = quoteResponseText(tostring(response.text or "")),
				size = "xs",
				color = "green",
				customSize = UDim2.fromOffset(buttonWidth, 36),
				LayoutOrder = index,
				disableHoverScaleTween = true,
				textProps = {
					TextScaled = true,
					TextWrapped = true,
				},
				onClick = function()
					selectConversationResponseEvent:FireServer(response.id)
				end,
			})
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
				advanceConversationEvent:FireServer()
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
			leaveConversationEvent:FireServer()
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
				Buttons = Roact.createFragment(self:_renderActions(responses)),
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
