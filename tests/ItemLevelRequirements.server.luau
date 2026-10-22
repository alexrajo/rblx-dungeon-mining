-- Run in a local server playtest runner after player data and the character load.
-- Returns a check summary; test player data is restored even when an assertion fails.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

assert(RunService:IsStudio() and RunService:IsRunning(), "Run in a Studio playtest")
local player = assert(Players:GetPlayers()[1], "A test player must be connected")
local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local client = assert(PlayerDataHandler.GetClient(player), "Wait for player data to load")
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local ItemLookupService = require(ReplicatedStorage.services.ItemLookupService)
local ItemLevelService = require(modules.ItemLevelService)
local HotbarToolValidator = require(modules.HotbarToolValidator)
local endpoints = modules.api_endpoints

local function cloneDeep(value: any): any
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, child in pairs(value) do copy[key] = cloneDeep(child) end
	return copy
end

local fields = { "Inventory", "Level", "Coins", "HotbarSlots", "SelectedHotbarSlot",
	"EquippedHelmet", "EquippedChestplate", "EquippedLeggings", "EquippedBoots" }
local original = {}
for _, field in ipairs(fields) do original[field] = cloneDeep(client:GetDataValue(field)) end
local humanoid = assert(player.Character and player.Character:FindFirstChildOfClass("Humanoid"))
local originalHealth = humanoid.Health
local tools = {}
local checks = 0

local function check(condition: boolean, message: string)
	assert(condition, message)
	checks += 1
end

local function setLevel(level: number)
	client:SetDataValue("Level", level)
end

local function checkFailure(result, requiredLevel: number, currentLevel: number)
	check(type(result) == "table" and result.success == false and result.reason == "level_required"
		and result.requiredLevel == requiredLevel and result.currentLevel == currentLevel,
		"Expected a structured level denial")
end

