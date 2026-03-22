local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local createElement = Roact.createElement

local WelcomeStep = Roact.Component:extend("WelcomeStep")

function WelcomeStep:render()
	return createElement("TextLabel", { Text = self.props.text })
end

return WelcomeStep
