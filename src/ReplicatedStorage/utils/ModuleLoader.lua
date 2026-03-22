local ModuleLoader = {}

local function _loadLayer(parent: DataModel)
	local loadedModules = {}
	local folders = {}
	for _, child in pairs(parent:GetChildren()) do
		if loadedModules[child.Name] ~= nil then
			continue
		end
		if child:IsA("ModuleScript") then
			loadedModules[child.Name] = require(child)
		elseif child:IsA("Folder") then
			table.insert(folders, child)
		end
	end
	return loadedModules, folders
end

function ModuleLoader.shallowLoad(parent: DataModel)
	local modules, _ = _loadLayer(parent)
	return modules
end

function ModuleLoader.deepLoad(parent: DataModel, maxDepth: int, currentDepth: int | nil)
	currentDepth = currentDepth or 1
	maxDepth = maxDepth or 5

	local modules, folders = _loadLayer(parent)

	if currentDepth < maxDepth then
		for _, folder in pairs(folders) do
			modules[folder.Name] = ModuleLoader.deepLoad(folder, maxDepth, currentDepth + 1)
		end
	end

	return modules
end

return ModuleLoader
