local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local BombConfig = require(ReplicatedStorage.configs.BombConfig)
local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)

local SLOT_TO_FOLDER: {[string]: string} = {
	Pickaxe = "Pickaxes",
	Weapon = "Weapons",
}

type PlayerState = {
	tools: {[number]: Tool?},
	entryIds: {[number]: string?},
	syncQueued: boolean,
}

local playerStates: {[Player]: PlayerState} = {}

local ToolEquipHandler = {}

local function getToolFolderName(itemName: string): string?
	if BombConfig.IsBombItem(itemName) then
		return "Bombs"
	end

	local equipmentSlot = GearConfig.GetSlotForItem(itemName)
	if equipmentSlot == nil then
		return nil
	end

	return SLOT_TO_FOLDER[equipmentSlot]
end

local function getToolTemplate(itemName: string): Tool?
	local folderName = getToolFolderName(itemName)
	if folderName == nil or itemName == "" then
		return nil
	end

	local toolsFolder = ServerStorage:FindFirstChild("Tools")
	if toolsFolder == nil then
		warn("ToolEquipHandler: ServerStorage.Tools folder not found")
		return nil
	end

	local slotFolder = toolsFolder:FindFirstChild(folderName)
	if slotFolder == nil then
		warn("ToolEquipHandler: ServerStorage.Tools." .. folderName .. " folder not found")
		return nil
	end

	local template = slotFolder:FindFirstChild(itemName)
	if template == nil then
		warn("ToolEquipHandler: Tool template '" .. itemName .. "' not found in " .. folderName)
		return nil
	end

	return template
end

local function destroyTool(state: PlayerState, slotIndex: number)
	local tool = state.tools[slotIndex]
	if tool then
		tool:Destroy()
		state.tools[slotIndex] = nil
	end
	state.entryIds[slotIndex] = nil
end

local function destroyAllTools(state: PlayerState)
	for slotIndex = 1, HotbarConfig.MAX_SLOTS do
		destroyTool(state, slotIndex)
	end
end

local function getBackpack(player: Player): Backpack?
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack ~= nil then
		return backpack
	end

	local child = player:FindFirstChild("Backpack")
	if child ~= nil and child:IsA("Backpack") then
		return child
	end

	return nil
end

local function cloneToolForSlot(player: Player, state: PlayerState, slotIndex: number, entryId: string, itemName: string): Tool?
	if itemName == nil or itemName == "" then
		return nil
	end

	local actionName = HotbarConfig.GetActionName(itemName)
	if actionName == nil then
		return nil
	end

	local template = getToolTemplate(itemName)
	if template == nil then
		return nil
	end

	local tool = template:Clone()
	tool.CanBeDropped = false
	tool:SetAttribute("HotbarSlot", slotIndex)
	tool:SetAttribute("HotbarEntryId", entryId)
	tool:SetAttribute("HotbarItemName", itemName)
	tool:SetAttribute("HotbarActionName", actionName)

	state.tools[slotIndex] = tool
	state.entryIds[slotIndex] = entryId
	return tool
end

local function syncToolsToHotbar(player: Player)
	local state = playerStates[player]
	if state == nil then
		return
	end

	local backpack = getBackpack(player)
	if backpack == nil then
		return
	end

	local hotbarSlots = PlayerDataHandler.GetHotbarSlots(player)
	local character = player.Character
	for slotIndex = 1, HotbarConfig.MAX_SLOTS do
		local entryId = hotbarSlots[slotIndex] or ""
		local itemName = entryId ~= "" and PlayerDataHandler.ResolveInventoryEntryItemName(player, entryId) or ""
		local existingTool = state.tools[slotIndex]
		local existingEntryId = state.entryIds[slotIndex]

		if itemName == "" or HotbarConfig.GetActionName(itemName) == nil then
			destroyTool(state, slotIndex)
			continue
		end

		if existingTool == nil or existingTool.Parent == nil or existingEntryId ~= entryId then
			destroyTool(state, slotIndex)
			existingTool = cloneToolForSlot(player, state, slotIndex, entryId, itemName)
		end

		if existingTool ~= nil and existingTool.Parent ~= backpack and existingTool.Parent ~= character then
			existingTool.Parent = backpack
		end
	end
end

local function queueSyncTools(player: Player)
	local state = playerStates[player]
	if state == nil then
		return
	end

	if state.syncQueued then
		return
	end

	state.syncQueued = true
	task.defer(function()
		local latestState = playerStates[player]
		if latestState == nil then
			return
		end

		latestState.syncQueued = false
		syncToolsToHotbar(player)
	end)
end

local function cleanup(player: Player)
	local state = playerStates[player]
	if state == nil then
		return
	end

	destroyAllTools(state)
	playerStates[player] = nil
end

local function onPlayerAdded(player: Player)
	local maxRetries = 300
	local n = 0
	while PlayerDataHandler.GetClient(player) == nil and n < maxRetries do
		n += 1
		task.wait(0.1)
	end

	if PlayerDataHandler.GetClient(player) == nil then
		warn("ToolEquipHandler: Player data not ready for", player.Name)
		return
	end

	playerStates[player] = {
		tools = {},
		entryIds = {},
		syncQueued = false,
	}

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		queueSyncTools(player)
	end)

	PlayerDataHandler.ListenToStatUpdate("HotbarSlots", player, function()
		queueSyncTools(player)
	end)

	if player.Character then
		queueSyncTools(player)
	end
end

function ToolEquipHandler.Initialize()
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(onPlayerAdded, player)
	end)

	Players.PlayerRemoving:Connect(cleanup)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
end

return ToolEquipHandler
