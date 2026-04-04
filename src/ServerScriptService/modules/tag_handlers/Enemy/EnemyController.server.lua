local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local modules = ServerScriptService.modules
local EnemyLootHandler = require(modules.EnemyLootHandler)
local MineTransitionService = require(modules.MineTransitionService)

local enemyBehaviors = modules.EnemyBehaviors
local movementBehaviors = enemyBehaviors.Movement
local attackBehaviors = enemyBehaviors.Attack

local DEFAULT_MOVEMENT_BEHAVIOR = "DefaultGround"
local DEFAULT_ATTACK_BEHAVIOR = "DefaultMelee"
local UPDATE_INTERVAL = 0.1

local enemy = script.Parent
local humanoid: Humanoid = enemy:FindFirstChildOfClass("Humanoid")
local root = enemy:FindFirstChild("HumanoidRootPart")

if humanoid == nil or root == nil then
	warn("EnemyController: Missing Humanoid or HumanoidRootPart on", enemy.Name)
	return
end

local function loadBehaviorModule(folder: Instance, behaviorName: string, defaultBehaviorName: string)
	local resolvedName = behaviorName
	local behaviorModule = folder:FindFirstChild(resolvedName)
	if behaviorModule == nil then
		warn(string.format(
			"EnemyController: Missing behavior module '%s' on %s, falling back to '%s'",
			tostring(behaviorName),
			enemy.Name,
			defaultBehaviorName
		))
		resolvedName = defaultBehaviorName
		behaviorModule = folder:FindFirstChild(resolvedName)
	end

	if behaviorModule == nil or not behaviorModule:IsA("ModuleScript") then
		error(string.format("EnemyController: Missing default behavior module '%s'", resolvedName))
	end

	local loadedModule = require(behaviorModule)
	if type(loadedModule) ~= "table" or type(loadedModule.Update) ~= "function" then
		error(string.format("EnemyController: Behavior module '%s' must return a table with Update(context, dt, targetCharacter, targetPosition)", resolvedName))
	end

	return loadedModule, resolvedName
end

local stats = {
	attackRange = enemy:GetAttribute("AttackRange") or 5,
	walkSpeed = enemy:GetAttribute("WalkSpeed") or 8,
	attackInterval = enemy:GetAttribute("AttackInterval") or 0.5,
	detectionRadius = enemy:GetAttribute("DetectionRadius") or 25,
	maxInterestDistance = (enemy:GetAttribute("DetectionRadius") or 25) * 2,
	damage = enemy:GetAttribute("Damage") or 10,
}

humanoid.WalkSpeed = stats.walkSpeed

local movementBehaviorName = enemy:GetAttribute("MovementBehavior") or DEFAULT_MOVEMENT_BEHAVIOR
local attackBehaviorName = enemy:GetAttribute("AttackBehavior") or DEFAULT_ATTACK_BEHAVIOR

local movementBehavior, resolvedMovementBehaviorName = loadBehaviorModule(
	movementBehaviors,
	movementBehaviorName,
	DEFAULT_MOVEMENT_BEHAVIOR
)
local attackBehavior, resolvedAttackBehaviorName = loadBehaviorModule(
	attackBehaviors,
	attackBehaviorName,
	DEFAULT_ATTACK_BEHAVIOR
)

enemy:SetAttribute("MovementBehavior", resolvedMovementBehaviorName)
enemy:SetAttribute("AttackBehavior", resolvedAttackBehaviorName)

local animations = enemy:FindFirstChild("Animations")
local animationTracks = {
	idle = nil,
	walk = nil,
	attack1 = nil,
	attack2 = nil,
	death = nil,
}

if animations then
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local idleAnim = animations:FindFirstChild("Idle")
		local walkAnim = animations:FindFirstChild("Walk")
		local attack1Anim = animations:FindFirstChild("Attack1")
		local attack2Anim = animations:FindFirstChild("Attack2")
		local deathAnim = animations:FindFirstChild("Death")

		if idleAnim then
			animationTracks.idle = animator:LoadAnimation(idleAnim)
			animationTracks.idle.Looped = true
			animationTracks.idle:Play()
		end
		if walkAnim then
			animationTracks.walk = animator:LoadAnimation(walkAnim)
			animationTracks.walk.Looped = true
		end
		if attack1Anim then
			animationTracks.attack1 = animator:LoadAnimation(attack1Anim)
			animationTracks.attack1.Looped = false
		end
		if attack2Anim then
			animationTracks.attack2 = animator:LoadAnimation(attack2Anim)
			animationTracks.attack2.Looped = false
		end
		if deathAnim then
			animationTracks.death = animator:LoadAnimation(deathAnim)
			animationTracks.death.Looped = false
		end
	end
