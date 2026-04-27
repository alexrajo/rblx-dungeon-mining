local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.modules.PlayerDataHandler)

local ARMOR_SLOTS = {
	"Helmet",
	"Chestplate",
	"Leggings",
	"Boots",
}

local DATA_READY_RETRIES = 300
local DATA_READY_WAIT = 0.1

type PlayerState = {
	slotModels: {[string]: Model?},
	syncQueued: boolean,
	connections: {RBXScriptConnection},
}

local playerStates: {[Player]: PlayerState} = {}

local ArmorAttachmentService = {}

local function warnPrefix(message: string, ...: any)
	warn("ArmorAttachmentService: " .. message, ...)
end

local function getArmorFolder(): Folder?
	local armorFolder = ServerStorage:FindFirstChild("Armor")
	if armorFolder == nil then
		warnPrefix("ServerStorage.Armor folder not found")
		return nil
	end
	if not armorFolder:IsA("Folder") then
		warnPrefix("ServerStorage.Armor is not a Folder")
		return nil
	end
	return armorFolder
end

local function getArmorTemplate(itemName: string): Model?
	local armorFolder = getArmorFolder()
	if armorFolder == nil then
		return nil
	end

	local template = armorFolder:FindFirstChild(itemName)
	if template == nil then
		warnPrefix("Armor model '" .. itemName .. "' not found in ServerStorage.Armor")
		return nil
	end
	if not template:IsA("Model") then
		warnPrefix("Armor asset '" .. itemName .. "' in ServerStorage.Armor is not a Model")
		return nil
	end

	return template
end

local function getArmorAttachments(part: BasePart): {Attachment}
	local attachments = {}
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("Attachment") then
			table.insert(attachments, child)
		end
	end
	return attachments
end

local function getTargetCharacterPart(character: Model, partName: string): BasePart?
	local targetPart = character:FindFirstChild(partName)
	if targetPart == nil then
		return nil
	end
	if not targetPart:IsA("BasePart") then
		return nil
	end
	return targetPart
end

local function prepareArmorPart(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.Massless = true
end

local function attachArmorPart(character: Model, itemName: string, armorPart: BasePart): boolean
	prepareArmorPart(armorPart)

	local targetPart = getTargetCharacterPart(character, armorPart.Name)
	if targetPart == nil then
		warnPrefix("Armor part '" .. armorPart.Name .. "' in '" .. itemName .. "' does not match a character BasePart")
		return false
	end

	local attachments = getArmorAttachments(armorPart)
	if #attachments == 0 then
		warnPrefix("Armor part '" .. armorPart.Name .. "' in '" .. itemName .. "' has no Attachment")
		return false
	end
	if #attachments > 1 then
		warnPrefix("Armor part '" .. armorPart.Name .. "' in '" .. itemName .. "' has multiple Attachments; using '" .. attachments[1].Name .. "'")
	end

	local armorAttachment = attachments[1]
	local targetAttachment = targetPart:FindFirstChild(armorAttachment.Name)
	if targetAttachment == nil or not targetAttachment:IsA("Attachment") then
		warnPrefix("Character part '" .. targetPart.Name .. "' is missing Attachment '" .. armorAttachment.Name .. "' for armor '" .. itemName .. "'")
		return false
	end

	local constraint = Instance.new("RigidConstraint")
	constraint.Name = "ArmorRigidConstraint"
	constraint.Attachment0 = armorAttachment
	constraint.Attachment1 = targetAttachment
	constraint.Parent = armorPart

	return true
end

local function destroySlotModel(state: PlayerState, slotName: string)
	local model = state.slotModels[slotName]
	if model ~= nil then
		model:Destroy()
		state.slotModels[slotName] = nil
	end
end

local function syncArmorSlot(player: Player, slotName: string)
	local state = playerStates[player]
	if state == nil then
		return
	end

	local character = player.Character
	if character == nil then
		destroySlotModel(state, slotName)
		return
	end

	destroySlotModel(state, slotName)

	local equippedArmor = PlayerDataHandler.GetEquippedArmor(player)
	local entryId = equippedArmor[slotName]
	if type(entryId) ~= "string" or entryId == "" then
		return
	end

	local itemName = PlayerDataHandler.ResolveInventoryEntryItemName(player, entryId)
	if itemName == "" then
		return
	end

	local template = getArmorTemplate(itemName)
	if template == nil then
		return
	end

	local armorModel = template:Clone()
	armorModel.Name = "Armor_" .. slotName
	armorModel:SetAttribute("ArmorSlot", slotName)
	armorModel:SetAttribute("ArmorItemName", itemName)
	armorModel.Parent = character

	local attachedPartCount = 0
	local basePartCount = 0
	local unattachedParts = {}
	for _, descendant in ipairs(armorModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			basePartCount += 1
			if attachArmorPart(character, itemName, descendant) then
				attachedPartCount += 1
			else
				table.insert(unattachedParts, descendant)
			end
		end
	end

	for _, part in ipairs(unattachedParts) do
		part:Destroy()
	end

	if basePartCount == 0 then
		warnPrefix("Armor model '" .. itemName .. "' has no BasePart descendants")
	elseif attachedPartCount == 0 then
		warnPrefix("Armor model '" .. itemName .. "' has no attachable BasePart descendants")
		armorModel:Destroy()
		return
	end

	state.slotModels[slotName] = armorModel
end

local function syncAllArmor(player: Player)
	for _, slotName in ipairs(ARMOR_SLOTS) do
		syncArmorSlot(player, slotName)
	end
end

local function queueSyncAllArmor(player: Player)
	local state = playerStates[player]
	if state == nil or state.syncQueued then
		return
	end

	state.syncQueued = true
	task.defer(function()
		local latestState = playerStates[player]
		if latestState == nil then
			return
		end

		latestState.syncQueued = false
		syncAllArmor(player)
	end)
end

local function cleanup(player: Player)
	local state = playerStates[player]
	if state == nil then
		return
	end

	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end

	for _, slotName in ipairs(ARMOR_SLOTS) do
		destroySlotModel(state, slotName)
	end

	playerStates[player] = nil
end

local function onPlayerAdded(player: Player)
	local retries = 0
	while PlayerDataHandler.GetClient(player) == nil and retries < DATA_READY_RETRIES do
		retries += 1
		task.wait(DATA_READY_WAIT)
	end

	if PlayerDataHandler.GetClient(player) == nil then
		warnPrefix("Player data not ready for", player.Name)
		return
	end

	if playerStates[player] ~= nil then
		return
	end

	local state: PlayerState = {
		slotModels = {},
		syncQueued = false,
		connections = {},
	}
	playerStates[player] = state

	table.insert(state.connections, player.CharacterAdded:Connect(function()
		task.defer(function()
			queueSyncAllArmor(player)
		end)
	end))

	for _, slotName in ipairs(ARMOR_SLOTS) do
		local fieldName = "Equipped" .. slotName
		PlayerDataHandler.ListenToStatUpdate(fieldName, player, function()
			syncArmorSlot(player, slotName)
		end)
	end

	if player.Character ~= nil then
		queueSyncAllArmor(player)
	end
end

function ArmorAttachmentService.Initialize()
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(onPlayerAdded, player)
	end)

	Players.PlayerRemoving:Connect(cleanup)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
end

return ArmorAttachmentService
