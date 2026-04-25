local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Services = ReplicatedStorage.services
local ProfileService = require(Services.ProfileService)
local DatabaseClientClass = require(game.ServerScriptService.modules.DatabaseClient)
local ProfileTemplate = require(script.ProfileTemplate)
local TempStats = require(script.TempStats)
local ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)
local APIService = require(Services.APIService)
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

local PlayerDataFolder = Instance.new("Folder")
PlayerDataFolder.Name = "PlayerData"
PlayerDataFolder.Parent = ReplicatedStorage

local dbClients = {}
local PlayerDataHandler = {}
local getStat
local setStat

local STARTER_HOTBAR_ITEMS = {
	[1] = "Wood Pickaxe",
	[2] = "Wood Sword",
}

local function handleRelease(player, client)
	dbClients[player] = nil
	player:Kick()
end

local function buildStoredHotbarSlots(slotValues: {string})
	local stored = {}
	for index = 1, HotbarConfig.MAX_SLOTS do
		table.insert(stored, {
			name = tostring(index),
			value = slotValues[index] or "",
		})
	end
	return stored
end

local function normalizeHotbarSlots(rawSlots): {string}
	local normalized = table.create(HotbarConfig.MAX_SLOTS, "")

	if typeof(rawSlots) ~= "table" then
		return normalized
	end

	for _, entry in ipairs(rawSlots) do
		if typeof(entry) ~= "table" then
			continue
		end

		local slotIndex = tonumber(entry.name)
		if slotIndex ~= nil and slotIndex >= 1 and slotIndex <= HotbarConfig.MAX_SLOTS then
			normalized[slotIndex] = type(entry.value) == "string" and entry.value or ""
		end
	end

	return normalized
end

local function getPlayerDataSnapshot(player: Player)
	return {
		Inventory = getStat("Inventory", ProfileTemplate.Inventory, player),
		EquippedHelmet = getStat("EquippedHelmet", ProfileTemplate.EquippedHelmet, player),
		EquippedChestplate = getStat("EquippedChestplate", ProfileTemplate.EquippedChestplate, player),
		EquippedLeggings = getStat("EquippedLeggings", ProfileTemplate.EquippedLeggings, player),
		EquippedBoots = getStat("EquippedBoots", ProfileTemplate.EquippedBoots, player),
	}
end

local function isInstanceInventoryItem(itemName: string): boolean
	return GearConfig.GetItemData(itemName) ~= nil and not GearConfig.IsStackable(itemName)
end

local function createItemInstance(itemName: string)
	return {
		id = HttpService:GenerateGUID(false),
		name = itemName,
	}
end

local function findInventoryInstanceByName(inventory, itemName: string)
	for _, entry in ipairs(inventory or {}) do
		if type(entry.id) == "string" and entry.name == itemName then
			return entry
		end
	end

	return nil
end

local function findInventoryInstanceById(inventory, itemId: string)
	for _, entry in ipairs(inventory or {}) do
		if entry.id == itemId and type(entry.name) == "string" then
			return entry
		end
	end

	return nil
end

local function ensureStarterGear(player: Player)
	local inventory = table.clone(getStat("Inventory", ProfileTemplate.Inventory, player))
	local changed = false
	local starterInstances = {}

	for _, itemName in pairs(STARTER_HOTBAR_ITEMS) do
		local itemInstance = findInventoryInstanceByName(inventory, itemName)
		if itemInstance == nil then
			itemInstance = createItemInstance(itemName)
			table.insert(inventory, itemInstance)
			changed = true
		end
		starterInstances[itemName] = itemInstance
	end

	if changed then
		setStat("Inventory", inventory, player)
	end

	local slotValues = normalizeHotbarSlots(getStat("HotbarSlots", ProfileTemplate.HotbarSlots, player))
	local hotbarChanged = false
	for slotIndex, itemName in pairs(STARTER_HOTBAR_ITEMS) do
		if slotValues[slotIndex] == "" or slotValues[slotIndex] == itemName then
			local itemInstance = starterInstances[itemName]
			if itemInstance ~= nil and slotValues[slotIndex] ~= itemInstance.id then
				slotValues[slotIndex] = itemInstance.id
				hotbarChanged = true
			end
		end
	end

	if hotbarChanged then
		setStat("HotbarSlots", buildStoredHotbarSlots(slotValues), player)
	end
end

