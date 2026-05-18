local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local StoryUtils = require(script.Parent.StoryUtils)
local OldMinerIntro = require(ReplicatedStorage.configs.ConversationConfig.OldMinerIntro)
local LostBook = require(ReplicatedStorage.configs.ConversationConfig.LostBook)

local ConversationManager = require(ModuleIndex.ConversationManager)
local TextButton = require(ModuleIndex.TextButton)
local TextLabel = require(ModuleIndex.TextLabel)

local createElement = Roact.createElement

local function getStep(conversation, stepId: string)
	for _, step in ipairs(conversation.steps) do
		if step.id == stepId then
			return step
		end
	end
end

local greetingStep = getStep(OldMinerIntro, "greeting")
local offerStep = getStep(OldMinerIntro, "offer")
local bookStep = getStep(LostBook, "page_1")

local scenarios = {
	{
		name = "Desktop line",
		device = "computer",
		size = "lg",
		conversation = {
			active = true,
			entityName = "Old Miner",
			text = greetingStep.text,
			responses = {},
		},
	},
	{
		name = "Desktop choices",
		device = "computer",
		size = "lg",
		conversation = {
			active = true,
			entityName = "Old Miner",
			text = offerStep.text,
			responses = offerStep.responses,
		},
	},
	{
		name = "Mobile choices",
		device = "mobile",
		size = "sm",
		conversation = {
			active = true,
			entityName = "Old Miner",
			text = offerStep.text,
			responses = offerStep.responses,
		},
	},
	{
		name = "Readable",
		device = "computer",
		size = "lg",
		conversation = {
			active = true,
			entityName = "Lost Book",
			text = bookStep.text,
			responses = {},
		},
	},
}

local ConversationStory = Roact.Component:extend("ConversationStory")

function ConversationStory:init()
	self:setState({
		scenarioIndex = 1,
	})
end

function ConversationStory:renderScenarioButton(scenario, index: number)
	local isSelected = self.state.scenarioIndex == index

	return createElement(TextButton, {
		text = scenario.name,
		size = "xs",
		color = if isSelected then "green" else "gray",
		customSize = UDim2.fromOffset(150, 32),
		LayoutOrder = index,
		disableHoverScaleTween = true,
		onClick = function()
			self:setState({
				scenarioIndex = index,
			})
		end,
		textProps = {
			TextScaled = true,
		},
	})
end

function ConversationStory:render()
	local scenario = scenarios[self.state.scenarioIndex]
	local buttons = {}

	for index, buttonScenario in ipairs(scenarios) do
		buttons["Scenario" .. tostring(index)] = self:renderScenarioButton(buttonScenario, index)
	end

	local element = createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(9, 18, 29),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		Backdrop = createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(17, 34, 45),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 1,
		}, {
			Grid = createElement("UIGridLayout", {
				CellPadding = UDim2.fromOffset(2, 2),
				CellSize = UDim2.fromOffset(96, 96),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),
		Header = createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(24, 20),
			Size = UDim2.new(1, -48, 0, 84),
			ZIndex = 20,
		}, {
			Title = createElement(TextLabel, {
				Text = "Conversation",
				Size = UDim2.new(1, 0, 0, 28),
				textSize = 24,
				ZIndex = 21,
				textProps = {
					TextXAlignment = Enum.TextXAlignment.Left,
				},
			}),
			ScenarioButtons = createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 42),
				Size = UDim2.new(1, 0, 0, 34),
				ZIndex = 21,
			}, {
				Layout = createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				}),
				Buttons = Roact.createFragment(buttons),
			}),
		}),
		ConversationManager = createElement(ConversationManager, {
			disableRemoteEvents = true,
			initialConversation = scenario.conversation,
			onAdvanceConversation = StoryUtils.noop,
			onSelectConversationResponse = StoryUtils.noop,
			onLeaveConversation = StoryUtils.noop,
		}),
	})

	return StoryUtils.withMockContexts(element, {
		screen = {
			Device = scenario.device,
			Size = scenario.size,
		},
	})
end

function story(target: Frame)
	return StoryUtils.mount(target, createElement(ConversationStory))
end

return story
