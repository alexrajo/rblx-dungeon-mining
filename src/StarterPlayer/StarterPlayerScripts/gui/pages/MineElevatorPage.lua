local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local APIService = require(Services.APIService)
local MineLayerConfig = require(ReplicatedStorage.configs.MineLayerConfig)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Button = require(ModuleIndex.Button)
local PageWrapper = require(ModuleIndex.PageWrapper)
local TextLabel = require(ModuleIndex.TextLabel)
local Window = require(ModuleIndex.Window)
local StatsContext = require(ModuleIndex.StatsContext)

local requestMineElevatorTravel = APIService.GetFunction("MineElevatorTravel")

local MineElevatorPage = Roact.Component:extend("MineElevatorPage")

local GRID_COLUMNS = 4
local GRID_PADDING = 8
local BUTTON_HEIGHT = 96

function MineElevatorPage:_renderFloorButton(floorNumber: number)
	local closeAllPages = self.props.closeAllPages

	return createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		AspectRatio = createElement("UIAspectRatioConstraint", {
			AspectRatio = 1,
			DominantAxis = Enum.DominantAxis.Width,
		}),
		Button = createElement(Button, {
			color = "yellow",
			customSize = UDim2.fromScale(1, 1),
			disableHoverScaleTween = true,
			onClick = function()
				closeAllPages()

				local success, response = pcall(function()
					return requestMineElevatorTravel:InvokeServer(floorNumber)
				end)

				if not success then
					warn("MineElevatorPage: Failed to request travel:", response)
				elseif type(response) == "table" and response.success ~= true then
					warn("MineElevatorPage: Travel request was rejected:", response.reason)
				end
			end,
		}, {
			Label = createElement(TextLabel, {
				Text = tostring(floorNumber),
				Size = UDim2.fromScale(1, 1),
				textSize = 28,
				ZIndex = 2,
			}),
		}),
	})
end

function MineElevatorPage:render()
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()

	local function onExit()
		closeAllPages()
	end

	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local unlockedFloors = MineLayerConfig.GetCheckpointFloorsUpTo(data.LatestCheckpointFloor)
			local gridChildren = {}

			for index, floorNumber in ipairs(unlockedFloors) do
				gridChildren["Floor_" .. floorNumber] = createElement("Frame", {
					LayoutOrder = index,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
				}, {
					Button = self:_renderFloorButton(floorNumber),
				})
			end

			return createElement(PageWrapper, { isOpen = (currentPage == "MineElevator") }, {
				Window = createElement(Window, {
					title = "Elevator",
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(0.45, 0.55),
					onExit = onExit,
				}, {
					EmptyState = (#unlockedFloors == 0) and createElement(TextLabel, {
						Text = "No checkpoints unlocked",
						Size = UDim2.fromScale(0.75, 0.18),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						textSize = 20,
					}),
					FloorGrid = (#unlockedFloors > 0) and createElement("ScrollingFrame", {
						Size = UDim2.new(1, -20, 1, -20),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarThickness = 0,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						CanvasSize = UDim2.new(),
						ScrollingDirection = Enum.ScrollingDirection.Y,
					}, {
						GridLayout = createElement("UIGridLayout", {
							CellPadding = UDim2.fromOffset(GRID_PADDING, GRID_PADDING),
							CellSize = UDim2.new(1 / GRID_COLUMNS, -math.ceil(GRID_PADDING * (GRID_COLUMNS - 1) / GRID_COLUMNS), 0, BUTTON_HEIGHT),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
						Items = Roact.createFragment(gridChildren),
					}),
				}),
			})
		end,
	})
end

return MineElevatorPage
