local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local ProfileService = require(Services.ProfileService)
local DatabaseClientClass = require(game.ServerScriptService.modules.DatabaseClient)
local ProfileTemplate = require(script.ProfileTemplate)
local TempStats = require(script.TempStats)
local ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)
local APIService = require(Services.APIService)

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

local PlayerDataFolder = Instance.new("Folder")
PlayerDataFolder.Name = "PlayerData"
PlayerDataFolder.Parent = ReplicatedStorage

local dbClients = {}

local function handleRelease(player, client)
	dbClients[player] = nil
	player:Kick()
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
end

game.Players.PlayerAdded:Connect(initializeClient)

-- Initialize dbClients if not caught by playerAdded event
for _, player in pairs(game.Players:GetChildren()) do
	initializeClient(player)
end

local PlayerDataHandler = {}

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
	for i, item in pairs(ownedItems) do
		local itemName = item.name
		local itemAmount = item.value

		local amountToGive = itemsMap[itemName]
		if amountToGive ~= nil then
			ownedItems[i] = {name = itemName, value = itemAmount + amountToGive}
			itemsMap[itemName] = nil
		end
	end
	for itemName, itemAmount in pairs(itemsMap) do
		if itemAmount == nil then continue end
		table.insert(ownedItems, {name = itemName, value = itemAmount})
	end
	setStat("Inventory", ownedItems, player)
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
end

function PlayerDataHandler.GetEquippedGear(player: Player)
	return {
		Pickaxe = getStat("EquippedPickaxe", ProfileTemplate.EquippedPickaxe, player),
		Weapon = getStat("EquippedWeapon", ProfileTemplate.EquippedWeapon, player),
		Helmet = getStat("EquippedHelmet", ProfileTemplate.EquippedHelmet, player),
		Chestplate = getStat("EquippedChestplate", ProfileTemplate.EquippedChestplate, player),
		Boots = getStat("EquippedBoots", ProfileTemplate.EquippedBoots, player),
	}
end

function PlayerDataHandler.GetEquippedPickaxe(player: Player): string
	return getStat("EquippedPickaxe", ProfileTemplate.EquippedPickaxe, player)
end

function PlayerDataHandler.GetEquippedWeapon(player: Player): string
	return getStat("EquippedWeapon", ProfileTemplate.EquippedWeapon, player)
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
	for i, entry in pairs(tutorialStates) do
		local name = entry.name
		if name == tutorialName then
			tutorialStates[i] = {name = tutorialName, value = true}
			break
		end
	end
	setStat("TutorialStates", tutorialStates, player)
end

return PlayerDataHandler
