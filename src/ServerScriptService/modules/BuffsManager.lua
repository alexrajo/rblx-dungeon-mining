local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local globalConfig = require(ReplicatedStorage.GlobalConfig)

-- buffs[player] = {
--   speed  = { bonus: number, originalSpeed: number, expiresAt: number, character: Model },
--   damage = { multiplier: number, expiresAt: number },
-- }
local buffs: {[Player]: {speed: any?, damage: any?}} = {}

local function ensureEntry(player: Player)
	if buffs[player] == nil then
		buffs[player] = {}
	end
end

local BuffsManager = {}

-- Apply a temporary WalkSpeed buff.
-- speedFraction is a fraction of DEFAULT_WALKSPEED (e.g. 0.20 → +20%).
-- If a speed buff is already active, the existing bonus is subtracted from the
-- humanoid's current speed before the new bonus is applied, preventing stacking.
function BuffsManager.ApplySpeedBuff(player: Player, speedFraction: number, duration: number)
	ensureEntry(player)

	local character = player.Character
	if character == nil then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then return end

	local bonus = math.round(globalConfig.DEFAULT_WALKSPEED * speedFraction)

	-- If a speed buff is already active on the same character, derive originalSpeed
	-- by subtracting the old bonus so we don't compound.
	local existing = buffs[player].speed
	local originalSpeed
	if existing ~= nil and existing.character == character then
		originalSpeed = existing.originalSpeed
	else
		originalSpeed = humanoid.WalkSpeed
	end

	buffs[player].speed = {
		bonus = bonus,
		originalSpeed = originalSpeed,
		expiresAt = os.clock() + duration,
		character = character,
	}

	humanoid.WalkSpeed = originalSpeed + bonus

	task.delay(duration, function()
		local entry = buffs[player]
		if entry == nil then return end
		local speedBuff = entry.speed
		if speedBuff == nil then return end
		-- Bail out if a newer buff replaced this one
		if speedBuff.character ~= character then return end
		if os.clock() < speedBuff.expiresAt then return end

		entry.speed = nil

		-- Only restore if the player is still on the same character
		local currentChar = player.Character
		if currentChar ~= character then return end
		local h = character:FindFirstChildOfClass("Humanoid")
		if h then
			h.WalkSpeed = speedBuff.originalSpeed
		end
	end)
end

-- Apply a temporary damage multiplier (e.g. 1.25 for +25% damage).
function BuffsManager.ApplyDamageMultiplier(player: Player, multiplier: number, duration: number)
	ensureEntry(player)

	buffs[player].damage = {
		multiplier = multiplier,
		expiresAt = os.clock() + duration,
	}

	task.delay(duration, function()
		local entry = buffs[player]
		if entry == nil then return end
		local damageBuff = entry.damage
		if damageBuff == nil then return end
		if os.clock() < damageBuff.expiresAt then return end
		entry.damage = nil
	end)
end

-- Returns the active damage multiplier for a player, or 1.0 if none is active.
function BuffsManager.GetDamageMultiplier(player: Player): number
	local entry = buffs[player]
	if entry == nil then return 1.0 end
	local damageBuff = entry.damage
	if damageBuff == nil then return 1.0 end
	if os.clock() >= damageBuff.expiresAt then
		entry.damage = nil
		return 1.0
	end
	return damageBuff.multiplier
end

-- Clean up state when a player leaves.
function BuffsManager.ClearPlayer(player: Player)
	buffs[player] = nil
end

Players.PlayerRemoving:Connect(BuffsManager.ClearPlayer)

return BuffsManager