local function sanitizeHotbarData(player: Player)
	local playerData = getPlayerDataSnapshot(player)
	local slotValues = normalizeHotbarSlots(getStat("HotbarSlots", ProfileTemplate.HotbarSlots, player))
	local seenEntries: {[string]: boolean} = {}

	for index, entryId in ipairs(slotValues) do
		local isValid = entryId ~= ""
			and HotbarConfig.IsEntryAvailable(entryId, playerData)
			and not seenEntries[entryId]

		if isValid then
			seenEntries[entryId] = true
		else
			slotValues[index] = ""
		end
	end

	local selectedSlot = getStat("SelectedHotbarSlot", 0, player)
	if type(selectedSlot) ~= "number" then
		selectedSlot = 0
	end
	if selectedSlot ~= 0 and (selectedSlot < 1 or selectedSlot > HotbarConfig.MAX_SLOTS or slotValues[selectedSlot] == "") then
		selectedSlot = 0
	end

	setStat("HotbarSlots", buildStoredHotbarSlots(slotValues), player)
	setStat("SelectedHotbarSlot", selectedSlot, player)
end

local function initializeClient(player: Player)
	if dbClients[player] ~= nil then return end
	local client = DatabaseClientClass.new(ProfileStore, PlayerDataFolder, player, function(client)
		handleRelease(player, client)
	end)
	if client == nil then
		player:Kick("Unable to load data, please rejoin.")
		return
	end
	dbClients[player] = client
	TempStats:InitializePlayer(player)
	ensureStarterGear(player)
	sanitizeHotbarData(player)
	PlayerDataHandler.ApplyPlayerMoveSpeed(player)
end

function addToStat(statName: string, defaultValue, player: Player, amount: number)
	local client = dbClients[player]
	if client ~= nil then
		local currentValue = client:GetDataValue(statName, defaultValue)
		client:SetDataValue(statName, currentValue + amount)
		return currentValue + amount
	end
end

function getStat(statName: string, defaultValue, player: Player)
	local client = dbClients[player]
	if client ~= nil then
		return client:GetDataValue(statName, defaultValue)
	end
	return defaultValue
end

function setStat(statName: string, value, player: Player)
	local client = dbClients[player]
	if client ~= nil then
		client:SetDataValue(statName, value)
	end
end

function PlayerDataHandler.GetClient(player: Player)
	return dbClients[player]
end

function PlayerDataHandler.ListenToStatUpdate(statName: string, player: Player, callback: (value: any) -> ())
	local client = dbClients[player]
	local maxNumRetries = 1000
	local n = 0
	while client == nil and n < maxNumRetries do
		n += 1
		task.wait()
		client = dbClients[player]
	end
	if client ~= nil then
		return client:ListenToDataValue(statName, callback)
	end
end

-- Currency
function PlayerDataHandler.GiveCoins(player: Player, amount: number)
	addToStat("Coins", 0, player, amount)
end

function PlayerDataHandler.TakeCoins(player: Player, amount: number)
	addToStat("Coins", 0, player, -amount)
end

function PlayerDataHandler.GetCoins(player: Player): number
	return getStat("Coins", 0, player)
end

-- XP & Leveling
function PlayerDataHandler.GiveXP(player: Player, amount: number)
	local xp = getStat("XP", 0, player)
	local level = getStat("Level", 1, player)
	local xpRequirement = StatCalculation.GetLevelUpXPRequirement(level)
	local remainingXPRequirement = xpRequirement - xp

	if remainingXPRequirement > amount then
		addToStat("XP", 0, player, amount)
	else
		setStat("XP", xp + amount - xpRequirement, player)
		PlayerDataHandler.GiveLevel(player, 1)
	end
end

function PlayerDataHandler.GiveLevel(player: Player, amount: number)
	local newLevel = addToStat("Level", 1, player, amount)

	local notificationEvent = APIService.GetEvent("SendNotification")
	notificationEvent:FireClient(player, {Type = "levelup", Title = "Level up!", Level = newLevel})
end

