local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local APIService = require(ReplicatedStorage.services.APIService)

local RF_TrackQuest = APIService.GetFunction("TrackQuest")
local RF_UntrackQuest = APIService.GetFunction("UntrackQuest")
local RF_AbandonQuest = APIService.GetFunction("AbandonQuest")
local RF_ClaimQuestReward = APIService.GetFunction("ClaimQuestReward")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local PageWrapper = require(ModuleIndex.PageWrapper)
local Window = require(ModuleIndex.Window)
local TextButton = require(ModuleIndex.TextButton)
local TextLabel = require(ModuleIndex.TextLabel)
local Tab = require(ModuleIndex.Tab)
local ConfirmationModal = require(ModuleIndex.ConfirmationModal)
local StatsContext = require(ModuleIndex.StatsContext)
local QuestDataUtils = require(ModuleIndex.QuestDataUtils)

local QuestPage = Roact.Component:extend("QuestPage")

local TAB_ACTIVE = "Active"
local TAB_COMPLETED = "Completed"
local PINNED_IMAGE_ID = "128278194793478"
local COMPLETED_IMAGE_ID = "85395726611287"

local function getFirstQuestId(rows)
	local firstRow = rows[1]
	if firstRow == nil or firstRow.quest == nil then
		return nil
	end
	return firstRow.quest.id
end

local function findRow(rows, questId: string?)
	if questId == nil then
		return nil
	end

	for _, row in ipairs(rows) do
		if row.quest.id == questId then
			return row
		end
	end

	return nil
end

function QuestPage:init()
	self:setState({
		currentTab = TAB_ACTIVE,
		selectedQuestId = nil,
		showAbandonModal = false,
	})
end

function QuestPage:didUpdate(previousProps)
	if previousProps.currentQuestNavigationId ~= self.props.currentQuestNavigationId and self.props.currentQuestId ~= nil then
		self:setState({
			currentTab = TAB_ACTIVE,
			selectedQuestId = self.props.currentQuestId,
			showAbandonModal = false,
		})
	end
end

function QuestPage:_renderQuestList(rows, selectedQuestId: string?, isActiveTab: boolean)
	local listItems = {}

	for index, row in ipairs(rows) do
		local quest = row.quest
		local entry = row.entry
		local selected = quest.id == selectedQuestId
		local isTracked = entry ~= nil and entry.tracked == true
		local isCompletedUnclaimed = entry ~= nil and QuestDataUtils.IsCompletedUnclaimed(entry)

		listItems[quest.id] = createElement("TextButton", {
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = selected and Color3.fromRGB(0, 84, 158) or Color3.fromRGB(0, 43, 83),
			BorderSizePixel = 0,
			Size = UDim2.new(1, -6, 0, 44),
			LayoutOrder = index,
			ZIndex = 8,
			[Roact.Event.Activated] = function()
				self:setState({
					selectedQuestId = quest.id,
					showAbandonModal = false,
				})
			end,
		}, {
			UICorner = createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			UIStroke = createElement("UIStroke", {
				Color = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(78, 171, 242),
				Transparency = selected and 0 or 0.3,
			}),
			Title = createElement(TextLabel, {
				Text = quest.title,
				Size = UDim2.new(1, -66, 1, -8),
				Position = UDim2.fromOffset(10, 4),
				textSize = 16,
				ZIndex = 9,
				textProps = {
					TextXAlignment = Enum.TextXAlignment.Left,
					TextScaled = true,
					TextWrapped = true,
				},
			}),
			Pinned = isActiveTab and isTracked and createElement("ImageLabel", {
				Image = "rbxassetid://" .. PINNED_IMAGE_ID,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -34, 0.5, 0),
				Size = UDim2.fromOffset(22, 22),
				ZIndex = 10,
			}) or nil,
			Completed = isActiveTab and isCompletedUnclaimed and createElement("ImageLabel", {
				Image = "rbxassetid://" .. COMPLETED_IMAGE_ID,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(22, 22),
				ZIndex = 10,
			}) or nil,
		})
	end

	return createElement("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		UIListLayout = createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
		Items = Roact.createFragment(listItems),
	})
end