local ok, failure = xpcall(function()
	local inventory = {}
	local entryIds = {}
	for itemName in pairs(ItemConfig.items) do
		local entryId = ItemConfig.IsStackable(itemName) and itemName or "level-test-" .. tostring(#inventory + 1)
		entryIds[itemName] = entryId
		table.insert(inventory, ItemConfig.IsStackable(itemName)
			and { name = itemName, value = 3 } or { id = entryId, name = itemName })
	end
	client:SetDataValue("Inventory", inventory)
	for _, slot in ipairs({ "Helmet", "Chestplate", "Leggings", "Boots" }) do
		client:SetDataValue("Equipped" .. slot, "")
	end
	PlayerDataHandler.SetHotbarSlots(player, {})
	client:SetDataValue("SelectedHotbarSlot", 0)

	local expectedTiers = { Wood = 1, Copper = 3, Iron = 6, Gold = 10, Diamond = 15, Obsidian = 20 }
	local expectedOther = { ["Mini Bomb"] = 1, ["Big Bomb"] = 6, ["Mega Bomb"] = 12,
		["Health Potion"] = 1, ["Speed Potion"] = 5, ["Strength Potion"] = 5 }
	check(ItemConfig.GetRequiredLevel("Stone") == 1 and ItemConfig.GetRequiredLevel(nil) == 1, "Default level")
	check(not PlayerDataHandler.AssignHotbarEntry(player, 1, "nonexistent-id"), "Ownership checks remain active")

	for itemName, data in pairs(ItemConfig.items) do
		local required = expectedOther[itemName] or expectedTiers[string.match(itemName, "^(%w+)")]
		check(data.requiredLevel == required, "Configured requirement: " .. itemName)
		check(ItemLookupService.GetItemDefinitionFromName(itemName).requiredLevel == required, "Lookup requirement")
		check(not ItemConfig.MeetsLevelRequirement(itemName, required - 1)
			and ItemConfig.MeetsLevelRequirement(itemName, required)
			and ItemConfig.MeetsLevelRequirement(itemName, required + 1), "Shared boundary checks")

		local entryId = entryIds[itemName]
		setLevel(required - 1)
		checkFailure(ItemLevelService.Check(player, itemName), required, required - 1)
		if GearConfig.IsArmorSlot(data.slot) then
			check(not PlayerDataHandler.EquipGear(player, entryId, data.slot), "Locked armor")
			check(not require(endpoints.EquipGear).Call(player, entryId), "Locked armor endpoint")
		else
			check(not PlayerDataHandler.AssignHotbarEntry(player, 1, entryId), "Locked hotbar assignment")
			check(not require(endpoints.AssignHotbarSlot).Call(player, 1, entryId), "Locked assignment endpoint")
		end

		for _, level in ipairs({ required, required + 1 }) do
			setLevel(level)
			if GearConfig.IsArmorSlot(data.slot) then
				check(require(endpoints.EquipGear).Call(player, entryId), "Eligible armor")
			else
				check(require(endpoints.AssignHotbarSlot).Call(player, 1, entryId), "Eligible hotbar assignment")
				check(require(endpoints.SelectHotbarSlot).Call(player, 1), "Eligible hotbar selection")
			end
		end

		if HotbarConfig.IsEntryHotbarEligible(itemName) then
			-- Simulate a stale/forged selection to exercise the action checks directly.
			setLevel(required - 1)
			check(not PlayerDataHandler.SetSelectedHotbarSlot(player, 1), "Locked selection")
			check(not require(endpoints.SelectHotbarSlot).Call(player, 1), "Locked selection endpoint")
			local beforeCount = PlayerDataHandler.GetItemCount(player, itemName)
			if data.slot == "Pickaxe" or data.slot == "Weapon" then
				local tool = Instance.new("Tool")
				table.insert(tools, tool)
				tool.RequiresHandle = false
				tool:SetAttribute("HotbarSlot", 1)
				tool:SetAttribute("HotbarEntryId", entryId)
				tool:SetAttribute("HotbarItemName", itemName)
				local action = HotbarConfig.GetActionName(itemName)
				tool:SetAttribute("HotbarActionName", action)
				tool.Parent = player.Character
				local valid, _, _, levelFailure = HotbarToolValidator.Validate(player, tool, action, data.slot)
				check(not valid, "Locked tool validator")
				checkFailure(levelFailure, required, required - 1)
				local endpointResult = data.slot == "Pickaxe" and require(endpoints.Mine).Call(player, tool, nil, Vector3.zero)
					or require(endpoints.Attack).Call(player, tool, {})
				checkFailure(endpointResult, required, required - 1)
				setLevel(required)
				check(HotbarToolValidator.Validate(player, tool, action, data.slot), "Unlocked tool validator")
				tool:Destroy()
			elseif data.slot == "Bomb" then
				checkFailure(require(endpoints.UseBomb).Call(player), required, required - 1)
			else
				checkFailure(require(endpoints.UseConsumable).Call(player), required, required - 1)
			end
			check(PlayerDataHandler.GetItemCount(player, itemName) == beforeCount, "Denial must not consume items")
		end
	end

	setLevel(1)
	client:SetDataValue("Coins", 100)
	local beforeBombs = PlayerDataHandler.GetItemCount(player, "Mega Bomb")
	check(require(endpoints.BuyItems).Call(player, "GearShop", {{ name = "Mega Bomb", quantity = 1 }}).success,
		"Can buy above player level")
	check(PlayerDataHandler.GetItemCount(player, "Mega Bomb") == beforeBombs + 1, "Purchase granted")
	PlayerDataHandler.GiveItems(player, { Iron = 10, Wood = 3 })
	local beforePickaxes = PlayerDataHandler.GetItemCount(player, "Iron Pickaxe")
	check(require(endpoints.Craft).Call(player, "Iron Pickaxe"), "Can craft above player level")
	check(PlayerDataHandler.GetItemCount(player, "Iron Pickaxe") == beforePickaxes + 1, "Craft granted")
	check(not require(endpoints.AssignHotbarSlot).Call(player, 1, "Mega Bomb"), "Acquisition does not unlock use")

	check(PlayerDataHandler.AssignHotbarEntry(player, 1, "Health Potion"), "Starter consumable assignment")
	check(PlayerDataHandler.SetSelectedHotbarSlot(player, 1), "Starter consumable selection")
	humanoid.Health = math.max(1, humanoid.MaxHealth - 50)
	local beforeHealth = humanoid.Health
	local beforePotions = PlayerDataHandler.GetItemCount(player, "Health Potion")
	check(require(endpoints.UseConsumable).Call(player).success, "Level 1 potion use")
	check(humanoid.Health > beforeHealth and PlayerDataHandler.GetItemCount(player, "Health Potion") == beforePotions - 1,
		"Potion effects and consumption")
end, debug.traceback)

for _, tool in ipairs(tools) do tool:Destroy() end
for _, field in ipairs(fields) do client:SetDataValue(field, original[field]) end
humanoid.Health = originalHealth
PlayerDataHandler.ApplyPlayerMoveSpeed(player)
assert(ok, failure)
return { passed = checks, items = 42, playerDataRestored = true }
