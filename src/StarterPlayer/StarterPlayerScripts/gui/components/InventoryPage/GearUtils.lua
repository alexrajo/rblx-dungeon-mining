local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local InventoryUtils = require(ModuleIndex.InventoryUtils)

local GearUtils = {}

local EQUIPPED_FIELDS = {
	"EquippedHelmet",
	"EquippedChestplate",
	"EquippedLeggings",
	"EquippedBoots",
}

function GearUtils.GetOwnedGearEntries(data, slotFilter: ((string, {slot: string}) -> boolean)?)
	local equippedItems: {[string]: boolean} = {}
	for _, fieldName in ipairs(EQUIPPED_FIELDS) do
		local itemId = data[fieldName]
		if type(itemId) == "string" and itemId ~= "" then
			equippedItems[itemId] = true
		end
	end
	for _, entryId in ipairs(HotbarConfig.NormalizeStoredSlots(data.HotbarSlots or {})) do
		if entryId ~= "" then
			equippedItems[entryId] = true
		end
	end

	local gearEntries = {}
	for _, entry in ipairs(data.Inventory or {}) do
		local itemName = entry.name
		local itemData = GearConfig.GetItemData(itemName)
		if itemData == nil then
			continue
		end

		local isStackable = GearConfig.IsStackable(itemName)
		local entryId = isStackable and itemName or entry.id
		if type(entryId) ~= "string" or entryId == "" then
			continue
		end

		local isVisible = not equippedItems[entryId]
		if isVisible and (slotFilter == nil or slotFilter(itemName, itemData)) then
			local amount = isStackable and InventoryUtils.GetInventoryCount(data, itemName) or nil
			table.insert(gearEntries, {
				id = entryId,
				name = itemName,
				amount = amount,
				slot = itemData.slot,
			})
		end
	end

	table.sort(gearEntries, function(a, b)
		if a.slot ~= b.slot then
			return a.slot < b.slot
		end
		return a.name < b.name
	end)

	return gearEntries
end

return GearUtils
