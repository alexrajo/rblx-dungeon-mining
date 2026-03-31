local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local enemy = script.Parent
local humanoid: Humanoid = enemy:FindFirstChildOfClass("Humanoid")
local root = enemy:FindFirstChild("HumanoidRootPart")

if humanoid == nil or root == nil then
	warn("EnemyController: Missing Humanoid or HumanoidRootPart on", enemy.Name)
	return
end

-- Read stats from attributes (set by the Enemy tag handler init.lua)
local ATTACK_RANGE = enemy:GetAttribute("AttackRange") or 5
local WALK_SPEED = enemy:GetAttribute("WalkSpeed") or 8
local ATTACK_INTERVAL = 0.5
local DETECTION_RADIUS = enemy:GetAttribute("DetectionRadius") or 25
local MAX_INTEREST_DISTANCE = DETECTION_RADIUS * 2
local DAMAGE = enemy:GetAttribute("Damage") or 10

humanoid.WalkSpeed = WALK_SPEED

-- Load animations if they exist
local animations = enemy:FindFirstChild("Animations")
local idleTrack, walkTrack, attack1Track, attack2Track, deathTrack

if animations then
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local idleAnim = animations:FindFirstChild("Idle")
		local walkAnim = animations:FindFirstChild("Walk")
		local attack1Anim = animations:FindFirstChild("Attack1")
		local attack2Anim = animations:FindFirstChild("Attack2")
		local deathAnim = animations:FindFirstChild("Death")

		if idleAnim then
			idleTrack = animator:LoadAnimation(idleAnim)
			idleTrack.Looped = true
			idleTrack:Play()
		end
		if walkAnim then
			walkTrack = animator:LoadAnimation(walkAnim)
			walkTrack.Looped = true
		end
		if attack1Anim then
			attack1Track = animator:LoadAnimation(attack1Anim)
			attack1Track.Looped = false
		end
		if attack2Anim then
			attack2Track = animator:LoadAnimation(attack2Anim)
			attack2Track.Looped = false
		end
		if deathAnim then
			deathTrack = animator:LoadAnimation(deathAnim)
			deathTrack.Looped = false
		end
	end
end

local alive = humanoid.Health > 0
local runningConnection = nil

-- Load EnemyLootHandler for death drops
local EnemyLootHandler = require(ServerScriptService.modules.EnemyLootHandler)
local MineTransitionService = require(ServerScriptService.modules.MineTransitionService)

humanoid.Died:Once(function()
	if runningConnection ~= nil then
		runningConnection:Disconnect()
		runningConnection = nil
	end

	alive = false
	root.Anchored = true

	if walkTrack then walkTrack:Stop() end
	if idleTrack then idleTrack:Stop() end
	if deathTrack then deathTrack:Play() end

	-- Handle loot drops
	EnemyLootHandler.HandleDeath(enemy)

	task.delay(3, function()
		enemy:Destroy()
	end)
end)

runningConnection = humanoid.Running:Connect(function(speed)
	if walkTrack then
		if speed <= 0 then
			walkTrack:Stop()
		else
			walkTrack:Play()
		end
	end
end)

function getClosestVisiblePlayer()
	local players = game.Players:GetChildren()
	for _, plr in ipairs(players) do
		local character = plr.Character
		if character == nil then continue end

		local characterRoot = character:FindFirstChild("HumanoidRootPart")
		if characterRoot == nil then continue end

		local diff: Vector3 = (characterRoot.Position - root.Position)
		if diff.Magnitude > DETECTION_RADIUS then continue end

		local allEnemies = CollectionService:GetTagged("Enemy")

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = allEnemies

		local raycastResult = game.Workspace:Raycast(root.Position, diff.Unit * DETECTION_RADIUS, raycastParams)
		if raycastResult == nil then continue end

		return plr, raycastResult.Position
	end
end

function getInterestAndPosition(targetPlayer: Player)
	if targetPlayer then
		local character = targetPlayer.Character
		if character == nil then
			return false
		end

		local plrHumanoid = character:FindFirstChild("Humanoid")
		if plrHumanoid == nil then
			return false
		end

		if plrHumanoid.Health <= 0 then
			return false
		end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart == nil then
			return false
		end

		return true, humanoidRootPart.Position
	else
		return false
	end
end

function attack(character)
	if character == nil then return end
	local plrHumanoid = character:FindFirstChild("Humanoid")
	if plrHumanoid == nil or plrHumanoid.Health <= 0 then return end

	local player = Players:GetPlayerFromCharacter(character)
	if player ~= nil and MineTransitionService.IsPlayerProtected(player) then
		return
	end

	if attack1Track and attack2Track then
		local track = math.random() < 0.5 and attack1Track or attack2Track
		track:Play()
	elseif attack1Track then
		attack1Track:Play()
	end

	plrHumanoid:TakeDamage(DAMAGE)
end

local targetPlayer = nil

while alive do
	local interest, position = getInterestAndPosition(targetPlayer)
	if interest == false or position == nil then
		targetPlayer = getClosestVisiblePlayer()
		if targetPlayer == nil then
			humanoid:Move(Vector3.zero)
			task.wait(3)
		end
		task.wait()
		continue
	end

	local diff = (position - root.Position)
	local dir = diff.Unit
	local distance = diff.Magnitude
	if distance > MAX_INTEREST_DISTANCE then
		targetPlayer = nil
		continue
	end

	humanoid:Move(dir)

	if distance <= ATTACK_RANGE then
		attack(targetPlayer.Character)
	end

	task.wait(ATTACK_INTERVAL)
end
