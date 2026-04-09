local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Button = require(ModuleIndex.Button)
local TextLabel = require(ModuleIndex.TextLabel)
local TextButton = require(ModuleIndex.TextButton)

local COIN_ICON_ID = "11953783945"

local SellConfirmationDialog = Roact.Component:extend("SellConfirmationDialog")

--[[
	@param visible: boolean
	@param itemName: string
	@param quantity: number
	@param totalValue: number
	@param onConfirm: () -> ()
	@param onCancel: () -> ()
]]
function SellConfirmationDialog:render()
	if not self.props.visible then
		return nil
	end

	local itemName: string = self.props.itemName
	local quantity: number = self.props.quantity
	local totalValue: number = self.props.totalValue
	local onConfirm: () -> () = self.props.onConfirm
	local onCancel: () -> () = self.props.onCancel

	return createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = 50,
	}, {
		Dialog = createElement("Frame", {
			Size = UDim2.fromOffset(220, 170),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(16, 121, 191),
			BorderSizePixel = 0,
			ZIndex = 51,
		}, {
			UICorner = createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			UIStroke = createElement("UIStroke", {
				Color = Color3.fromRGB(0, 43, 106),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Shadow = createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 6),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.78,
				ZIndex = 50,
			}, {
				UICorner = createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
			Title = createElement(TextLabel, {
				Text = "Are you sure?",
				textSize = 18,
				Size = UDim2.new(1, -16, 0, 26),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 10),
				ZIndex = 52,
				textProps = {
					TextScaled = false,
					Font = Enum.Font.GothamBold,
				},
			}),
			Description = createElement(TextLabel, {
				Text = "Sell ALL " .. tostring(quantity) .. "x " .. itemName .. "?",
				textSize = 13,
				Size = UDim2.new(1, -16, 0, 36),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 44),
				ZIndex = 52,
				textProps = {
					TextScaled = false,
					TextWrapped = true,
				},
			}),
			CoinRow = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -16, 0, 22),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 86),
				ZIndex = 52,
			}, {
				UIListLayout = createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 4),
				}),
				CoinIcon = createElement("ImageLabel", {
					Image = "rbxassetid://" .. COIN_ICON_ID,
					Size = UDim2.fromOffset(18, 18),
					BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
					LayoutOrder = 1,
					ZIndex = 53,
				}),
				TotalText = createElement(TextLabel, {
					Text = tostring(totalValue),
					textSize = 14,
					Size = UDim2.fromOffset(60, 22),
					LayoutOrder = 2,
					ZIndex = 53,
					textProps = {
						Font = Enum.Font.GothamBold,
					},
				}),
			}),
			ButtonRow = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -16, 0, 36),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -10),
				ZIndex = 52,
			}, {
				UIListLayout = createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
				}),
				ConfirmButton = createElement(TextButton, {
					text = "CONFIRM",
					size = "xs",
					color = "green",
					LayoutOrder = 1,
					onClick = onConfirm,
				}),
				CancelButton = createElement(TextButton, {
					text = "CANCEL",
					size = "xs",
					color = "red",
					LayoutOrder = 2,
					onClick = onCancel,
				}),
			}),
		}),
	})
end

return SellConfirmationDialog
