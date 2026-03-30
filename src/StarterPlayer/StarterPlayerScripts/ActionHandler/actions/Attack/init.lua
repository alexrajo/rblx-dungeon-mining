local plr = game.Players.LocalPlayer

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))

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

	-- Delay hit registration to sync with animation
	task.wait(HIT_DELAY)

	-- No valid targets — return 0 (delay already elapsed)
	if #hitEnemies == 0 then return 0 end

	-- Invoke server with list of hit enemies
	local func = APIService.GetFunction("Attack")
	local result = func:InvokeServer(hitEnemies)

	local cooldown = (result and result.cooldown) or globalConfig.ATTACK_SWING_COOLDOWN
	return math.max(0, cooldown - HIT_DELAY)
end

return AttackAction
