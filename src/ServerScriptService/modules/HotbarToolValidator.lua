local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local GearConfig = require(configs.GearConfig)
local HotbarConfig = require(configs.HotbarConfig)

local HotbarToolValidator = {}

function HotbarToolValidator.Validate(
	player: Player,
	tool: Instance?,
	expectedActionName: string,
	expectedGearSlot: string?
): (boolean, string?, string?)
	if tool == nil or not tool:IsA("Tool") then
		return false, nil, "invalid_tool"
	end

	local character = player.Character
	if character == nil or tool.Parent ~= character then
		return false, nil, "tool_not_wielded"
	end

	local slotIndex = tool:GetAttribute("HotbarSlot")
	local entryId = tool:GetAttribute("HotbarEntryId")
	local itemName = tool:GetAttribute("HotbarItemName")
	local actionName = tool:GetAttribute("HotbarActionName")

	if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > HotbarConfig.MAX_SLOTS then
		return false, nil, "invalid_hotbar_slot"
	end
	if type(entryId) ~= "string" or entryId == "" then
		return false, nil, "invalid_hotbar_entry"
	end
	if type(itemName) ~= "string" or itemName == "" then
		return false, nil, "invalid_hotbar_item"
	end
	if actionName ~= expectedActionName then
		return false, nil, "wrong_action"
	end
	if HotbarConfig.GetActionName(itemName) ~= expectedActionName then
		return false, nil, "wrong_item_action"
	end
	if expectedGearSlot ~= nil and GearConfig.GetSlotForItem(itemName) ~= expectedGearSlot then
		return false, nil, "wrong_gear_slot"
	end

	local hotbarSlots = PlayerDataHandler.GetHotbarSlots(player)
	if hotbarSlots[slotIndex] ~= entryId then
		return false, nil, "hotbar_mismatch"
	end

	if PlayerDataHandler.ResolveInventoryEntryItemName(player, entryId) ~= itemName then
		return false, nil, "entry_item_mismatch"
	end

	return true, itemName, nil
end

return HotbarToolValidator
