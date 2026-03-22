local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local Panel = Roact.Component:extend("Panel")

--[[
@param aspectRatio: number
@dominantAxis: Enum.DominantAxis
]]
function Panel:render()
	local props = table.clone(self.props)
	if not props.BorderColor3 then 
		props.BorderColor3 = Color3.fromRGB(27, 42, 53)
	end
	if not props.Size then
		props.Size = UDim2.fromOffset(600, 200)
	end
	props[Roact.Children] = nil
	props.aspectRatio = nil
	props.dominantAxis = nil
	
	return Roact.createElement("Frame", props, {
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
				BackgroundColor3 = Color3.fromRGB(29, 177, 255),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 3,
			}, {
				uICorner2 = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
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

return Panel