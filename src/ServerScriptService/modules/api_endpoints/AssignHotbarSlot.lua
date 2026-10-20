local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)
local ItemLevelService = require(ServerScriptService.modules.ItemLevelService)

local endpoint = {}

function endpoint.Call(player: Player, slotIndex: number, entryId: string)
	if type(entryId) ~= "string" then return false end
	local itemName = PlayerDataHandler.ResolveInventoryEntryItemName(player, entryId)
	if ItemLevelService.Check(player, itemName, true) ~= nil then
		return false
	end
	return PlayerDataHandler.AssignHotbarEntry(player, slotIndex, entryId)
end

return endpoint
