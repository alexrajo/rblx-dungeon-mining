local ToolSelectionService = {}

local selectedTool: string = "Mine"
local changeCallbacks: {(string) -> ()} = {}

function ToolSelectionService.GetSelectedTool(): string
	return selectedTool
end

function ToolSelectionService.SetSelectedTool(toolName: string)
	if toolName == selectedTool then return end
	selectedTool = toolName
	for _, callback in ipairs(changeCallbacks) do
		callback(selectedTool)
	end
end

function ToolSelectionService.OnChanged(callback: (string) -> ()): () -> ()
	table.insert(changeCallbacks, callback)
	return function()
		for i, cb in ipairs(changeCallbacks) do
			if cb == callback then
				table.remove(changeCallbacks, i)
				break
			end
		end
	end
end

return ToolSelectionService
