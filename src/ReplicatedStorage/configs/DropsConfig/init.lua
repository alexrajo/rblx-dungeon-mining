local dropsConfig = {
	itemDefinitions = {
		apple = {
			imageId = "75930677705281"
		},
		leaf = {
			imageId = "101046749640533"
		}
	},
	types = {}
}

for _, m in pairs(script:GetChildren()) do
	if m:IsA("ModuleScript") then
		if dropsConfig.types[m.Name] ~= nil then
			warn("The drops for", m.Name, "are defined multiple times!")
			continue
		end
		dropsConfig.types[m.Name] = require(m)
	end
end

return dropsConfig
