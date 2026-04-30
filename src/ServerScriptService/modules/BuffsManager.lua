local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local globalConfig = require(ReplicatedStorage.GlobalConfig)
local EffectsConfig = require(ReplicatedStorage.configs.EffectsConfig)
local TempStats = require(ServerScriptService.modules.PlayerDataHandler.TempStats)

type EffectState = {
	effectId: string,
	duration: number,
	expiresAt: number,
	revision: number,
	value: number,
}

local buffs: {[Player]: {[string]: EffectState}} = {}

local function ensureEntry(player: Player)
	if buffs[player] == nil then
		buffs[player] = {}
	end
end

local function getActiveEffectsFolder(player: Player): Folder?
	local activeEffects = TempStats:GetTempStat(player, "ActiveEffects")
	if activeEffects ~= nil and activeEffects:IsA("Folder") then
		return activeEffects
	end

	return nil
end

local function getEffectFolder(activeEffectsFolder: Folder, effectId: string): Folder
	local effectFolder = activeEffectsFolder:FindFirstChild(effectId)
	if effectFolder ~= nil and effectFolder:IsA("Folder") then
		return effectFolder
	end

	effectFolder = Instance.new("Folder")
	effectFolder.Name = effectId
	effectFolder.Parent = activeEffectsFolder
	return effectFolder
end

local function getOrCreateValue(parent: Instance, className: string, valueName: string)
	local valueObject = parent:FindFirstChild(valueName)
	if valueObject ~= nil and valueObject.ClassName == className then
		return valueObject
	end

	if valueObject ~= nil then
		valueObject:Destroy()
	end

	valueObject = Instance.new(className)
	valueObject.Name = valueName
	valueObject.Parent = parent
	return valueObject
end

local function getCurrentTime(): number
	return os.clock()
end

local function removeReplicatedEffect(player: Player, effectId: string)
	local activeEffectsFolder = getActiveEffectsFolder(player)
	if activeEffectsFolder == nil then
		return
	end

	local effectFolder = activeEffectsFolder:FindFirstChild(effectId)
	if effectFolder ~= nil then
		effectFolder:Destroy()
	end
end

local function replicateEffect(player: Player, effectState: EffectState)
	local activeEffectsFolder = getActiveEffectsFolder(player)
	if activeEffectsFolder == nil then
		return
	end

	local effectConfig = EffectsConfig.GetEffectData(effectState.effectId)
	if effectConfig == nil then
		return
	end

	local effectFolder = getEffectFolder(activeEffectsFolder, effectState.effectId)

	local imageId = getOrCreateValue(effectFolder, "StringValue", "ImageId")
	imageId.Value = tostring(effectConfig.imageId or EffectsConfig.DEFAULT_IMAGE_ID)

	local displayName = getOrCreateValue(effectFolder, "StringValue", "DisplayName")
	displayName.Value = effectConfig.displayName or effectState.effectId

	local duration = getOrCreateValue(effectFolder, "NumberValue", "Duration")
	duration.Value = effectState.duration

	local expiresAt = getOrCreateValue(effectFolder, "NumberValue", "ExpiresAt")
	expiresAt.Value = effectState.expiresAt
end

local function getActiveEffectState(player: Player, effectId: string): EffectState?
	local entry = buffs[player]
	if entry == nil then
		return nil
	end

	local effectState = entry[effectId]
	if effectState == nil then
		return nil
	end

	if getCurrentTime() < effectState.expiresAt then
		return effectState
	end

	entry[effectId] = nil
	removeReplicatedEffect(player, effectId)
	return nil
end

local function getActiveSpeedBonus(player: Player): number
	local entry = buffs[player]
	if entry == nil then
		return 0
	end

	local totalBonus = 0

	for effectId, effectState in pairs(entry) do
		local effectConfig = EffectsConfig.GetEffectData(effectId)
		if effectConfig ~= nil and effectConfig.modifierType == "speed_additive" then
			if getCurrentTime() < effectState.expiresAt then
				totalBonus += math.round(globalConfig.DEFAULT_WALKSPEED * effectState.value)
			else
				entry[effectId] = nil
				removeReplicatedEffect(player, effectId)
			end
		end
	end

	return totalBonus
end

local BuffsManager = {}

function BuffsManager.RefreshCharacterState(player: Player, baseWalkSpeed: number?)
	local character = player.Character
	if character == nil then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end

	local resolvedBaseWalkSpeed = baseWalkSpeed
	if resolvedBaseWalkSpeed == nil then
		resolvedBaseWalkSpeed = humanoid.WalkSpeed - getActiveSpeedBonus(player)
	end

	humanoid.WalkSpeed = resolvedBaseWalkSpeed + getActiveSpeedBonus(player)
end

function BuffsManager.ApplyEffect(player: Player, effectId: string, value: number, duration: number)
	ensureEntry(player)

	local effectConfig = EffectsConfig.GetEffectData(effectId)
	if effectConfig == nil then
		return
	end

	local entry = buffs[player]
	local previousState = getActiveEffectState(player, effectId)
	local nextRevision = previousState ~= nil and (previousState.revision + 1) or 1
	local expiresAt = getCurrentTime() + duration

	entry[effectId] = {
		effectId = effectId,
		duration = duration,
		expiresAt = expiresAt,
		revision = nextRevision,
		value = value,
	}

	replicateEffect(player, entry[effectId])
	BuffsManager.RefreshCharacterState(player)

	task.delay(duration, function()
		local currentState = getActiveEffectState(player, effectId)
		if currentState == nil then
			return
		end
		if currentState.revision ~= nextRevision then
			return
		end
		if getCurrentTime() < currentState.expiresAt then
			return
		end

		local playerEntry = buffs[player]
		if playerEntry == nil then
			return
		end

		playerEntry[effectId] = nil
		removeReplicatedEffect(player, effectId)
		BuffsManager.RefreshCharacterState(player)
	end)
end

-- Returns the active damage multiplier for a player, or 1.0 if none is active.
function BuffsManager.GetDamageMultiplier(player: Player): number
	local entry = buffs[player]
	if entry == nil then
		return 1.0
	end

	local damageMultiplier = 1.0

	for effectId, effectState in pairs(entry) do
		local effectConfig = EffectsConfig.GetEffectData(effectId)
		if effectConfig ~= nil and effectConfig.modifierType == "damage_multiplier" then
			if getCurrentTime() < effectState.expiresAt then
				damageMultiplier *= effectState.value
			else
				entry[effectId] = nil
				removeReplicatedEffect(player, effectId)
			end
		end
	end

	return damageMultiplier
end

-- Clean up state when a player leaves.
function BuffsManager.ClearPlayer(player: Player)
	local activeEffectsFolder = getActiveEffectsFolder(player)
	if activeEffectsFolder ~= nil then
		activeEffectsFolder:ClearAllChildren()
	end
	buffs[player] = nil
end

Players.PlayerRemoving:Connect(BuffsManager.ClearPlayer)

return BuffsManager
