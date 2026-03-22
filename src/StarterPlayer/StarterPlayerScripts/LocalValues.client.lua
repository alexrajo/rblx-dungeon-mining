local plr = game.Players.LocalPlayer
local localValues = Instance.new("Folder")
localValues.Name = "LocalValues"
localValues.Parent = plr

local autoDrink = Instance.new("BoolValue")
autoDrink.Name = "AutoDrink"
autoDrink.Value = false
autoDrink.Parent = localValues