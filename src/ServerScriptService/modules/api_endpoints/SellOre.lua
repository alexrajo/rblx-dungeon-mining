local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local OreConfig = require(configs.OreConfig)

local endpoint = {}

function endpoint.Call(player: Player, oreName: string, quantity: number)
	if type(oreName) ~= "string" or type(quantity) ~= "number" then
		return false
	end
	quantity = math.floor(quantity)
	if quantity <= 0 then return false end

	local oreData = OreConfig.byName[oreName]
	if oreData == nil then return false end

	local owned = PlayerDataHandler.GetItemCount(player, oreName)
	if owned < quantity then return false end

	local coinValue = oreData.baseValue * quantity
	PlayerDataHandler.TakeItems(player, { [oreName] = quantity })
	PlayerDataHandler.GiveCoins(player, coinValue)

	return true
end

return endpoint
