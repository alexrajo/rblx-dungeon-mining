local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local Clickable = Roact.Component:extend("Clickable")

function Clickable:init()
	self.state = {
		hovering = false,
	}
end

--[[
	@param onClick
]]
function Clickable:render()
	local function onClick()
		local externalOnClick = self.props.onClick
		if externalOnClick ~= nil then
			externalOnClick()
		end
	end
	
	local function onHoverBegin()
		self:setState({
			hovering = true,
		})
	end
	
	local function onHoverEnd()
		self:setState({
			hovering = false,
		})
	end
	
	return createElement("TextButton", {
		Text = "",
		[Roact.Event.MouseButton1Click] = onClick,
		[Roact.Event.MouseEnter] = onHoverBegin,
		[Roact.Event.MouseLeave] = onHoverEnd,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = self.state.hovering and 0.8 or 1
	})
end

return Clickable