function QuestPage:_renderObjectives(statsData, quest)
	local objectiveComponents = {}
	for index, objective in ipairs(quest.objectives or {}) do
		objectiveComponents["Objective" .. tostring(index)] = createElement(TextLabel, {
			Text = QuestDataUtils.GetObjectiveText(statsData, quest, objective),
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = index,
			textSize = 15,
			textProps = {
				TextXAlignment = Enum.TextXAlignment.Left,
				TextScaled = true,
				TextWrapped = true,
			},
		})
	end

	return Roact.createFragment(objectiveComponents)
end

function QuestPage:_renderRewards(quest, highlighted: boolean)
	local rewardComponents = {}
	local rewardLines = QuestDataUtils.GetRewardLines(quest)
	for index, rewardText in ipairs(rewardLines) do
		rewardComponents["Reward" .. tostring(index)] = createElement(TextLabel, {
			Text = rewardText,
			Size = UDim2.new(1, 0, 0, 22),
			LayoutOrder = index,
			textSize = highlighted and 17 or 14,
			textProps = {
				TextXAlignment = Enum.TextXAlignment.Left,
				TextScaled = true,
				TextColor3 = highlighted and Color3.fromRGB(114, 255, 85) or Color3.fromRGB(255, 255, 255),
			},
		})
	end

	if #rewardLines == 0 then
		rewardComponents.Empty = createElement(TextLabel, {
			Text = "No reward",
			Size = UDim2.new(1, 0, 0, 22),
			textSize = 14,
			textProps = {
				TextXAlignment = Enum.TextXAlignment.Left,
			},
		})
	end

	return Roact.createFragment(rewardComponents)
end

function QuestPage:_renderDetails(statsData, row, isActiveTab: boolean)
	if row == nil then
		return createElement(TextLabel, {
			Text = "Select a quest",
			Size = UDim2.fromScale(0.8, 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			textSize = 20,
		})
	end

	local quest = row.quest
	local entry = row.entry
	local isCompletedUnclaimed = entry ~= nil and QuestDataUtils.IsCompletedUnclaimed(entry)
	local isTracked = entry ~= nil and entry.tracked == true
	local canTrack = isActiveTab and entry ~= nil and not isCompletedUnclaimed

	local actionChildren = {}
	if isCompletedUnclaimed then
		actionChildren.Claim = createElement(TextButton, {
			text = "CLAIM",
			size = "sm",
			color = "green",
			LayoutOrder = 1,
			onClick = function()
				RF_ClaimQuestReward:InvokeServer(quest.id)
				self:setState({
					showAbandonModal = false,
				})
			end,
		})
	elseif canTrack then
		actionChildren.Track = createElement(TextButton, {
			text = isTracked and "UNTRACK" or "TRACK",
			size = "sm",
			color = isTracked and "gray" or "green",
			LayoutOrder = 1,
			onClick = function()
				if isTracked then
					RF_UntrackQuest:InvokeServer(quest.id)
				else
					RF_TrackQuest:InvokeServer(quest.id)
				end
			end,
		})
		actionChildren.Abandon = createElement(TextButton, {
			text = "ABANDON",
			size = "sm",
			color = "red",
			LayoutOrder = 2,
			onClick = function()
				self:setState({
					showAbandonModal = true,
				})
			end,
		})
	end

	return createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = isCompletedUnclaimed and 0.36 or 0.5,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		UICorner = createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		Title = createElement(TextLabel, {
			Text = quest.title,
			Size = UDim2.new(1, -20, 0, 32),
			Position = UDim2.fromOffset(10, 8),
			textSize = 22,
			textProps = {
				TextXAlignment = Enum.TextXAlignment.Left,
				TextScaled = true,
				TextWrapped = true,
			},
		}),
		Description = createElement(TextLabel, {
			Text = quest.description,
			Size = UDim2.new(1, -20, 0, 70),
			Position = UDim2.fromOffset(10, 48),
			textSize = 15,
			textProps = {
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
			},
		}),
		ObjectiveTitle = createElement(TextLabel, {
			Text = "Objectives",
			Size = UDim2.new(1, -20, 0, 24),
			Position = UDim2.fromOffset(10, 128),
			textSize = 18,
			textProps = {
				TextXAlignment = Enum.TextXAlignment.Left,
			},
		}),
		Objectives = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 92),
			Position = UDim2.fromOffset(10, 154),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			Items = self:_renderObjectives(statsData, quest),
		}),
		RewardTitle = createElement(TextLabel, {
			Text = "Reward",
			Size = UDim2.new(1, -20, 0, 24),
			Position = UDim2.fromOffset(10, 254),
			textSize = isCompletedUnclaimed and 20 or 18,
			textProps = {
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = isCompletedUnclaimed and Color3.fromRGB(114, 255, 85) or Color3.fromRGB(255, 255, 255),
			},
		}),
		Rewards = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 90),
			Position = UDim2.fromOffset(10, 282),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			Items = self:_renderRewards(quest, isCompletedUnclaimed),
		}),
		ActionRow = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 44),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
			}),
			Actions = Roact.createFragment(actionChildren),
		}),
	})
