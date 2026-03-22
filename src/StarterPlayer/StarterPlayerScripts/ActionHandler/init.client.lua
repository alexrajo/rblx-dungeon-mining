local plr = game.Players.LocalPlayer
local eventFolder = Instance.new("Folder")
eventFolder.Name = "LocalActionBindables"
eventFolder.Parent = plr

local actions = script.actions:GetChildren() -- List of module scripts implementing the Activate function

-- A table that maps all the action module scripts to their names
local actionTable = {}
for _, action in pairs(actions) do
	actionTable[action.Name] = require(action)
	
	-- Create a bindable function for the action in eventFolder
	local bindable = Instance.new("BindableFunction")
	bindable.Name = action.Name
	bindable.Parent = eventFolder
	
	bindable.OnInvoke = function(...) -- The function that is called when the bindable event is invoked
		--print(action.Name, "activated!")
		return actionTable[action.Name].Activate(...)
	end
end