-- Inventory (stackable items and instanced gear)
function PlayerDataHandler.GiveItems(player: Player, itemsMap: {[string]: number})
	if next(itemsMap) == nil then return end
	local ownedItems = getStat("Inventory", {}, player)
	local pendingItems = {}
	for itemName, amount in pairs(itemsMap) do
		local amountToGive = math.floor(amount)
		if amountToGive == 0 then
			continue
		end

		if isInstanceInventoryItem(itemName) then
			for _ = 1, amountToGive do
				table.insert(ownedItems, createItemInstance(itemName))
			end
		else
			pendingItems[itemName] = (pendingItems[itemName] or 0) + amountToGive
		end
	end

	for i, item in pairs(ownedItems) do
		local itemName = item.name
		local itemAmount = item.value

		local amountToGive = pendingItems[itemName]
		if amountToGive ~= nil then
			local nextAmount = itemAmount + amountToGive
			ownedItems[i] = {name = itemName, value = nextAmount}
			pendingItems[itemName] = nil
		end
	end
	for itemName, itemAmount in pairs(pendingItems) do
		if itemAmount == nil then continue end
		table.insert(ownedItems, {name = itemName, value = itemAmount})
	end

	for index = #ownedItems, 1, -1 do
		local entry = ownedItems[index]
		if entry.value ~= nil and entry.value <= 0 then
			table.remove(ownedItems, index)
		end
	end

	setStat("Inventory", ownedItems, player)
	sanitizeHotbarData(player)
end

function PlayerDataHandler.TakeItems(player: Player, itemsMap: {[string]: number})
	local tblClone = table.clone(itemsMap)
	for i, v in pairs(tblClone) do
		tblClone[i] = -v
	end
	PlayerDataHandler.GiveItems(player, tblClone)
end

function PlayerDataHandler.TakeItemInstances(player: Player, itemIds: {string}): boolean
	local ownedItems = getStat("Inventory", {}, player)
	local idsToRemove = {}
	for _, itemId in ipairs(itemIds) do
		if type(itemId) ~= "string" or itemId == "" then
			return false
		end
		idsToRemove[itemId] = true
	end

	for itemId in pairs(idsToRemove) do
		if findInventoryInstanceById(ownedItems, itemId) == nil then
			return false
		end
	end

	for index = #ownedItems, 1, -1 do
		local entry = ownedItems[index]
		if type(entry.id) == "string" and idsToRemove[entry.id] then
			table.remove(ownedItems, index)
		end
	end

	setStat("Inventory", ownedItems, player)
	sanitizeHotbarData(player)
	return true
end

function PlayerDataHandler.GetInventory(player: Player)
	return getStat("Inventory", ProfileTemplate.Inventory, player)
end

function PlayerDataHandler.GetItemCount(player: Player, itemName: string): number
	local inventory = PlayerDataHandler.GetInventory(player)
	local count = 0
	for _, entry in pairs(inventory) do
		if entry.name == itemName then
			if type(entry.value) == "number" then
				count += entry.value
			elseif type(entry.id) == "string" then
				count += 1
			end
		end
	end
	return count
end

function PlayerDataHandler.HasItems(player: Player, itemsMap: {[string]: number}): boolean
	for itemName, requiredAmount in pairs(itemsMap) do
		if PlayerDataHandler.GetItemCount(player, itemName) < requiredAmount then
			return false
		end
	end
	return true
end

-- Gear
function PlayerDataHandler.GetItemInstance(player: Player, itemId: string)
	return findInventoryInstanceById(PlayerDataHandler.GetInventory(player), itemId)
end

function PlayerDataHandler.ResolveInventoryEntryItemName(player: Player, entryId: string): string
	local snapshot = getPlayerDataSnapshot(player)
	return HotbarConfig.ResolveEntryItemName(entryId, snapshot)
end

function PlayerDataHandler.PlayerOwnsItemInstance(player: Player, itemId: string): boolean
	return PlayerDataHandler.GetItemInstance(player, itemId) ~= nil
end

function PlayerDataHandler.EquipGear(player: Player, itemId: string, slot: string)
	if not GearConfig.IsArmorSlot(slot) then
		return false
	end

	local itemInstance = PlayerDataHandler.GetItemInstance(player, itemId)
	if itemInstance == nil then
		return false
	end

	local itemName = itemInstance.name
	if GearConfig.GetSlotForItem(itemName) ~= slot then
		return false
	end

	local fieldName = "Equipped" .. slot
	setStat(fieldName, itemId, player)
	sanitizeHotbarData(player)
	if slot == "Boots" then
		PlayerDataHandler.ApplyPlayerMoveSpeed(player)
	end
	return true
end

