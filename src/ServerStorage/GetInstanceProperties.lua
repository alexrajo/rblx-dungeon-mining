local module = {}

function module.GetPropertiesOfInstance(instance)
	local properties = {}
	local className = instance.ClassName
	local currentClass = className

	while currentClass do
		-- Look for ReflectionMetadataClass for this class
		local metaClass = game:GetService("ReflectionMetadata"):FindFirstChild(currentClass)
		if not metaClass then break end

		-- Look for ReflectionMetadataProperties inside the class
		for _, child in ipairs(metaClass:GetChildren()) do
			if child:IsA("ReflectionMetadataMember") and child:GetAttribute("MemberType") == "Property" then
				local name = child.Name
				local tags = child:GetAttribute("Tags") or {}
				local hidden = table.find(tags, "Hidden") or table.find(tags, "NotScriptable")

				if not hidden then
					table.insert(properties, name)
				end
			end
		end

		-- Inheritance: check superclass
		currentClass = metaClass:GetAttribute("Superclass")
	end

	return properties
end

return module
