local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local BombConfig = require(ReplicatedStorage.configs.BombConfig)
local ConsumablesConfig = require(ReplicatedStorage.configs.ConsumablesConfig)
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)

local HotbarConfig = {}

HotbarConfig.MAX_SLOTS = 5

function HotbarConfig.NormalizeStoredSlots(rawSlots): {string}
	local normalized = table.create(HotbarConfig.MAX_SLOTS, "")

	if typeof(rawSlots) ~= "table" then
		return normalized
	end

	for _, entry in ipairs(rawSlots) do
		if typeof(entry) ~= "table" then
			continue
		end

		local slotIndex = tonumber(entry.name)
		if slotIndex ~= nil and slotIndex >= 1 and slotIndex <= HotbarConfig.MAX_SLOTS then
			normalized[slotIndex] = type(entry.value) == "string" and entry.value or ""
		end
	end

	return normalized
end

function HotbarConfig.IsEntryHotbarEligible(itemName: string): boolean
	if BombConfig.IsBombItem(itemName) then
		return true
	end

	if ConsumablesConfig.IsConsumableItem(itemName) then
		return true
	end

	local slotName = GearConfig.GetSlotForItem(itemName)
	return slotName == "Pickaxe" or slotName == "Weapon"
end

function HotbarConfig.ResolveEntryItemName(entryId: string?, playerData): string
	if type(entryId) ~= "string" or entryId == "" then
		return ""
	end

	if BombConfig.IsBombItem(entryId) or ConsumablesConfig.IsConsumableItem(entryId) then
		return entryId
	end

	if GearConfig.GetItemData(entryId) ~= nil then
		return entryId
	end

	for _, item in ipairs((playerData and playerData.Inventory) or {}) do
		if item.id == entryId and type(item.name) == "string" then
			return item.name
		end
	end

	return ""
end

function HotbarConfig.IsEntryIdHotbarEligible(entryId: string, playerData): boolean
	local itemName = HotbarConfig.ResolveEntryItemName(entryId, playerData)
	return itemName ~= "" and HotbarConfig.IsEntryHotbarEligible(itemName)
end

local function hasStackedInventoryItem(playerData, itemName: string): boolean
	for _, item in ipairs(playerData.Inventory or {}) do
		if item.name == itemName and type(item.value) == "number" and item.value > 0 then
			return true
		end
	end

	return false
end

local function hasInventoryInstance(playerData, entryId: string, itemName: string): boolean
	for _, item in ipairs(playerData.Inventory or {}) do
		if item.id == entryId and item.name == itemName then
			return true
		end
	end

	return false
end

function HotbarConfig.IsEntryAvailable(entryId: string, playerData): boolean
	local itemName = HotbarConfig.ResolveEntryItemName(entryId, playerData)
	if itemName == "" or not HotbarConfig.IsEntryHotbarEligible(itemName) then
		return false
	end

	if BombConfig.IsBombItem(itemName) then
		return hasStackedInventoryItem(playerData, itemName)
	end

	if ConsumablesConfig.IsConsumableItem(itemName) then
		if ConsumablesConfig.IsStackable(itemName) then
			return hasStackedInventoryItem(playerData, itemName)
		end

		return hasInventoryInstance(playerData, entryId, itemName)
	end

	if GearConfig.GetItemData(itemName) == nil then
		return false
	end

	for _, item in ipairs(playerData.Inventory or {}) do
		if item.id == entryId and item.name == itemName then
			return true
		end
	end

	return false
end

function HotbarConfig.GetActionName(itemName: string): string?
	local slotName = GearConfig.GetSlotForItem(itemName)
	if slotName == "Pickaxe" then
		return "Mine"
	elseif slotName == "Weapon" then
		return "Attack"
	elseif BombConfig.IsBombItem(itemName) then
		return "Bomb"
	elseif ConsumablesConfig.IsConsumableItem(itemName) then
		return "UseConsumable"
	end

	return nil
end

function HotbarConfig.ResolveActiveColor(itemName: string): string
	local actionName = HotbarConfig.GetActionName(itemName)
	if actionName == "Mine" then
		return "green"
	elseif actionName == "Attack" then
		return "red"
	elseif actionName == "Bomb" then
		return "orange"
	elseif actionName == "UseConsumable" then
		return "purple"
	end

	return "gray"
end

function HotbarConfig.GetImageId(itemName: string): string
	if itemName == "" then
		return ItemConfig.DEFAULT_IMAGE_ID
	end

	return ItemConfig.GetImageIdForItem(itemName)
end

return HotbarConfig
