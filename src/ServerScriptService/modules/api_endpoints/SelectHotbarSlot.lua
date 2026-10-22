local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)
local ItemLevelService = require(ServerScriptService.modules.ItemLevelService)

local endpoint = {}

function endpoint.Call(player: Player, slotIndex: number)
	if type(slotIndex) ~= "number" then return false end
	local entryId = PlayerDataHandler.GetHotbarSlots(player)[slotIndex]
	if entryId ~= nil and entryId ~= "" then
		local itemName = PlayerDataHandler.ResolveInventoryEntryItemName(player, entryId)
		if ItemLevelService.Check(player, itemName, true) ~= nil then
			return false
		end
	end
	return PlayerDataHandler.SetSelectedHotbarSlot(player, slotIndex)
end

return endpoint
