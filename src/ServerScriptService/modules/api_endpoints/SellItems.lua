local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local SellPriceConfig = require(configs.SellPriceConfig)
local GearConfig = require(configs.GearConfig)

local endpoint = {}

local function isEquippedGear(player: Player, itemName: string): boolean
	local slotName = GearConfig.GetSlotForItem(itemName)
	if slotName == nil then
		return false
	end

	local equippedArmor = PlayerDataHandler.GetEquippedArmor(player)
	for _, equippedName in pairs(equippedArmor) do
		if equippedName == itemName then
			return true
		end
	end

	if slotName ~= "Pickaxe" and slotName ~= "Weapon" then
		return false
	end

	local hotbarSlots = PlayerDataHandler.GetHotbarSlots(player)
	for _, hotbarItemName in ipairs(hotbarSlots) do
		if hotbarItemName == itemName then
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

	for _, item in ipairs(items) do
		if type(item) ~= "table" then return { success = false } end

		local name = item.name
		local quantity = item.quantity
		if type(name) ~= "string" or type(quantity) ~= "number" then
			return { success = false }
		end

		quantity = math.floor(quantity)
		if quantity <= 0 then return { success = false } end

		local price = SellPriceConfig[name]
		if price == nil then return { success = false } end

		if isEquippedGear(player, name) then
			return { success = false, reason = "equipped" }
		end

		local owned = PlayerDataHandler.GetItemCount(player, name)
		if owned < quantity then return { success = false } end

		takeMap[name] = (takeMap[name] or 0) + quantity
		totalCoins += price * quantity
	end

	if totalCoins <= 0 then return { success = false } end

	-- Process the sale
	PlayerDataHandler.TakeItems(player, takeMap)
	PlayerDataHandler.GiveCoins(player, totalCoins)

	return { success = true, totalCoins = totalCoins }
end

return endpoint
