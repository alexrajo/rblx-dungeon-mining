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

function PlayerDataHandler.GiveBurpPoints(player: Player, amount: number)
	addToStat("BurpPoints", 0, player, amount)
end

function PlayerDataHandler.GiveCoins(player: Player, amount: number)
	addToStat("Coins", 0, player, amount)
end

function PlayerDataHandler.SetBurpCharge(player: Player, value: number)
	local valueInstance = TempStats:GetTempStat(player, "BurpCharge")
	if valueInstance then
		valueInstance.Value = value
	end
end

function PlayerDataHandler.ResetBurpCharge(player: Player)
	PlayerDataHandler.SetBurpCharge(player, 0)
end

function PlayerDataHandler.GetBurpCharge(player: Player)
	local valueInstance = TempStats:GetTempStat(player, "BurpCharge")
	if valueInstance then
		return valueInstance.Value
	end
	return 0
end

function PlayerDataHandler.GetBurpChargeThreshold(player: Player)
	local valueInstance = TempStats:GetTempStat(player, "BurpChargeThreshold")
	if valueInstance then
		return valueInstance.Value
	end
	return 0
end

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

function PlayerDataHandler.GiveIngredients(player, itemsMap)
	if next(itemsMap) == nil then return end -- If the table is empty, don't update stats
	local ownedItems = getStat("Ingredients", {}, player)
	for i, item in pairs(ownedItems) do
		local itemName = item.name
		local itemAmount = item.value
		
		local amountToGive = itemsMap[itemName]
		if amountToGive ~= nil then
			-- Give items from itemsMap
			ownedItems[i] = {name = itemName, value = itemAmount + amountToGive}
			itemsMap[itemName] = nil
		end
	end
	for itemName, itemAmount in pairs(itemsMap) do
		if itemAmount == nil then continue end
		
		table.insert(ownedItems, {name = itemName, value = itemAmount})
	end
	setStat("Ingredients", ownedItems, player)
end

function PlayerDataHandler.TakeIngredients(player, itemsMap)
	-- Give negative amount
	-- Flip the sign of all entries in the itemsMap
	local tblClone = table.clone(itemsMap)
	for i, v in pairs(tblClone) do
		tblClone[i] = -v
	end
	PlayerDataHandler.GiveIngredients(player, tblClone)
end

function PlayerDataHandler.GetEquippedDrink(player: Player)
	return getStat("EquippedDrink", ProfileTemplate.EquippedDrink, player)
end

function PlayerDataHandler.GetOwnedIngredients(player: Player)
	return getStat("Ingredients", ProfileTemplate.Ingredients, player)
end

function PlayerDataHandler.GiveDrink(player: Player, drinkName: string)
	local ownedDrinks = getStat("OwnedDrinks", ProfileTemplate.OwnedDrinks, player)
	local drinkAlreadyOwned = false
	for _, v in ipairs(ownedDrinks) do
		if v.name == drinkName then
			drinkAlreadyOwned = true
			break
		end
	end
	if drinkAlreadyOwned then return end
	
	table.insert(ownedDrinks, {name = drinkName, value = 0})
	print(ownedDrinks)
	setStat("OwnedDrinks", ownedDrinks, player)
end

-- Equip drink if it is owned
--[[
	returns: boolean - whether or not the drink was equipped
]]
function PlayerDataHandler.EquipDrink(player: Player, drinkName: string)
	local ownedDrinks = getStat("OwnedDrinks", ProfileTemplate.OwnedDrinks, player)
	for i, v in ipairs(ownedDrinks) do
		if v.name == drinkName then
			setStat("EquippedDrink", drinkName, player)
			return true
		end
	end
	return false
end

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