function PlayerDataHandler.GetEquippedArmor(player: Player)
	return {
		Helmet = getStat("EquippedHelmet", ProfileTemplate.EquippedHelmet, player),
		Chestplate = getStat("EquippedChestplate", ProfileTemplate.EquippedChestplate, player),
		Leggings = getStat("EquippedLeggings", ProfileTemplate.EquippedLeggings, player),
		Boots = getStat("EquippedBoots", ProfileTemplate.EquippedBoots, player),
	}
end

function PlayerDataHandler.GetEquippedBootsItemName(player: Player): string
	local bootsEntryId = getStat("EquippedBoots", ProfileTemplate.EquippedBoots, player)
	if type(bootsEntryId) ~= "string" or bootsEntryId == "" then
		return ""
	end

	return PlayerDataHandler.ResolveInventoryEntryItemName(player, bootsEntryId)
end

function PlayerDataHandler.ApplyPlayerMoveSpeed(player: Player)
	local character = player.Character
	if character == nil then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end

	local bootsItemName = PlayerDataHandler.GetEquippedBootsItemName(player)
	humanoid.WalkSpeed = StatCalculation.GetPlayerMoveSpeed(bootsItemName ~= "" and bootsItemName or nil)
end

function PlayerDataHandler.ClearEquippedGear(player: Player, slot: string)
	if not GearConfig.IsArmorSlot(slot) then
		return false
	end

	local fieldName = "Equipped" .. slot
	if ProfileTemplate[fieldName] == nil then
		return false
	end

	setStat(fieldName, "", player)
	sanitizeHotbarData(player)
	if slot == "Boots" then
		PlayerDataHandler.ApplyPlayerMoveSpeed(player)
	end
	return true
end

function PlayerDataHandler.GetHotbarSlots(player: Player): {string}
	return normalizeHotbarSlots(getStat("HotbarSlots", ProfileTemplate.HotbarSlots, player))
end

function PlayerDataHandler.SetHotbarSlots(player: Player, slotValues: {string})
	setStat("HotbarSlots", buildStoredHotbarSlots(slotValues), player)
	sanitizeHotbarData(player)
end

function PlayerDataHandler.AssignHotbarEntry(player: Player, slotIndex: number, entryId: string): boolean
	if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > HotbarConfig.MAX_SLOTS then
		return false
	end
	if type(entryId) ~= "string" then
		return false
	end

	local snapshot = getPlayerDataSnapshot(player)
	if not HotbarConfig.IsEntryAvailable(entryId, snapshot) then
		return false
	end

	local slots = PlayerDataHandler.GetHotbarSlots(player)
	local previousEntryId = slots[slotIndex] or ""
	for index, existingEntryId in ipairs(slots) do
		if existingEntryId == entryId then
			slots[index] = ""
		end
	end

	slots[slotIndex] = entryId
	PlayerDataHandler.SetHotbarSlots(player, slots)

	local selectedSlot = PlayerDataHandler.GetSelectedHotbarSlot(player)
	if selectedSlot == slotIndex and previousEntryId ~= "" and previousEntryId ~= entryId then
		PlayerDataHandler.SetSelectedHotbarSlot(player, 0)
	end

	return true
end

function PlayerDataHandler.ClearHotbarSlot(player: Player, slotIndex: number): boolean
	if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > HotbarConfig.MAX_SLOTS then
		return false
	end

	local slots = PlayerDataHandler.GetHotbarSlots(player)
	slots[slotIndex] = ""
	PlayerDataHandler.SetHotbarSlots(player, slots)

	return true
end

function PlayerDataHandler.GetSelectedHotbarSlot(player: Player): number
	local value = getStat("SelectedHotbarSlot", 0, player)
	if type(value) ~= "number" then
		return 0
	end
	return value
end

function PlayerDataHandler.SetSelectedHotbarSlot(player: Player, slotIndex: number): boolean
	if type(slotIndex) ~= "number" then
		return false
	end

	if slotIndex == 0 then
		setStat("SelectedHotbarSlot", 0, player)
		return true
	end

	local slots = PlayerDataHandler.GetHotbarSlots(player)
	if slotIndex < 1 or slotIndex > HotbarConfig.MAX_SLOTS or slots[slotIndex] == "" then
		return false
	end

	setStat("SelectedHotbarSlot", slotIndex, player)
	return true
end

-- Mine progression
function PlayerDataHandler.UnlockCheckpoint(player: Player, floor: number)
	local checkpoints = getStat("UnlockedCheckpoints", {}, player)
	for _, entry in pairs(checkpoints) do
		if entry.name == tostring(floor) then
			return -- Already unlocked
		end
	end
	table.insert(checkpoints, {name = tostring(floor), value = true})
	setStat("UnlockedCheckpoints", checkpoints, player)
