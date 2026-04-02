local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local ShopConfig = require(configs.ShopConfig)

local endpoint = {}

function endpoint.Call(player: Player, shopId: string, items: {{name: string, quantity: number}})
	if type(shopId) ~= "string" then return { success = false } end
	if type(items) ~= "table" then return { success = false } end

	local shopDef = ShopConfig[shopId]
	if shopDef == nil then return { success = false } end

	-- Validate all items before processing
	local totalCost = 0
	local giveMap = {}

	for _, item in ipairs(items) do
		if type(item) ~= "table" then return { success = false } end

		local name = item.name
		local quantity = item.quantity
		if type(name) ~= "string" or type(quantity) ~= "number" then
			return { success = false }
		end

		quantity = math.floor(quantity)
		if quantity <= 0 then return { success = false } end

		local price = shopDef.items[name]
		if price == nil then return { success = false } end

		giveMap[name] = (giveMap[name] or 0) + quantity
		totalCost += price * quantity
	end

	if totalCost <= 0 then return { success = false } end

	-- Check if player can afford
	local coins = PlayerDataHandler.GetCoins(player)
	if coins < totalCost then return { success = false, reason = "insufficient_coins" } end

	-- Process the purchase
	PlayerDataHandler.TakeCoins(player, totalCost)
	PlayerDataHandler.GiveItems(player, giveMap)

	return { success = true, totalCost = totalCost }
end

return endpoint
