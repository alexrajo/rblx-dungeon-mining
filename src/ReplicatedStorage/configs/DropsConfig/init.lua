local dropsConfig = {
	itemDefinitions = {
		Stone = {
			imageId = "131498599100053",
			description = "A common rock used for early crafting and building around camp.",
		},
		Copper = {
			imageId = "119748007578926",
			description = "A soft metal ore used to craft your first upgraded tools and armor.",
		},
		Iron = {
			imageId = "94875433906041",
			description = "A sturdy ore used for reliable mid-depth mining and combat gear.",
		},
		Gold = {
			imageId = "109771614530170",
			description = "A valuable ore used for advanced crafting and profitable sales.",
		},
		Diamond = {
			imageId = "124595491268959",
			description = "A rare crystal used to craft powerful gear for dangerous mine layers.",
		},
		Obsidian = {
			imageId = "136977272561074",
			description = "A dense volcanic resource used for late-game equipment.",
		},
		Mythril = {
			imageId = "124856000628050",
			description = "A very rare ore from the deepest mines, prized for top-tier crafting.",
		},
		Wood = {
			imageId = "111503525768885",
			description = "A basic crafting material used for handles, shafts, and camp supplies.",
		},
		["Slime Gel"] = {
			imageId = "113708158375500",
			description = "A sticky monster drop used in potion crafting.",
		},
		["Bat Wing"] = {
			imageId = "100838722686920",
			description = "A lightweight monster drop used for mobility-focused consumables.",
		},
		["Bone Fragment"] = {
			imageId = "134407417210423",
			description = "A brittle monster drop used for weapon and potion recipes.",
		},
		["Fire Essence"] = {
			imageId = "137224694813959",
			description = "A hot magical reagent gathered from dangerous deep-mine enemies.",
		},
		["Healing Herb"] = {
			imageId = "108507164585415",
			description = "A restorative plant used to brew healing consumables.",
		},
	},
	types = {}
}

function dropsConfig.RollLoot(dropType: string): {[string]: number}
	local rewards = {}
	local loot = dropsConfig.types[dropType]
	if loot == nil then
		return rewards
	end

	for _, entry in ipairs(loot) do
		local itemName = entry.itemName
		if type(itemName) ~= "string" or itemName == "" then
			continue
		end

		local chance = if type(entry.chance) == "number" then entry.chance else 1
		if math.random() > chance then
			continue
		end

		local minAmount = if type(entry.minAmount) == "number" then entry.minAmount else 1
		local maxAmount = if type(entry.maxAmount) == "number" then entry.maxAmount else minAmount
		minAmount = math.max(1, math.floor(minAmount))
		maxAmount = math.max(minAmount, math.floor(maxAmount))

		local amount = math.random(minAmount, maxAmount)
		rewards[itemName] = (rewards[itemName] or 0) + amount
	end

	return rewards
end

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
