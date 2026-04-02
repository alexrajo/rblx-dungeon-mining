local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local Button = require(ModuleIndex.Button)
local TextLabel = require(ModuleIndex.TextLabel)

local GearDetailPopup = Roact.Component:extend("GearDetailPopup")

function GearDetailPopup:render()
	local details = self.props.details
	if details == nil then
		return nil
	end

	local zIndex = self.props.ZIndex or 20
	local detailElements = {}

	for index, lineText in ipairs(details.detailLines or {}) do
		detailElements["Line" .. tostring(index)] = createElement(TextLabel, {
			Text = lineText,
			textSize = 13,
			Size = UDim2.new(1, 0, 0, 16),
			LayoutOrder = index,
			ZIndex = zIndex + 4,
			textProps = {
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
		})
	end

	return createElement("Frame", {
		AnchorPoint = self.props.AnchorPoint or Vector2.new(0.5, 0),
		Position = self.props.Position,
		Size = self.props.Size or UDim2.fromOffset(260, 200),
		BackgroundTransparency = 1,
		ZIndex = zIndex,
	}, {
		Shadow = createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 6),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.78,
			ZIndex = zIndex,
		}, {
			UICorner = createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}),
		Body = createElement("Frame", {
			Size = UDim2.new(1, 0, 1, -6),
			BackgroundColor3 = Color3.fromRGB(16, 121, 191),
			ZIndex = zIndex + 1,
		}, {
			UICorner = createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			UIStroke = createElement("UIStroke", {
				Color = Color3.fromRGB(0, 43, 106),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Inner = createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -10, 1, -10),
				BackgroundTransparency = 1,
				ZIndex = zIndex + 2,
			}, {
				CloseButton = createElement(Button, {
					size = "xs-square",
					color = "red",
					customSize = UDim2.fromOffset(26, 26),
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					onClick = self.props.onClose,
					disableHoverScaleTween = true,
				}, {
					Text = createElement(TextLabel, {
						Text = "X",
						textSize = 14,
						Size = UDim2.fromScale(0.9, 0.9),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						ZIndex = zIndex + 5,
						textProps = {
							TextScaled = true,
						},
					}),
				}),
				Header = createElement("Frame", {
					Size = UDim2.new(1, -34, 0, 60),
					BackgroundTransparency = 1,
					ZIndex = zIndex + 2,
				}, {
					Icon = createElement("ImageLabel", {
						Image = "rbxassetid://" .. details.imageId,
						Size = UDim2.fromOffset(46, 46),
						Position = UDim2.fromOffset(0, 2),
						BackgroundTransparency = 1,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = zIndex + 3,
					}),
					Name = createElement(TextLabel, {
						Text = details.name,
						textSize = 16,
						Size = UDim2.new(1, -52, 0, 26),
						Position = UDim2.fromOffset(52, 0),
						ZIndex = zIndex + 4,
						textProps = {
							TextScaled = true,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						},
					}),
					Equipped = createElement(TextLabel, {
						Text = details.equippedText,
						textSize = 11,
						Size = UDim2.new(1, -52, 0, 16),
						Position = UDim2.fromOffset(52, 28),
						ZIndex = zIndex + 4,
						textProps = {
							TextScaled = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						},
					}),
				}),
				PrimaryStat = details.primaryStatText and createElement(TextLabel, {
					Text = details.primaryStatText,
					textSize = 14,
					Size = UDim2.new(1, 0, 0, 18),
					Position = UDim2.fromOffset(0, 62),
					ZIndex = zIndex + 4,
					textProps = {
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Left,
					},
				}) or nil,
				Stats = createElement("Frame", {
					Size = UDim2.new(1, 0, 1, -86),
					Position = UDim2.fromOffset(0, 84),
					BackgroundTransparency = 1,
					ZIndex = zIndex + 2,
				}, {
					UIListLayout = createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 2),
					}),
					Lines = Roact.createFragment(detailElements),
				}),
			}),
		}),
	})
end

return GearDetailPopup