end

local context = {
	enemy = enemy,
	humanoid = humanoid,
	root = root,
	players = Players,
	workspace = Workspace,
	mineTransitionService = MineTransitionService,
	stats = stats,
	animations = animationTracks,
	state = {},
}

function context:PlayAttackAnimation()
	local attack1Track = self.animations.attack1
	local attack2Track = self.animations.attack2

	if attack1Track and attack2Track then
		local track = math.random() < 0.5 and attack1Track or attack2Track
		track:Play()
	elseif attack1Track then
		attack1Track:Play()
	elseif attack2Track then
		attack2Track:Play()
	end
end

local function stopMovement()
	humanoid:Move(Vector3.zero)
end

local function getClosestVisiblePlayer()
	local players = Players:GetPlayers()
	for _, player in ipairs(players) do
		local character = player.Character
		if character == nil then
			continue
		end

		local targetHumanoid = character:FindFirstChildOfClass("Humanoid")
		local characterRoot = character:FindFirstChild("HumanoidRootPart")
		if targetHumanoid == nil or targetHumanoid.Health <= 0 or characterRoot == nil then
			continue
		end

		local diff = characterRoot.Position - root.Position
		if diff.Magnitude > stats.detectionRadius then
			continue
		end

		local allEnemies = CollectionService:GetTagged("Enemy")
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = allEnemies

		local raycastResult = Workspace:Raycast(root.Position, diff, raycastParams)
		if raycastResult ~= nil and not raycastResult.Instance:IsDescendantOf(character) then
			continue
		end

		return player
	end

	return nil
end

local function getTargetCharacter(targetPlayer: Player?)
	if targetPlayer == nil then
		return nil
	end

	local character = targetPlayer.Character
	if character == nil then
		return nil
	end

	local targetHumanoid = character:FindFirstChildOfClass("Humanoid")
	local characterRoot = character:FindFirstChild("HumanoidRootPart")
	if targetHumanoid == nil or targetHumanoid.Health <= 0 or characterRoot == nil then
		return nil
	end

	return character
end

local function getTargetPosition(targetCharacter: Model?)
	if targetCharacter == nil then
		return nil
	end

	local characterRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	if characterRoot == nil then
		return nil
	end

	return characterRoot.Position
end

local alive = humanoid.Health > 0
local runningConnection: RBXScriptConnection? = nil

if type(movementBehavior.Init) == "function" then
	movementBehavior.Init(context)
end

if type(attackBehavior.Init) == "function" then
	attackBehavior.Init(context)
end

humanoid.Died:Once(function()
	if runningConnection ~= nil then
		runningConnection:Disconnect()
		runningConnection = nil
	end

	alive = false
	root.Anchored = true

	stopMovement()

	if type(movementBehavior.Cleanup) == "function" then
		movementBehavior.Cleanup(context)
	end

	if type(attackBehavior.Cleanup) == "function" then
		attackBehavior.Cleanup(context)
	end

	if animationTracks.walk then
		animationTracks.walk:Stop()
	end
	if animationTracks.idle then
		animationTracks.idle:Stop()
	end
	if animationTracks.death then
		animationTracks.death:Play()
	end

	EnemyLootHandler.HandleDeath(enemy)

	task.delay(3, function()
		enemy:Destroy()
	end)
end)

runningConnection = humanoid.Running:Connect(function(speed)
	local walkTrack = animationTracks.walk
	if walkTrack == nil then
		return
	end

	if speed <= 0 then
		walkTrack:Stop()
	else
		walkTrack:Play()
	end
end)

local targetPlayer: Player? = nil
local lastUpdateAt = os.clock()

while alive do
	local now = os.clock()
	local dt = now - lastUpdateAt
	lastUpdateAt = now

	local targetCharacter = getTargetCharacter(targetPlayer)
	local targetPosition = getTargetPosition(targetCharacter)

	if targetPosition == nil then
		targetPlayer = getClosestVisiblePlayer()
		targetCharacter = getTargetCharacter(targetPlayer)
		targetPosition = getTargetPosition(targetCharacter)

		if targetPosition == nil then
			stopMovement()
			task.wait(0.25)
			continue
		end
	end

	local distance = (targetPosition - root.Position).Magnitude
	if distance > stats.maxInterestDistance then
		targetPlayer = nil
		stopMovement()
		task.wait(UPDATE_INTERVAL)
		continue
	end

	movementBehavior.Update(context, dt, targetCharacter, targetPosition)
	attackBehavior.Update(context, dt, targetCharacter, targetPosition)

	task.wait(UPDATE_INTERVAL)
end
