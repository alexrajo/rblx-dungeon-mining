local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)

local ACTION_TO_SLOT: {[string]: string} = {
	Mine = "Pickaxe",
	Attack = "Weapon",
}

local SLOT_TO_FOLDER: {[string]: string} = {
	Pickaxe = "Pickaxes",
	Weapon = "Weapons",
}

local SLOT_TO_DATA_FIELD: {[string]: string} = {
	Pickaxe = "EquippedPickaxe",
	Weapon = "EquippedWeapon",
}

type PlayerState = {
	tools: { Pickaxe: Tool?, Weapon: Tool? },
	activeSlot: string,
}

local playerStates: {[Player]: PlayerState} = {}

local ToolEquipHandler = {}

local function getToolTemplate(slot: string, itemName: string): Tool?
	local folderName = SLOT_TO_FOLDER[slot]
	if folderName == nil then return nil end

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

local function destroyTool(state: PlayerState, slot: string)
	local tool = state.tools[slot]
	if tool then
		tool:Destroy()
		state.tools[slot] = nil
	end
end

local function cloneToolForSlot(player: Player, state: PlayerState, slot: string)
	destroyTool(state, slot)

	local dataField = SLOT_TO_DATA_FIELD[slot]
	if dataField == nil then return end

	local itemName: string
	if slot == "Pickaxe" then
		itemName = PlayerDataHandler.GetEquippedPickaxe(player)
	else
		itemName = PlayerDataHandler.GetEquippedWeapon(player)
	end

	local template = getToolTemplate(slot, itemName)
	if template == nil then return end

	local tool = template:Clone()
	state.tools[slot] = tool

	local character = player.Character
	if slot == state.activeSlot and character then
		tool.Parent = character
	end
end

local function giveTools(player: Player)
	local state = playerStates[player]
	if state == nil then return end

	-- Destroy any existing tools (e.g., from previous character)
	destroyTool(state, "Pickaxe")
	destroyTool(state, "Weapon")

	cloneToolForSlot(player, state, "Pickaxe")
	cloneToolForSlot(player, state, "Weapon")
end

local function setActiveSlot(player: Player, slot: string)
	local state = playerStates[player]
	if state == nil then return end
	if state.activeSlot == slot then return end

	local character = player.Character

	-- Unparent current active tool
	local currentTool = state.tools[state.activeSlot]
	if currentTool then
		currentTool.Parent = nil
	end

	-- Parent new active tool to character
	state.activeSlot = slot
	local newTool = state.tools[slot]
	if newTool and character then
		newTool.Parent = character
	end
end

local function cleanup(player: Player)
	local state = playerStates[player]
	if state == nil then return end

	destroyTool(state, "Pickaxe")
	destroyTool(state, "Weapon")
	playerStates[player] = nil
end

local function onPlayerAdded(player: Player)
	-- Wait for player data to be ready
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
		activeSlot = "Pickaxe",
	}

	-- Give tools when character spawns
	player.CharacterAdded:Connect(function()
		-- Small delay to ensure character is fully loaded
		task.wait(0.1)
		giveTools(player)
	end)

	-- Listen for equipped gear changes
	PlayerDataHandler.ListenToStatUpdate("EquippedPickaxe", player, function()
		local state = playerStates[player]
		if state == nil then return end
		cloneToolForSlot(player, state, "Pickaxe")
	end)

	PlayerDataHandler.ListenToStatUpdate("EquippedWeapon", player, function()
		local state = playerStates[player]
		if state == nil then return end
		cloneToolForSlot(player, state, "Weapon")
	end)

	-- If character already exists, give tools now
	if player.Character then
		giveTools(player)
	end
end

function ToolEquipHandler.SetActiveSlot(player: Player, actionName: string)
	local slot = ACTION_TO_SLOT[actionName]
	if slot == nil then
		warn("ToolEquipHandler: Unknown action name '" .. tostring(actionName) .. "'")
		return
	end
	setActiveSlot(player, slot)
end

function ToolEquipHandler.Initialize()
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(onPlayerAdded, player)
	end)

	Players.PlayerRemoving:Connect(cleanup)

	-- Handle players already in game
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
end

return ToolEquipHandler
