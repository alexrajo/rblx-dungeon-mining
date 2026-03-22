local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local endpoint = {}

function endpoint.Call(player: Player, drinkName: string)
	PlayerDataHandler.EquipDrink(player, drinkName)
end

return endpoint
