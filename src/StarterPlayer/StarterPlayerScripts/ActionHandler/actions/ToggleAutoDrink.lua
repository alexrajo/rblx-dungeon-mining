local plr = game.Players.LocalPlayer
local localValues = plr:WaitForChild("LocalValues")
local autoDrinkValue = localValues:WaitForChild("AutoDrink")

local ToggleAutoDrinkAction = {}

--[[
	Function to be called to activate the action
]]
function ToggleAutoDrinkAction.Activate()
	autoDrinkValue.Value = not autoDrinkValue.Value
end

return ToggleAutoDrinkAction
