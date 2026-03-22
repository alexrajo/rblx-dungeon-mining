local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local TextLabel = require(ModuleIndex.TextLabel)

local Tab = Roact.Component:extend("Tab")

--[[
	@param text
	@param selected
	@param LayoutOrder?
	@param onClick
	@param xSize?
]]
function Tab:render()
	local selected = self.props.selected == true
	local text = self.props.text or ""
	
	local function onClick()
		local externalOnClick = self.props.onClick
		if externalOnClick ~= nil then
			externalOnClick()
		end
	end
	
	return createElement("Frame", {
		BackgroundColor3 = selected and Color3.fromRGB(0, 84, 158) or Color3.fromRGB(0, 43, 83),
		BorderColor3 = Color3.fromRGB(27, 42, 53),
		Size = UDim2.new(self.props.xSize or UDim.new(0.3, 0), UDim.new(1, 0)),
		ZIndex = 5,
		LayoutOrder = self.props.LayoutOrder
	}, {
		textButton = createElement("TextButton", {
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Text = "",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
			[Roact.Event.MouseButton1Click] = onClick
		}, {
			text = createElement(TextLabel, {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
				Text = selected and text or '<font color="rgb(78, 171, 242)">'..text..'</font>',
				textSize = 20
			}),
		}),

		uICorner = createElement("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),

		uIStroke1 = createElement("UIStroke", {
			Color = Color3.fromRGB(78, 171, 242),
		}),

		bottom = createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Size = UDim2.fromScale(1, 1),
		}, {
			edge = createElement("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = selected and Color3.fromRGB(0, 84, 158) or Color3.fromRGB(0, 43, 83),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 12),
			}, {
				uIStroke2 = createElement("UIStroke", {
					Color = Color3.fromRGB(78, 171, 242),
				}),
			}),

			unstroke = createElement("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = selected and Color3.fromRGB(0, 84, 158) or Color3.fromRGB(0, 43, 83),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 14),
				ZIndex = 2,
			}),
		})
	})
end

return Tab