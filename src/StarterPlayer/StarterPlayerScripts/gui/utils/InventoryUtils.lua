local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BombConfig = require(ReplicatedStorage.configs.BombConfig)

local InventoryUtils = {}

function InventoryUtils.GetInventoryCount(data, itemName: string): number
	for _, entry in ipairs(data.Inventory or {}) do
		if entry.name == itemName then
			return entry.value
		end
	end

	return 0
end

function InventoryUtils.GetBombInventoryCount(data, itemName: string): number?
	if not BombConfig.IsBombItem(itemName) then
		return nil
	end

	return InventoryUtils.GetInventoryCount(data, itemName)
end

return InventoryUtils
