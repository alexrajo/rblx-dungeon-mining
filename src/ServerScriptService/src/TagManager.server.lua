local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local tagModuleScripts = ServerScriptService.modules.tag_handlers:GetChildren()
local tagModules = {}

for _, moduleScript in pairs(tagModuleScripts) do
	if tagModules[moduleScript.Name] ~= nil then 
		warn("TagManager: Error when loading tag handlers. Duplicate module name:", moduleScript.Name) 
		continue 
	end
	tagModules[moduleScript.Name] = require(moduleScript)
end

local function applyTag(instance: Instance, tag: string)
	if tagModules[tag] == nil then return end
	tagModules[tag].Apply(instance)
end

-- Initially apply tag properties to all tagged instances and connect to an instance added signal for every tag
local tags = CollectionService:GetAllTags()

for _, tag in pairs(tags) do
	if tagModules[tag] == nil then continue end -- No reason to attempt to call a module that does not exist
	
	local instances = CollectionService:GetTagged(tag)
	
	for _, instance in pairs(instances) do
		applyTag(instance, tag)
	end
	
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(newInstance)
		applyTag(newInstance, tag)
	end)
end