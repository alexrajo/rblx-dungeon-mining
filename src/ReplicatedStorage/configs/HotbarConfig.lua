local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local HotbarConfig = {}

HotbarConfig.MAX_SLOTS = 5
HotbarConfig.CURRENT_VERSION = 2

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

function HotbarConfig.GetDefaultSlotsForPlayerData(playerData): {string}
	local slots = table.create(HotbarConfig.MAX_SLOTS, "")
	slots[1] = playerData.EquippedPickaxe or ""
	slots[2] = playerData.EquippedWeapon or ""
	return slots
end

function HotbarConfig.IsEntryHotbarEligible(itemName: string): boolean
	local slotName = GearConfig.GetSlotForItem(itemName)
	return slotName == "Pickaxe" or slotName == "Weapon"
end

function HotbarConfig.IsEntryAvailable(itemName: string, playerData): boolean
	if itemName == "" or not HotbarConfig.IsEntryHotbarEligible(itemName) then
		return false
	end

	local tier = GearConfig.GetTierForItem(itemName) or 0
	if tier <= 1 then
		return true
	end

	local inventory = playerData.Inventory or {}
	for _, item in ipairs(inventory) do
		if item.name == itemName and item.value > 0 then
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
	end

	return nil
end

function HotbarConfig.ResolveActiveColor(itemName: string): string
	local actionName = HotbarConfig.GetActionName(itemName)
	if actionName == "Mine" then
		return "green"
	elseif actionName == "Attack" then
		return "red"
	end

	return "gray"
end

function HotbarConfig.GetImageId(itemName: string): string
	if itemName == "" then
		return GearConfig.DEFAULT_IMAGE_ID
	end

	return GearConfig.GetImageIdForItem(itemName)
end

return HotbarConfig
