local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local SellPriceConfig = require(configs.SellPriceConfig)
local GearConfig = require(configs.GearConfig)

local endpoint = {}

local function isEquippedEntry(player: Player, entryId: string): boolean
	if type(entryId) ~= "string" or entryId == "" then
		return false
	end

	local equippedArmor = PlayerDataHandler.GetEquippedArmor(player)
	for _, equippedEntryId in pairs(equippedArmor) do
		if equippedEntryId == entryId then
			return true
		end
	end

	local hotbarSlots = PlayerDataHandler.GetHotbarSlots(player)
	for _, hotbarEntryId in ipairs(hotbarSlots) do
		if hotbarEntryId == entryId then
			return true
		end
	end

	return false
end

function endpoint.Call(player: Player, items: {{name: string, quantity: number}})
	if type(items) ~= "table" then return { success = false } end

	-- Validate all items before processing
	local totalCoins = 0
	local takeMap = {}
	local instanceIds = {}
	local seenInstanceIds = {}

	for _, item in ipairs(items) do
		if type(item) ~= "table" then return { success = false } end

		local itemId = item.id
		if type(itemId) == "string" and itemId ~= "" then
			if seenInstanceIds[itemId] then
				return { success = false }
			end
			seenInstanceIds[itemId] = true

			if isEquippedEntry(player, itemId) then
				return { success = false, reason = "equipped" }
			end

			local itemInstance = PlayerDataHandler.GetItemInstance(player, itemId)
			if itemInstance == nil then return { success = false } end

			local name = itemInstance.name
			if GearConfig.GetItemData(name) == nil or GearConfig.IsStackable(name) then
				return { success = false }
			end

			local price = SellPriceConfig[name]
			if price == nil then return { success = false } end

			table.insert(instanceIds, itemId)
			totalCoins += price
		else
			local name = item.name
			local quantity = item.quantity
			if type(name) ~= "string" or type(quantity) ~= "number" then
				return { success = false }
			end

			quantity = math.floor(quantity)
			if quantity <= 0 then return { success = false } end

			if GearConfig.GetItemData(name) ~= nil and not GearConfig.IsStackable(name) then
				return { success = false }
			end

			local price = SellPriceConfig[name]
			if price == nil then return { success = false } end

			local owned = PlayerDataHandler.GetItemCount(player, name)
			if owned < quantity then return { success = false } end

			takeMap[name] = (takeMap[name] or 0) + quantity
			totalCoins += price * quantity
		end
	end

	if totalCoins <= 0 then return { success = false } end

	-- Process the sale
	if next(takeMap) ~= nil then
		PlayerDataHandler.TakeItems(player, takeMap)
	end
	if #instanceIds > 0 and not PlayerDataHandler.TakeItemInstances(player, instanceIds) then
		return { success = false }
	end
	PlayerDataHandler.GiveCoins(player, totalCoins)

	return { success = true, totalCoins = totalCoins }
end

return endpoint
