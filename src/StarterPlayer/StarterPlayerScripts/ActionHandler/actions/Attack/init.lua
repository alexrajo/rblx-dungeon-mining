local plr = game.Players.LocalPlayer

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))
local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local HIT_DELAY = 0.2
local SWORD_SWING_SOUND_IDS = {
	125023973544068,
	77014651976869,
	73220320692052,
	140194463941336,
	105564993105995,
	94410407602311,
	127060626004341,
	133050367938898,
}
local ATTACK_ARC_DOT = 0 -- forward 180° arc

local attackAnim = Instance.new("Animation")
attackAnim.AnimationId = "rbxassetid://93287550553129"

local cachedCharacter: Model? = nil
local cachedTrack: AnimationTrack? = nil

local function getTrack(humanoid: Humanoid): AnimationTrack?
	local character = humanoid.Parent
	if character ~= cachedCharacter then
		cachedCharacter = character
		cachedTrack = nil
	end
	if cachedTrack == nil then
		local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5)
		if animator == nil then return nil end
		cachedTrack = animator:LoadAnimation(attackAnim)
		cachedTrack.Looped = false
		cachedTrack.Priority = Enum.AnimationPriority.Action
	end
	return cachedTrack
end

local function getTargetPosition(target: Instance): Vector3?
	if target:IsA("BasePart") then
		return target.Position
	end

	if target:IsA("Model") then
		return target:GetPivot().Position
	end

	return nil
end

local function playRandomSwordSwingSound()
	local soundId = SWORD_SWING_SOUND_IDS[math.random(1, #SWORD_SWING_SOUND_IDS)]
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	SoundService:PlayLocalSound(sound)

	task.spawn(function()
		sound.Ended:Wait()
		sound:Destroy()
	end)
end

local AttackAction = {}

function AttackAction.Activate(tool: Tool?)
	local character = plr.Character
	if character == nil or character.Parent == nil then return 0.5 end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoidRootPart == nil or humanoid == nil or humanoid.Health <= 0 then return 0.5 end

	-- Determine cooldown locally from the wielded weapon so the timer starts
	-- immediately without waiting for a server round-trip.
	local weaponName = tool and tool:GetAttribute("HotbarItemName") or nil
	local weaponStats = GearConfig.GetWeaponCombatStats(type(weaponName) == "string" and weaponName or nil)
	local attackCooldown = weaponStats.attackCooldown or globalConfig.ATTACK_SWING_COOLDOWN

	playRandomSwordSwingSound()

	-- Play weapon swing animation
	local track = getTrack(humanoid)
	if track then
		track:Play()
	end

	-- Find all enemies within attack range using sphere overlap
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {character}

	local parts = workspace:GetPartBoundsInRadius(
		humanoidRootPart.Position,
		globalConfig.ATTACK_REACH_DISTANCE,
		overlapParams
	)

	-- Collect unique attack targets within the forward arc.
	local hitTargets: {Instance} = {}
	local seenTargets: {[Instance]: boolean} = {}
	local lookVector = humanoidRootPart.CFrame.LookVector

	for _, part in ipairs(parts) do
		local current = part
		local target = nil
		while current and current ~= workspace do
			if CollectionService:HasTag(current, "Enemy") then
				target = current
				break
			end
			if CollectionService:HasTag(current, "MineCrate") then
				target = current
				break
			end
			current = current.Parent
		end

		if target and not seenTargets[target] then
			local targetPosition = getTargetPosition(target)
			if targetPosition ~= nil then
				local toTarget = targetPosition - humanoidRootPart.Position
				if toTarget.Magnitude > 0 and toTarget.Unit:Dot(lookVector) >= ATTACK_ARC_DOT then
					seenTargets[target] = true
					table.insert(hitTargets, target)
				end
			end
		end
	end

	-- Spawn the hit-registration and server call in the background so the
	-- cooldown timer starts immediately regardless of server latency.
	task.spawn(function()
		task.wait(HIT_DELAY)
		APIService.GetFunction("Attack"):InvokeServer(tool, hitTargets)
	end)

	return attackCooldown
end

return AttackAction
