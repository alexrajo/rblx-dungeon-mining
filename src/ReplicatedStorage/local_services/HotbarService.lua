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
	end

	local function updateSelectedSlot()
		setState(nil, selectedHotbarSlotValue.Value)
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
			selectHotbarSlotEvent:FireServer(0)
			setState(nil, 0)
		end
		return
	end

	if slotIndex ~= 0 and state.slots[slotIndex] == "" then
		return
	end

	selectHotbarSlotEvent:FireServer(slotIndex)
	setState(nil, slotIndex)
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

	selectHotbarSlotEvent:FireServer(slotIndex)
	setState(nil, slotIndex)
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
