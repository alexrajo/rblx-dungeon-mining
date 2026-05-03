local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local SelectablePanel = require(ModuleIndex.SelectablePanel)
local TextLabel = require(ModuleIndex.TextLabel)

local SelectableItemTile = Roact.Component:extend("SelectableItemTile")

function SelectableItemTile:render()
	local itemName = self.props.itemName
	local imageId = self.props.imageId or ItemConfig.GetImageIdForItem(itemName)
	local amount = self.props.amount
	local slotNumber = self.props.slotNumber
	local showName = self.props.showName ~= false
	local showSelectionTint = self.props.showSelectionTint == true
	local selected = self.props.selected == true
	local isCompactItemCell = not showName

	return createElement(SelectablePanel, {
		selected = selected,
		Size = self.props.Size,
		Position = self.props.Position,
		AnchorPoint = self.props.AnchorPoint,
		LayoutOrder = self.props.LayoutOrder,
		Visible = self.props.Visible,
		aspectRatio = self.props.aspectRatio,
		dominantAxis = self.props.dominantAxis,
		onSelect = self.props.onSelect,
	}, {
		SlotNumber = slotNumber ~= nil and createElement(TextLabel, {
			Text = tostring(slotNumber),
			textSize = 14,
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.new(0, 10, 0, 10),
			AnchorPoint = Vector2.zero,
			ZIndex = 3,
			textProps = {
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
		}) or nil,
		Icon = createElement("ImageLabel", {
			Image = "rbxassetid://" .. imageId,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = self.props.iconPosition or (isCompactItemCell and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.45)),
			Size = self.props.iconSize or (isCompactItemCell and UDim2.new(0.75, 0, 0.75, 0) or UDim2.fromScale(0.58, 0.58)),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 1,
		}, isCompactItemCell and {
			UISizeConstraint = createElement("UISizeConstraint", {
				MaxSize = Vector2.new(64, 64),
			}),
		} or nil),
		Amount = amount ~= nil and createElement("Frame", {
			BackgroundColor3 = isCompactItemCell and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 43, 106),
			BackgroundTransparency = isCompactItemCell and 1 or 0,
			AnchorPoint = Vector2.new(1, 1),
			Position = isCompactItemCell and UDim2.fromScale(0.95, 0.95) or UDim2.new(1, -8, 1, -8),
			Size = isCompactItemCell and UDim2.fromScale(0.9, 0.2) or UDim2.fromOffset(24, 18),
			ZIndex = 5,
		}, {
			UICorner = not isCompactItemCell and createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}) or nil,
			Text = createElement(TextLabel, {
				Text = tostring(amount),
				textSize = 11,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 6,
				textProps = {
					TextScaled = true,
					TextXAlignment = isCompactItemCell and Enum.TextXAlignment.Right or Enum.TextXAlignment.Center,
				},
			}),
		}) or nil,
		Name = showName and itemName ~= nil and itemName ~= "" and createElement(TextLabel, {
			Text = itemName,
			textSize = 12,
			Size = self.props.nameSize or UDim2.new(1, -8, 0, 28),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = self.props.namePosition or UDim2.new(0.5, 0, 1, -6),
			ZIndex = 3,
			textProps = {
				TextScaled = true,
				TextWrapped = true,
			},
		}) or nil,
		SelectionTint = showSelectionTint and selected and createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.85,
			Size = UDim2.new(1, -8, 1, -8),
			Position = UDim2.fromOffset(4, 4),
			ZIndex = 4,
		}, {
			UICorner = createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
		}) or nil,
	})
end

return SelectableItemTile
