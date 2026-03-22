local CollectionService = game:GetService("CollectionService")

local enemy = script.Parent
local animations = enemy.Animations
local humanoid: Humanoid = enemy.Humanoid
local animator = humanoid.Animator
local root = enemy.HumanoidRootPart

local idleAnim = animations.Idle
local walkAnim = animations.Walk
local attack1Anim = animations.Attack1
local attack2Anim = animations.Attack2
local deathAnim = animations.Death

local ATTACK_RANGE = 7
local WALK_SPEED = 20
local ATTACK_INTERVAL = 0.5
local DETECTION_RADIUS = 100
local MAX_INTEREST_DISTANCE = 150
local DAMAGE = 20

humanoid.WalkSpeed = WALK_SPEED

local idleTrack = animator:LoadAnimation(idleAnim)
idleTrack.Looped = true
idleTrack:Play()

local walkTrack = animator:LoadAnimation(walkAnim)
walkTrack.Looped = true

local attack1Track = animator:LoadAnimation(attack1Anim)
attack1Track.Looped = false

local attack2Track = animator:LoadAnimation(attack2Anim)
attack2Track.Looped = false

local deathTrack = animator:LoadAnimation(deathAnim)
deathTrack.Looped = false

local alive = humanoid.Health > 0

local runningConnection = nil

humanoid.Died:Once(function()
	if runningConnection ~= nil then
		runningConnection:Disconnect()
		runningConnection = nil
	end
	
	alive = false
	root.Anchored = true
	walkTrack:Stop()
	idleTrack:Stop()
	deathTrack:Play()
	task.delay(3, function()
		enemy:Destroy()
	end)
end)

runningConnection = humanoid.Running:Connect(function(speed)
	if speed <= 0 then
		walkTrack:Stop()
	else
		walkTrack:Play()
	end
end)

function getClosestVisiblePlayer()
	local players = game.Players:GetChildren()
	for _, plr in ipairs(players) do
		local character = plr.Character
		if character == nil then continue end
		
		local characterRoot = character:FindFirstChild("HumanoidRootPart")
		local diff: Vector3 = (characterRoot.Position - root.Position)
		
		local allEnemies = CollectionService:GetTagged("Enemy")
		
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = allEnemies
		
		local raycastResult = game.Workspace:Raycast(root.Position, diff.Unit*DETECTION_RADIUS)
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
		
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid == nil then
			return false
		end
		
		if humanoid.Health <= 0 then
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
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then return end
	
	local track = math.random() < 0.5 and attack1Track or attack2Track
	track:Play()
	humanoid:TakeDamage(DAMAGE)
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
	
	task.wait(1)
end