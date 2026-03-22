local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Button = require(ModuleIndex.Button)
local TextLabel = require(ModuleIndex.TextLabel)

local TextButton = Roact.Component:extend("TextButton")


local SIZES = {
	["xs-square"] = {
		font = 16,
	},
	xs = {
		font = 16	
	},
	sm = {
		font = 25,
	},
	md = {
		font = 30,
	},
}

--[[
	@param size
	@param text
	@param color
	@param AnchorPoint
	@param Position
]]
function TextButton:render()
	local size = self.props.size

	return createElement(Button, self.props, {
		Text = createElement(TextLabel, {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, -5),
			ZIndex = 2,
			textSize = SIZES[size].font,
			Text = self.props.text
		})
	})
end

return TextButton