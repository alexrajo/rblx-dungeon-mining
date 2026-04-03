local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local GearUtils = {}

local EQUIPPED_FIELDS = {
	"EquippedPickaxe",
	"EquippedWeapon",
	"EquippedHelmet",
	"EquippedChestplate",
	"EquippedLeggings",
	"EquippedBoots",
}

function GearUtils.GetOwnedGearEntries(data, slotFilter: ((string, {slot: string, tier: number}) -> boolean)?)
	local inventoryCounts: {[string]: number} = {}
	for _, entry in ipairs(data.Inventory or {}) do
		inventoryCounts[entry.name] = entry.value
	end

	local equippedItems: {[string]: boolean} = {}
	for _, fieldName in ipairs(EQUIPPED_FIELDS) do
		local itemName = data[fieldName]
		if type(itemName) == "string" and itemName ~= "" then
			equippedItems[itemName] = true
		end
	end

	local gearEntries = {}
	for itemName, itemData in pairs(GearConfig.items) do
		local isOwned = itemData.tier <= 1 or (inventoryCounts[itemName] or 0) > 0
		local isVisible = not equippedItems[itemName]
		if isOwned and isVisible and (slotFilter == nil or slotFilter(itemName, itemData)) then
			table.insert(gearEntries, {
				name = itemName,
				amount = math.max(inventoryCounts[itemName] or 0, itemData.tier <= 1 and 1 or 0),
				slot = itemData.slot,
				tier = itemData.tier,
			})
		end
	end

	table.sort(gearEntries, function(a, b)
		if a.slot ~= b.slot then
			return a.slot < b.slot
		end
		if a.tier ~= b.tier then
			return a.tier < b.tier
		end
		return a.name < b.name
	end)

	return gearEntries
end

return GearUtils
