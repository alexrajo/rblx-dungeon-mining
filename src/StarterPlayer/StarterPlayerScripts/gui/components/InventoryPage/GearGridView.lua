local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local ItemCounter = require(ModuleIndex.ItemCounter)
local SelectablePanel = require(ModuleIndex.SelectablePanel)
local TextLabel = require(ModuleIndex.TextLabel)

local GearGridView = Roact.Component:extend("GearGridView")

local function createGearCellContent(gearEntry)
	return createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Item = createElement(ItemCounter, {
			name = gearEntry.name,
			amount = gearEntry.amount or 1,
			Size = UDim2.fromScale(1, 1),
		}),
		Name = createElement(TextLabel, {
			Text = gearEntry.name,
			textSize = 12,
			Size = UDim2.new(1, -8, 0, 28),
			Position = UDim2.new(0.5, 0, 1, -6),
			AnchorPoint = Vector2.new(0.5, 1),
			ZIndex = 3,
			textProps = {
				TextScaled = true,
				TextWrapped = true,
			},
		}),
	})
end

function GearGridView:render()
	local itemsPerRow = self.props.itemsPerRow or 6
	local paddingPixels = 4
	local gearEntries = self.props.gearEntries or {}
	local interactive = self.props.interactive == true
	local selectedItemName = self.props.selectedItemName
	local itemElements = {}

	for _, gearEntry in ipairs(gearEntries) do
		local elementKey = gearEntry.name
		local content = createGearCellContent(gearEntry)

		if interactive then
			itemElements[elementKey] = createElement(SelectablePanel, {
				Size = UDim2.fromScale(1, 1),
				selected = selectedItemName == gearEntry.name,
				onSelect = function()
					if self.props.onItemSelected then
						self.props.onItemSelected(gearEntry.name)
					end
				end,
			}, {
				Content = content,
			})
		else
			itemElements[elementKey] = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, {
				Content = content,
			})
		end
	end

	return createElement("ScrollingFrame", {
		Size = self.props.Size or UDim2.new(1, -20, 1, 0),
		AnchorPoint = self.props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = self.props.Position or UDim2.new(0.5, 0, 0.5, 0),
		LayoutOrder = self.props.LayoutOrder,
		BackgroundTransparency = 1,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = self.props.Visible,
	}, {
		UIGridLayout = createElement("UIGridLayout", {
			CellSize = UDim2.new(1 / itemsPerRow, -math.ceil(paddingPixels * (itemsPerRow - 1) / itemsPerRow), 1, 0),
			CellPadding = UDim2.fromOffset(paddingPixels, paddingPixels),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, {
			UIAspectRatioConstraint = createElement("UIAspectRatioConstraint", {
				AspectRatio = 1,
				DominantAxis = Enum.DominantAxis.Width,
			}),
		}),
		Items = Roact.createFragment(itemElements),
	})
end

return GearGridView
