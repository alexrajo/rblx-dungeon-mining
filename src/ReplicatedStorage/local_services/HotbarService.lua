local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local APIService = require(ReplicatedStorage.services.APIService)
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)

local player = Players.LocalPlayer
local selectHotbarSlotEvent = APIService.GetEvent("SelectHotbarSlot")

local HotbarService = {}

local state = {
	slots = table.create(HotbarConfig.MAX_SLOTS, ""),
	selectedSlot = 0,
}

local changeCallbacks = {}
local initialized = false
local pendingSelectedSlot = 0
local pendingServerSelectedSlot: number? = nil

local function emitChanged()
	for _, callback in ipairs(changeCallbacks) do
		callback(state)
	end
end

local function setState(nextSlots: {string}?, nextSelectedSlot: number?)
	local changed = false

	if nextSlots ~= nil then
		for index = 1, HotbarConfig.MAX_SLOTS do
			local nextValue = nextSlots[index] or ""
			if state.slots[index] ~= nextValue then
				state.slots[index] = nextValue
				changed = true
			end
		end
	end

	if nextSelectedSlot ~= nil and state.selectedSlot ~= nextSelectedSlot then
		state.selectedSlot = nextSelectedSlot
		changed = true
	end

	if changed then
		emitChanged()
	end
end

local function getHumanoid(): Humanoid?
	local character = player.Character
	if character == nil then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getToolForSlot(slotIndex: number): Tool?
	local expectedItemName = state.slots[slotIndex]
	if expectedItemName == nil or expectedItemName == "" then
		return nil
	end

	local function findInContainer(container: Instance?): Tool?
		if container == nil then
			return nil
		end

		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool")
				and child:GetAttribute("HotbarSlot") == slotIndex
				and child:GetAttribute("HotbarItemName") == expectedItemName
			then
				return child
			end
		end

		return nil
	end

	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	return findInContainer(character) or findInContainer(backpack)
end

local function unequipLocalTools()
	local humanoid = getHumanoid()
	if humanoid ~= nil then
		humanoid:UnequipTools()
	end
end

local function equipLocalSlot(slotIndex: number): boolean
	if slotIndex == 0 then
		pendingSelectedSlot = 0
		unequipLocalTools()
		return true
	end

	local humanoid = getHumanoid()
	if humanoid == nil then
		pendingSelectedSlot = slotIndex
		return false
	end

	local tool = getToolForSlot(slotIndex)
	if tool == nil then
		pendingSelectedSlot = slotIndex
		return false
	end

	pendingSelectedSlot = 0
	humanoid:EquipTool(tool)
	return true
end

local function retryPendingEquip()
	if pendingSelectedSlot == 0 then
		return
	end

	if state.selectedSlot ~= pendingSelectedSlot then
		pendingSelectedSlot = 0
		return
	end

	equipLocalSlot(pendingSelectedSlot)
end

local function sendSelectedSlot(slotIndex: number)
	pendingServerSelectedSlot = slotIndex
	selectHotbarSlotEvent:FireServer(slotIndex)
end

