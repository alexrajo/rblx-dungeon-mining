local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local SelectablePanel = Roact.Component:extend("SelectablePanel")

function SelectablePanel:init()
	self:setState({
		hovering = false
	})
end

--[[
@param aspectRatio: number
@dominantAxis: Enum.DominantAxis
]]
function SelectablePanel:render()
	local function onClick()
		local externalOnClick = self.props.onSelect
		if externalOnClick ~= nil then
			externalOnClick()
		end
	end
	
	local function onHoverBegin()
		self:setState({
			hovering = true
		})
	end
	
	local function onHoverEnd()
		self:setState({
			hovering = false
		})
	end
	
	local selected = self.props.selected == true
	local hovering = self.state.hovering
	
	local props = table.clone(self.props)
	if not props.BorderColor3 then 
		props.BorderColor3 = Color3.fromRGB(27, 42, 53)
	end
	if not props.Size then
		props.Size = UDim2.fromOffset(600, 200)
	end
	props[Roact.Children] = nil
	props.Text = ""
	props.aspectRatio = nil
	props.dominantAxis = nil
	props.selected = nil
	props.onSelect = nil
	props[Roact.Event.Activated] = onClick
	props[Roact.Event.MouseEnter] = onHoverBegin
	props[Roact.Event.MouseLeave] = onHoverEnd
	
	return Roact.createElement("TextButton", props, {
		uICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),

		uIStroke = Roact.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(0, 43, 106),
		}),

		background = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			shadow = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.8,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Size = UDim2.new(1, 0, 1, 5),
			}, {
				uICorner1 = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),

			color = Roact.createElement("Frame", {
				BackgroundColor3 = hovering and Color3.fromRGB(99, 201, 255) or Color3.fromRGB(29, 177, 255),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 3,
				ClipsDescendants = true
			}, {
				uICorner2 = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
				StrokeContainer = Roact.createElement("Frame", {
					Size = UDim2.new(1, -4, 1, -4),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					BackgroundTransparency = 1,
					Visible = selected,
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Thickness = 3,
						Color = Color3.fromRGB(255, 255, 255),
					}),
					uICorner2 = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
				})
			}),
		}),

		content = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -8, 1, -8),
			ZIndex = 2,
		}, self.props[Roact.Children]),
		
		UIAspectRatioConstraint = self.props.aspectRatio ~= nil and Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = self.props.aspectRatio,
			DominantAxis = self.props.dominantAxis or Enum.DominantAxis.Width
		})
	})
end

return SelectablePanel
