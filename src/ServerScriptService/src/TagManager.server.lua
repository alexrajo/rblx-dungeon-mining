local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local tagModuleScripts = ServerScriptService.modules.tag_handlers:GetChildren()
local tagModules = {}
local appliedTagsByInstance = setmetatable({}, { __mode = "k" })

for _, moduleScript in pairs(tagModuleScripts) do
	if not moduleScript:IsA("ModuleScript") then
		continue
	end

	if tagModules[moduleScript.Name] ~= nil then 
		warn("TagManager: Error when loading tag handlers. Duplicate module name:", moduleScript.Name) 
		continue 
	end

	local tagModule = require(moduleScript)
	if type(tagModule) ~= "table" or type(tagModule.Apply) ~= "function" then
		warn("TagManager: Tag handler is missing Apply(instance):", moduleScript.Name)
		continue
	end

	tagModules[moduleScript.Name] = tagModule
end

local function applyTag(instance: Instance, tag: string)
	if tagModules[tag] == nil then return end

	local appliedTags = appliedTagsByInstance[instance]
	if appliedTags == nil then
		appliedTags = {}
		appliedTagsByInstance[instance] = appliedTags
	elseif appliedTags[tag] then
		return
	end

	appliedTags[tag] = true
	tagModules[tag].Apply(instance)
end

-- Apply to existing tagged instances and subscribe for future instances based on available handlers.
for tag in pairs(tagModules) do
	for _, instance in pairs(CollectionService:GetTagged(tag)) do
		applyTag(instance, tag)
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(function(newInstance)
		applyTag(newInstance, tag)
	end)
end
