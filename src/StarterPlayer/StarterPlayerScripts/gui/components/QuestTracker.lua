local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local PageNavigationService = require(ReplicatedStorage.local_services.PageNavigationService)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local StatsContext = require(ModuleIndex.StatsContext)
local TextLabel = require(ModuleIndex.TextLabel)
local QuestDataUtils = require(ModuleIndex.QuestDataUtils)

local QuestTracker = Roact.Component:extend("QuestTracker")

function QuestTracker:_renderTracker(statsData)
	local quest = QuestDataUtils.GetTrackedQuest(statsData)
	if quest == nil then
		return nil
	end

	local objectiveComponents = {}
	for index, objective in ipairs(quest.objectives or {}) do
		objectiveComponents["Objective" .. tostring(index)] = createElement(TextLabel, {
			Text = QuestDataUtils.GetObjectiveText(statsData, quest, objective),
			Size = UDim2.new(1, -16, 0, 20),
			LayoutOrder = index,
			textSize = 14,
			textProps = {
				TextXAlignment = Enum.TextXAlignment.Left,
				TextScaled = true,
				TextWrapped = true,
			},
		})
	end

	return createElement("TextButton", {
		Text = "",
		AutoButtonColor = true,
		Size = UDim2.fromOffset(280, 100),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 18),
		BackgroundColor3 = Color3.fromRGB(0, 43, 83),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 30,
		[Roact.Event.Activated] = function()
			PageNavigationService.OpenQuestLog(quest.id)
		end,
	}, {
		UICorner = createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		UIStroke = createElement("UIStroke", {
			Color = Color3.fromRGB(78, 171, 242),
		}),
		Title = createElement(TextLabel, {
			Text = quest.title,
			Size = UDim2.new(1, -16, 0, 28),
			Position = UDim2.fromOffset(8, 8),
			textSize = 18,
			ZIndex = 31,
			textProps = {
				TextXAlignment = Enum.TextXAlignment.Left,
				TextScaled = true,
				TextWrapped = true,
			},
		}),
		Objectives = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -16, 1, -42),
			Position = UDim2.fromOffset(8, 36),
			ZIndex = 31,
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			Items = Roact.createFragment(objectiveComponents),
		}),
	})
end

function QuestTracker:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(statsData)
			return self:_renderTracker(statsData)
		end,
	})
end

return QuestTracker
