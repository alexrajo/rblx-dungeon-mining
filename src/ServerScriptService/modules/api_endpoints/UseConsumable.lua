local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local BuffsManager = require(modules.BuffsManager)

local configs = ReplicatedStorage.configs
local ConsumablesConfig = require(configs.ConsumablesConfig)
local globalConfig = require(ReplicatedStorage.GlobalConfig)

-- Timestamp-based per-player cooldown. Keyed by Player instance so entries
-- are automatically distinct across sessions; cleaned up on PlayerRemoving.
local lastUseTime: {[Player]: number} = {}

Players.PlayerRemoving:Connect(function(player)
	lastUseTime[player] = nil
end)

local endpoint = {}

type SelectedConsumable = {
	entryId: string,
	itemName: string,
}

local function getSelectedConsumable(player: Player): SelectedConsumable?
	local selectedSlot = PlayerDataHandler.GetSelectedHotbarSlot(player)
	if selectedSlot <= 0 then
		return nil
	end

	local hotbarSlots = PlayerDataHandler.GetHotbarSlots(player)
	local entryId = hotbarSlots[selectedSlot]
	local itemName = PlayerDataHandler.ResolveInventoryEntryItemName(player, entryId)
	if not ConsumablesConfig.IsConsumableItem(itemName) then
		return nil
	end

	return {
		entryId = entryId,
		itemName = itemName,
	}
end

function endpoint.Call(player: Player)
	local selectedConsumable = getSelectedConsumable(player)
	if selectedConsumable == nil then
		return { success = false, cooldown = 0.1, reason = "invalid_consumable" }
	end
	local itemName = selectedConsumable.itemName

	local consumableData = ConsumablesConfig.GetConsumableData(itemName)
	if consumableData == nil then
		return { success = false, cooldown = 0.1, reason = "invalid_consumable" }
	end

	-- Timestamp-based cooldown check with server leniency window
	local now = os.clock()
	local serverWindow = ConsumablesConfig.USE_COOLDOWN - globalConfig.SERVER_ACTION_LENIENCY
	if lastUseTime[player] and (now - lastUseTime[player]) < serverWindow then
		return { success = false, cooldown = 0.1 }
	end

	if PlayerDataHandler.GetItemCount(player, itemName) <= 0 then
		return { success = false, cooldown = 0.1, reason = "missing_item" }
	end

	if not ConsumablesConfig.IsStackable(itemName) and PlayerDataHandler.GetItemInstance(player, selectedConsumable.entryId) == nil then
		return { success = false, cooldown = 0.1, reason = "missing_item" }
	end

	local character = player.Character
	if character == nil then
		return { success = false, cooldown = 0.1 }
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return { success = false, cooldown = 0.1 }
	end

	-- Record accepted time before any state mutations
	lastUseTime[player] = os.clock()

	if ConsumablesConfig.IsStackable(itemName) then
		PlayerDataHandler.TakeItems(player, { [itemName] = 1 })
	else
		PlayerDataHandler.TakeItemInstances(player, { selectedConsumable.entryId })
	end

	-- Apply effect based on type
	local effectType = consumableData.effectType

	if effectType == "heal" then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + consumableData.healAmount)

	elseif effectType == "speed" then
		BuffsManager.ApplySpeedBuff(player, consumableData.speedBonus, consumableData.duration)

	elseif effectType == "damage" then
		BuffsManager.ApplyDamageMultiplier(player, consumableData.damageMultiplier, consumableData.duration)
	end

	return { success = true, cooldown = ConsumablesConfig.USE_COOLDOWN }
end

return endpoint
