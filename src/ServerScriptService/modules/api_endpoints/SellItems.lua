local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local SellPriceConfig = require(configs.SellPriceConfig)
local GearConfig = require(configs.GearConfig)

local endpoint = {}

function endpoint.Call(player: Player, items: {{name: string, quantity: number}})
	if type(items) ~= "table" then return { success = false } end

	-- Validate all items before processing
	local totalCoins = 0
	local takeMap = {}
	local equippedGear = PlayerDataHandler.GetEquippedGear(player)

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

		-- Prevent selling equipped gear
		if GearConfig.items[name] then
			for _, equippedName in pairs(equippedGear) do
				if equippedName == name then
					return { success = false, reason = "equipped" }
				end
			end
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