local function initialize()
	if initialized then
		return
	end
	initialized = true

	local playerData = ReplicatedStorage:WaitForChild("PlayerData")
	local myData = playerData:WaitForChild(player.Name)
	local hotbarSlotsFolder = myData:WaitForChild("HotbarSlots")
	local selectedHotbarSlotValue = myData:WaitForChild("SelectedHotbarSlot")

	local function updateSlots()
		local slotEntries = {}
		for _, child in ipairs(hotbarSlotsFolder:GetChildren()) do
			if child:IsA("ValueBase") then
				table.insert(slotEntries, {name = child.Name, value = child.Value})
			end
		end
		setState(HotbarConfig.NormalizeStoredSlots(slotEntries))

		if state.selectedSlot ~= 0 and state.slots[state.selectedSlot] == "" then
			pendingSelectedSlot = 0
			unequipLocalTools()
			setState(nil, 0)
		else
			retryPendingEquip()
		end
	end

	local function updateSelectedSlot()
		local selectedSlot = selectedHotbarSlotValue.Value
		if type(selectedSlot) ~= "number" then
			selectedSlot = 0
		end

		if pendingServerSelectedSlot ~= nil then
			if selectedSlot ~= pendingServerSelectedSlot then
				return
			end
			pendingServerSelectedSlot = nil
		end

		if selectedSlot ~= 0 and state.slots[selectedSlot] == "" then
			selectedSlot = 0
		end

		equipLocalSlot(selectedSlot)
		setState(nil, selectedSlot)
	end

	hotbarSlotsFolder.ChildAdded:Connect(updateSlots)
	hotbarSlotsFolder.ChildRemoved:Connect(updateSlots)
	for _, child in ipairs(hotbarSlotsFolder:GetChildren()) do
		if child:IsA("ValueBase") then
			child.Changed:Connect(updateSlots)
		end
	end
	hotbarSlotsFolder.ChildAdded:Connect(function(child)
		if child:IsA("ValueBase") then
			child.Changed:Connect(updateSlots)
		end
	end)

	selectedHotbarSlotValue.Changed:Connect(updateSelectedSlot)

	local backpack = player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			retryPendingEquip()
		end
	end)

	local function connectCharacter(character: Model)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				retryPendingEquip()
			end
		end)

		task.defer(function()
			if state.selectedSlot ~= 0 then
				equipLocalSlot(state.selectedSlot)
			end
		end)
	end

	if player.Character then
		connectCharacter(player.Character)
	end
	player.CharacterAdded:Connect(connectCharacter)

	updateSlots()
	updateSelectedSlot()
end

function HotbarService.GetState()
	initialize()
	return {
		slots = table.clone(state.slots),
		selectedSlot = state.selectedSlot,
	}
end

function HotbarService.GetSlots(): {string}
	initialize()
	return table.clone(state.slots)
end

function HotbarService.GetSelectedSlot(): number
	initialize()
	return state.selectedSlot
end

function HotbarService.GetSelectedEntryId(): string
	initialize()
	if state.selectedSlot < 1 or state.selectedSlot > HotbarConfig.MAX_SLOTS then
		return ""
	end
	return state.slots[state.selectedSlot] or ""
end

function HotbarService.SelectSlot(slotIndex: number)
	initialize()
	if slotIndex == state.selectedSlot then
		if slotIndex ~= 0 then
			equipLocalSlot(0)
			setState(nil, 0)
			sendSelectedSlot(0)
		end
		return
	end

	if slotIndex ~= 0 and state.slots[slotIndex] == "" then
		return
	end

	equipLocalSlot(slotIndex)
	setState(nil, slotIndex)
	sendSelectedSlot(slotIndex)
end

function HotbarService.SyncSelectedSlot(slotIndex: number)
	initialize()
	if type(slotIndex) ~= "number" then
		return
	end
	if slotIndex ~= 0 and state.slots[slotIndex] == "" then
		return
	end
	if state.selectedSlot == slotIndex then
		return
	end

	equipLocalSlot(slotIndex)
	setState(nil, slotIndex)
	sendSelectedSlot(slotIndex)
end

function HotbarService.FindNextFilledSlot(direction: number): number
	initialize()
	local startSlot = state.selectedSlot
	if startSlot == 0 then
		startSlot = direction > 0 and 0 or HotbarConfig.MAX_SLOTS + 1
	end

	for offset = 1, HotbarConfig.MAX_SLOTS do
		local candidate = ((startSlot - 1 + direction * offset) % HotbarConfig.MAX_SLOTS) + 1
		if state.slots[candidate] ~= "" then
			return candidate
		end
	end

	return 0
end

function HotbarService.OnChanged(callback: ({slots: {string}, selectedSlot: number}) -> ()): () -> ()
	initialize()
	table.insert(changeCallbacks, callback)
	return function()
		for index, existingCallback in ipairs(changeCallbacks) do
			if existingCallback == callback then
				table.remove(changeCallbacks, index)
				break
			end
		end
	end
end

return HotbarService
