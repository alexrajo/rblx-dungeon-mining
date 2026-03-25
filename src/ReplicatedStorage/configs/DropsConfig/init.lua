local dropsConfig = {
	itemDefinitions = {
		Stone = {
			imageId = "131498599100053"
		},
		Copper = {
			imageId = "119748007578926"
		},
		Iron = {
			imageId = "94875433906041"
		},
		Gold = {
			imageId = "109771614530170"
		},
		Diamond = {
			imageId = "124595491268959"
		},
		Obsidian = {
			imageId = "136977272561074"
		},
		Mythril = {
			imageId = "124856000628050"
		},
		Wood = {
			imageId = "111503525768885"
		},
		["Slime Gel"] = {
			imageId = "113708158375500"
		},
		["Bat Wing"] = {
			imageId = "100838722686920"
		},
		["Bone Fragment"] = {
			imageId = "134407417210423"
		},
		["Fire Essence"] = {
			imageId = "137224694813959"
		},
		["Healing Herb"] = {
			imageId = "108507164585415"
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
