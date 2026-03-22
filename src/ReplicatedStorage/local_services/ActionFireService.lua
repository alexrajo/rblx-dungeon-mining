local plr = game.Players.LocalPlayer

local ActionFireService = {}

function ActionFireService.GetAction(name: string): BindableFunction
	local bindableFolder = plr:WaitForChild("LocalActionBindables")
	local actionBindable = bindableFolder:WaitForChild(name)
	return actionBindable
end

return ActionFireService
