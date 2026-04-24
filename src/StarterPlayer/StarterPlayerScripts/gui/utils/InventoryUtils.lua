local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BombConfig = require(ReplicatedStorage.configs.BombConfig)
local ConsumablesConfig = require(ReplicatedStorage.configs.ConsumablesConfig)

local InventoryUtils = {}

function InventoryUtils.GetInventoryCount(data, itemName: string): number
	local count = 0
	for _, entry in ipairs(data.Inventory or {}) do
		if entry.name == itemName then
			if type(entry.value) == "number" then
				count += entry.value
			elseif type(entry.id) == "string" then
				count += 1
			end
		end
	end

	return count
end

function InventoryUtils.GetInventoryInstance(data, itemId: string)
	for _, entry in ipairs(data.Inventory or {}) do
		if entry.id == itemId then
			return entry
		end
	end

	return nil
end

function InventoryUtils.ResolveEntryItemName(data, entryId: string?): string
	if type(entryId) ~= "string" or entryId == "" then
		return ""
	end

	local itemInstance = InventoryUtils.GetInventoryInstance(data, entryId)
	if itemInstance ~= nil and type(itemInstance.name) == "string" then
		return itemInstance.name
	end

	return entryId
end

function InventoryUtils.GetStackDisplayCount(data, itemName: string): number?
	if not BombConfig.IsBombItem(itemName) and not ConsumablesConfig.IsStackable(itemName) then
		return nil
	end

	return InventoryUtils.GetInventoryCount(data, itemName)
end

return InventoryUtils
