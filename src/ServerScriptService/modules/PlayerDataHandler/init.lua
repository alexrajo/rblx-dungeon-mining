local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local migrateHotbarData

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
		EquippedPickaxe = getStat("EquippedPickaxe", ProfileTemplate.EquippedPickaxe, player),
		EquippedWeapon = getStat("EquippedWeapon", ProfileTemplate.EquippedWeapon, player),
		EquippedHelmet = getStat("EquippedHelmet", ProfileTemplate.EquippedHelmet, player),
		EquippedChestplate = getStat("EquippedChestplate", ProfileTemplate.EquippedChestplate, player),
		EquippedLeggings = getStat("EquippedLeggings", ProfileTemplate.EquippedLeggings, player),
		EquippedBoots = getStat("EquippedBoots", ProfileTemplate.EquippedBoots, player),
	}
end

local function getFirstAvailableHotbarSlot(slotValues: {string}, playerData): number
	for index, entryId in ipairs(slotValues) do
		if entryId ~= "" and HotbarConfig.IsEntryAvailable(entryId, playerData) then
			return index
		end
	end
	return 0
end

local function sanitizeHotbarData(player: Player)
	local playerData = getPlayerDataSnapshot(player)
	local slotValues = normalizeHotbarSlots(getStat("HotbarSlots", ProfileTemplate.HotbarSlots, player))
	local seenEntries: {[string]: boolean} = {}

	for index, entryId in ipairs(slotValues) do
		local isValid = entryId ~= ""
			and HotbarConfig.IsEntryHotbarEligible(entryId)
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
	if selectedSlot < 1 or selectedSlot > HotbarConfig.MAX_SLOTS or slotValues[selectedSlot] == "" then
		selectedSlot = getFirstAvailableHotbarSlot(slotValues, playerData)
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
	migrateHotbarData(player)
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

function PlayerDataHandler.MigrateHotbarData(player: Player)
	local version = getStat("HotbarVersion", 0, player)
	if version < HotbarConfig.CURRENT_VERSION then
		local snapshot = getPlayerDataSnapshot(player)
		local defaultSlots = HotbarConfig.GetDefaultSlotsForPlayerData(snapshot)
		setStat("HotbarSlots", buildStoredHotbarSlots(defaultSlots), player)
		setStat("SelectedHotbarSlot", getFirstAvailableHotbarSlot(defaultSlots, snapshot), player)
		setStat("HotbarVersion", HotbarConfig.CURRENT_VERSION, player)
	end

	sanitizeHotbarData(player)
end

migrateHotbarData = PlayerDataHandler.MigrateHotbarData

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

-- Inventory (ores, resources, consumables)
function PlayerDataHandler.GiveItems(player: Player, itemsMap: {[string]: number})
	if next(itemsMap) == nil then return end
	local ownedItems = getStat("Inventory", {}, player)
	local pendingItems = table.clone(itemsMap)
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
		if ownedItems[index].value <= 0 then
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

function PlayerDataHandler.GetInventory(player: Player)
	return getStat("Inventory", ProfileTemplate.Inventory, player)
end

function PlayerDataHandler.GetItemCount(player: Player, itemName: string): number
	local inventory = PlayerDataHandler.GetInventory(player)
	for _, entry in pairs(inventory) do
		if entry.name == itemName then
			return entry.value
		end
	end
	return 0
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
function PlayerDataHandler.EquipGear(player: Player, itemName: string, slot: string)
	local fieldName = "Equipped" .. slot
	setStat(fieldName, itemName, player)
	sanitizeHotbarData(player)
end

function PlayerDataHandler.GetEquippedGear(player: Player)
	return {
		Pickaxe = getStat("EquippedPickaxe", ProfileTemplate.EquippedPickaxe, player),
		Weapon = getStat("EquippedWeapon", ProfileTemplate.EquippedWeapon, player),
		Helmet = getStat("EquippedHelmet", ProfileTemplate.EquippedHelmet, player),
		Chestplate = getStat("EquippedChestplate", ProfileTemplate.EquippedChestplate, player),
		Leggings = getStat("EquippedLeggings", ProfileTemplate.EquippedLeggings, player),
		Boots = getStat("EquippedBoots", ProfileTemplate.EquippedBoots, player),
	}
end

function PlayerDataHandler.GetEquippedPickaxe(player: Player): string
	return getStat("EquippedPickaxe", ProfileTemplate.EquippedPickaxe, player)
end

function PlayerDataHandler.GetEquippedWeapon(player: Player): string
	return getStat("EquippedWeapon", ProfileTemplate.EquippedWeapon, player)
end

function PlayerDataHandler.ClearEquippedGear(player: Player, slot: string)
	local fieldName = "Equipped" .. slot
	if ProfileTemplate[fieldName] == nil then
		return false
	end

	setStat(fieldName, "", player)
	sanitizeHotbarData(player)
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
	if type(entryId) ~= "string" or not HotbarConfig.IsEntryHotbarEligible(entryId) then
		return false
	end

	local snapshot = getPlayerDataSnapshot(player)
	if not HotbarConfig.IsEntryAvailable(entryId, snapshot) then
		return false
	end

	local slots = PlayerDataHandler.GetHotbarSlots(player)
	for index, existingEntryId in ipairs(slots) do
		if existingEntryId == entryId then
			slots[index] = ""
		end
	end

	slots[slotIndex] = entryId
	PlayerDataHandler.SetHotbarSlots(player, slots)
	return true
end

function PlayerDataHandler.ClearHotbarSlot(player: Player, slotIndex: number): boolean
	if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > HotbarConfig.MAX_SLOTS then
		return false
	end

	local slots = PlayerDataHandler.GetHotbarSlots(player)
	local entryId = slots[slotIndex] or ""
	slots[slotIndex] = ""
	PlayerDataHandler.SetHotbarSlots(player, slots)

	local equipmentSlot = GearConfig.GetSlotForItem(entryId)
	local fieldName = equipmentSlot and ("Equipped" .. equipmentSlot) or nil
	if fieldName ~= nil and getStat(fieldName, "", player) == entryId then
		setStat(fieldName, "", player)
	end

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

function PlayerDataHandler.SetMaxFloorReached(player: Player, floor: number)
	local current = getStat("MaxFloorReached", 0, player)
	if floor > current then
		setStat("MaxFloorReached", floor, player)
	end
end

function PlayerDataHandler.GetMaxFloorReached(player: Player): number
	return getStat("MaxFloorReached", 0, player)
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
