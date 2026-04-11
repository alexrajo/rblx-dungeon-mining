local plr = game.Players.LocalPlayer

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))
local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local StatRetrieval = require(ReplicatedStorage.utils.StatRetrieval)

local HIT_DELAY = 0.2
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

local AttackAction = {}

function AttackAction.Activate()
	local character = plr.Character
	if character == nil or character.Parent == nil then return 0.5 end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoidRootPart == nil or humanoid == nil or humanoid.Health <= 0 then return 0.5 end

	-- Determine cooldown locally from equipped weapon so the timer starts
	-- immediately without waiting for a server round-trip.
	local equippedWeapon = StatRetrieval.GetPlayerStat("EquippedWeapon", plr)
	local weaponStats = GearConfig.GetWeaponCombatStats(equippedWeapon)
	local attackCooldown = weaponStats.attackCooldown or globalConfig.ATTACK_SWING_COOLDOWN

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

	-- Collect unique enemy models within the forward arc
	local hitEnemies: {Instance} = {}
	local seenEnemies: {[Instance]: boolean} = {}
	local lookVector = humanoidRootPart.CFrame.LookVector

	for _, part in ipairs(parts) do
		local current = part
		local enemyModel = nil
		while current and current ~= workspace do
			if CollectionService:HasTag(current, "Enemy") then
				enemyModel = current
				break
			end
			current = current.Parent
		end

		if enemyModel and not seenEnemies[enemyModel] then
			local enemyRoot = enemyModel:FindFirstChild("HumanoidRootPart")
			if enemyRoot then
				local toEnemy = enemyRoot.Position - humanoidRootPart.Position
				if toEnemy.Magnitude > 0 and toEnemy.Unit:Dot(lookVector) >= ATTACK_ARC_DOT then
					seenEnemies[enemyModel] = true
					table.insert(hitEnemies, enemyModel)
				end
			end
		end
	end

	-- Spawn the hit-registration and server call in the background so the
	-- cooldown timer starts immediately regardless of server latency.
	task.spawn(function()
		task.wait(HIT_DELAY)
		APIService.GetFunction("Attack"):InvokeServer(hitEnemies)
	end)

	return attackCooldown
end

return AttackAction