end

function QuestPage:_renderContent(statsData)
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()

	local function onExit()
		closeAllPages()
	end

	local activeRows = QuestDataUtils.GetActiveRows(statsData)
	local completedRows = QuestDataUtils.GetClaimedRows(statsData)
	local currentTab = self.state.currentTab
	local rows = currentTab == TAB_ACTIVE and activeRows or completedRows
	local selectedQuestId = self.state.selectedQuestId
	if findRow(rows, selectedQuestId) == nil then
		selectedQuestId = getFirstQuestId(rows)
	end

	local selectedRow = findRow(rows, selectedQuestId)

	return createElement(PageWrapper, { isOpen = (currentPage == "QuestPage") }, {
		Tabs = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.6, 0.1),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0.15, 0),
		}, {
			UIListLayout = createElement("UIListLayout", {
				Padding = UDim.new(0, 5),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			Active = createElement(Tab, {
				text = TAB_ACTIVE,
				selected = currentTab == TAB_ACTIVE,
				LayoutOrder = 1,
				xSize = UDim.new(0.28, 0),
				onClick = function()
					self:setState({
						currentTab = TAB_ACTIVE,
						selectedQuestId = getFirstQuestId(activeRows),
						showAbandonModal = false,
					})
				end,
			}),
			Completed = createElement(Tab, {
				text = TAB_COMPLETED,
				selected = currentTab == TAB_COMPLETED,
				LayoutOrder = 2,
				xSize = UDim.new(0.28, 0),
				onClick = function()
					self:setState({
						currentTab = TAB_COMPLETED,
						selectedQuestId = getFirstQuestId(completedRows),
						showAbandonModal = false,
					})
				end,
			}),
		}),
		Window = createElement(Window, {
			title = "QUESTS",
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.68, 0.74),
			AnchorPoint = Vector2.new(0.5, 0.5),
			onExit = onExit,
		}, {
			ListSection = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.5, -12, 1, -16),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
			}, {
				Title = createElement(TextLabel, {
					Text = currentTab,
					Size = UDim2.new(1, 0, 0, 24),
					textSize = 20,
				}),
				List = createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, -30),
					Position = UDim2.fromOffset(0, 30),
				}, {
					Items = self:_renderQuestList(rows, selectedQuestId, currentTab == TAB_ACTIVE),
				}),
			}),
			DetailSection = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.5, -12, 1, -16),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
			}, {
				Details = self:_renderDetails(statsData, selectedRow, currentTab == TAB_ACTIVE),
			}),
			AbandonModal = createElement(ConfirmationModal, {
				visible = self.state.showAbandonModal,
				title = "Abandon Quest?",
				message = selectedRow and ("Abandon " .. selectedRow.quest.title .. "?") or "Abandon this quest?",
				confirmText = "ABANDON",
				cancelText = "CANCEL",
				confirmColor = "red",
				cancelColor = "gray",
				onConfirm = function()
					if selectedRow ~= nil then
						RF_AbandonQuest:InvokeServer(selectedRow.quest.id)
					end
					self:setState({
						showAbandonModal = false,
					})
				end,
				onCancel = function()
					self:setState({
						showAbandonModal = false,
					})
				end,
			}),
		}),
	})
end

function QuestPage:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(statsData)
			return self:_renderContent(statsData)
		end,
	})
end

return QuestPage
