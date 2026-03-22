local dropsConfig = {
	itemDefinitions = {
		Stone = {
			imageId = "ASSET_ID_HERE"
		},
		Copper = {
			imageId = "ASSET_ID_HERE"
		},
		Iron = {
			imageId = "ASSET_ID_HERE"
		},
		Gold = {
			imageId = "ASSET_ID_HERE"
		},
		Diamond = {
			imageId = "ASSET_ID_HERE"
		},
		Obsidian = {
			imageId = "ASSET_ID_HERE"
		},
		Mythril = {
			imageId = "ASSET_ID_HERE"
		},
		Wood = {
			imageId = "ASSET_ID_HERE"
		},
		["Slime Gel"] = {
			imageId = "ASSET_ID_HERE"
		},
		["Bat Wing"] = {
			imageId = "ASSET_ID_HERE"
		},
		["Bone Fragment"] = {
			imageId = "ASSET_ID_HERE"
		},
		["Fire Essence"] = {
			imageId = "ASSET_ID_HERE"
		},
		["Healing Herb"] = {
			imageId = "ASSET_ID_HERE"
		},
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