end

function PlayerDataHandler.HasUnlockedCheckpoint(player: Player, floor: number, includeFloorOne: boolean?): boolean
	if includeFloorOne == true and floor == 1 then
		return true
	end

	local checkpoints = getStat("UnlockedCheckpoints", {}, player)
	for _, entry in pairs(checkpoints) do
		if entry.name == tostring(floor) and entry.value == true then
			return true
		end
	end

	return false
end

function PlayerDataHandler.SetMaxFloorReached(player: Player, floor: number)
	local current = getStat("MaxFloorReached", 0, player)
	if floor > current then
		setStat("MaxFloorReached", floor, player)
	end
end

function PlayerDataHandler.GetMaxFloorReached(player: Player): number
	return getStat("MaxFloorReached", 0, player)
end

function PlayerDataHandler.HasOpenedMineChest(player: Player, floor: number): boolean
	local openedMineChests = getStat("OpenedMineChests", {}, player)
	for _, entry in pairs(openedMineChests) do
		if entry.name == tostring(floor) then
			return entry.value == true
		end
	end

	return false
end

function PlayerDataHandler.MarkMineChestOpened(player: Player, floor: number): boolean
	if PlayerDataHandler.HasOpenedMineChest(player, floor) then
		return false
	end

	local openedMineChests = getStat("OpenedMineChests", {}, player)
	table.insert(openedMineChests, {
		name = tostring(floor),
		value = true,
	})
	setStat("OpenedMineChests", openedMineChests, player)

	return true
end

-- Temp stats (session-only)
function PlayerDataHandler.SetCurrentFloor(player: Player, floor: number)
	local valueInstance = TempStats:GetTempStat(player, "CurrentFloor")
	if valueInstance then
		valueInstance.Value = floor
	end
end

function PlayerDataHandler.GetCurrentFloor(player: Player): number
	local valueInstance = TempStats:GetTempStat(player, "CurrentFloor")
	if valueInstance then
		return valueInstance.Value
	end
	return 0
end

function PlayerDataHandler.SetInMine(player: Player, value: boolean)
	local valueInstance = TempStats:GetTempStat(player, "InMine")
	if valueInstance then
		valueInstance.Value = value
	end
end

function PlayerDataHandler.GetInMine(player: Player): boolean
	local valueInstance = TempStats:GetTempStat(player, "InMine")
	if valueInstance then
		return valueInstance.Value
	end
	return false
end

function PlayerDataHandler.SetActiveTheme(player: Player, themeName: string)
	local valueInstance = TempStats:GetTempStat(player, "ActiveTheme")
	if valueInstance then
		valueInstance.Value = themeName
	end
end

function PlayerDataHandler.GetActiveTheme(player: Player): string
	local valueInstance = TempStats:GetTempStat(player, "ActiveTheme")
	if valueInstance then
		return valueInstance.Value
	end
	return "default"
end

-- Tutorials
function PlayerDataHandler.GetTutorialIsCompleted(player: Player, tutorialName: string)
	local tutorialStates = getStat("TutorialStates", ProfileTemplate.TutorialStates, player)
	for _, entry in pairs(tutorialStates) do
		local name = entry.name
		local completed = entry.value
		if name == tutorialName then
			return completed
		end
	end
end

function PlayerDataHandler.CompleteTutorial(player: Player, tutorialName: string, tutorialRewards)
	local tutorialStates = getStat("TutorialStates", ProfileTemplate.TutorialStates, player)
	local foundTutorialState = false
	for i, entry in pairs(tutorialStates) do
		local name = entry.name
		if name == tutorialName then
			tutorialStates[i] = {name = tutorialName, value = true}
			foundTutorialState = true
			break
		end
	end

	if not foundTutorialState then
		table.insert(tutorialStates, {name = tutorialName, value = true})
	end

	setStat("TutorialStates", tutorialStates, player)

	if tutorialRewards == nil then
		return
	end

	local coinReward = tutorialRewards.Coins
	if type(coinReward) == "number" and coinReward > 0 then
		PlayerDataHandler.GiveCoins(player, coinReward)
	end
end

game.Players.PlayerAdded:Connect(initializeClient)

for _, player in pairs(game.Players:GetChildren()) do
	initializeClient(player)
end

return PlayerDataHandler
