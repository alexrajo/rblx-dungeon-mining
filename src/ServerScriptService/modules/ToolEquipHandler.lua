local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)

local SLOT_TO_FOLDER: {[string]: string} = {
	Pickaxe = "Pickaxes",
	Weapon = "Weapons",
}

type PlayerState = {
	tools: {[number]: Tool?},
}

local playerStates: {[Player]: PlayerState} = {}

local ToolEquipHandler = {}

local function getToolTemplate(equipmentSlot: string, itemName: string): Tool?
	local folderName = SLOT_TO_FOLDER[equipmentSlot]
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
end

local function destroyAllTools(state: PlayerState)
	for slotIndex = 1, HotbarConfig.MAX_SLOTS do
		destroyTool(state, slotIndex)
	end
end

local function cloneToolForSlot(player: Player, state: PlayerState, slotIndex: number)
	destroyTool(state, slotIndex)

	local hotbarSlots = PlayerDataHandler.GetHotbarSlots(player)
	local itemName = hotbarSlots[slotIndex]
	if itemName == nil or itemName == "" then
		return
	end

	local actionName = HotbarConfig.GetActionName(itemName)
	if actionName == nil then
		return
	end

	local equipmentSlot = GearConfig.GetSlotForItem(itemName)
	if equipmentSlot == nil then
		return
	end

	local template = getToolTemplate(equipmentSlot, itemName)
	if template == nil then
		return
	end

	local tool = template:Clone()
	tool.CanBeDropped = false
	tool:SetAttribute("HotbarSlot", slotIndex)
	tool:SetAttribute("HotbarItemName", itemName)
	tool:SetAttribute("HotbarActionName", actionName)

	state.tools[slotIndex] = tool
end

local function syncEquippedTool(player: Player)
	local state = playerStates[player]
	if state == nil then
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack") or player:FindFirstChild("Backpack")
	local character = player.Character
	if backpack == nil then
		return
	end

	for slotIndex = 1, HotbarConfig.MAX_SLOTS do
		local tool = state.tools[slotIndex]
		if tool and tool.Parent ~= backpack then
			tool.Parent = backpack
		end
	end

	if character == nil then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end

	local selectedSlot = PlayerDataHandler.GetSelectedHotbarSlot(player)
	if selectedSlot == 0 then
		humanoid:UnequipTools()
		return
	end

	local selectedTool = state.tools[selectedSlot]
	if selectedTool == nil then
		humanoid:UnequipTools()
		return
	end

	humanoid:EquipTool(selectedTool)
end

local function rebuildTools(player: Player)
	local state = playerStates[player]
	if state == nil then
		return
	end

	destroyAllTools(state)
	for slotIndex = 1, HotbarConfig.MAX_SLOTS do
		cloneToolForSlot(player, state, slotIndex)
	end
	syncEquippedTool(player)
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
	}

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		rebuildTools(player)
	end)

	PlayerDataHandler.ListenToStatUpdate("HotbarSlots", player, function()
		rebuildTools(player)
	end)

	PlayerDataHandler.ListenToStatUpdate("SelectedHotbarSlot", player, function()
		syncEquippedTool(player)
	end)

	PlayerDataHandler.ListenToStatUpdate("EquippedPickaxe", player, function()
		rebuildTools(player)
	end)

	PlayerDataHandler.ListenToStatUpdate("EquippedWeapon", player, function()
		rebuildTools(player)
	end)

	PlayerDataHandler.ListenToStatUpdate("Inventory", player, function()
		rebuildTools(player)
	end)

	if player.Character then
		rebuildTools(player)
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
