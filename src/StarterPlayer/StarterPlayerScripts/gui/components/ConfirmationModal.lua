local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local TextLabel = require(ModuleIndex.TextLabel)
local TextButton = require(ModuleIndex.TextButton)

local ConfirmationModal = Roact.Component:extend("ConfirmationModal")

--[[
	@param visible: boolean
	@param title: string?
	@param message: string?
	@param confirmText: string?
	@param cancelText: string?
	@param confirmColor: string?
	@param cancelColor: string?
	@param onConfirm: () -> ()
	@param onCancel: () -> ()
]]
function ConfirmationModal:render()
	if not self.props.visible then
		return nil
	end

	local title = self.props.title or "Are you sure?"
	local message = self.props.message or "Do you want to complete this action?"
	local confirmText = self.props.confirmText or "CONFIRM"
	local cancelText = self.props.cancelText or "CANCEL"
	local confirmColor = self.props.confirmColor or "green"
	local cancelColor = self.props.cancelColor or "red"
	local onConfirm: () -> () = self.props.onConfirm
	local onCancel: () -> () = self.props.onCancel

	return createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 500,
	}, {
		Dialog = createElement("Frame", {
			Size = UDim2.fromOffset(300, 180),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(16, 121, 191),
			BorderSizePixel = 0,
			ZIndex = 501,
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
				ZIndex = 500,
			}, {
				UICorner = createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
			Title = createElement(TextLabel, {
				Text = title,
				textSize = 20,
				Size = UDim2.new(1, -20, 0, 30),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 12),
				ZIndex = 502,
				textProps = {
					TextScaled = false,
				},
			}),
			Message = createElement(TextLabel, {
				Text = message,
				textSize = 14,
				Size = UDim2.new(1, -24, 0, 58),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 52),
				ZIndex = 502,
				RichText = false,
				textProps = {
					TextScaled = false,
					TextWrapped = true,
				},
			}),
			ButtonRow = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 0, 40),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -12),
				ZIndex = 502,
			}, {
				UIListLayout = createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 10),
				}),
				ConfirmButton = createElement(TextButton, {
					text = confirmText,
					size = "xs",
					color = confirmColor,
					LayoutOrder = 1,
					onClick = onConfirm,
				}),
				CancelButton = createElement(TextButton, {
					text = cancelText,
					size = "xs",
					color = cancelColor,
					LayoutOrder = 2,
					onClick = onCancel,
				}),
			}),
		}),
	})
end

return ConfirmationModal
