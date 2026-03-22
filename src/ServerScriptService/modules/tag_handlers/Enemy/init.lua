local controllerScriptRef = script.EnemyController
controllerScriptRef.Enabled = false

local TagHandler = {}

function TagHandler.Apply(instance: Instance)
	local controller = controllerScriptRef:Clone()
	controller.Parent = instance
	controller.Enabled = true
end

return TagHandler
