local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local configs = ReplicatedStorage.configs
local EnemyConfig = require(configs.EnemyConfig)
local BossEnemyService = require(ServerScriptService.modules.BossEnemyService)

local controllerScriptRef = script.EnemyController
controllerScriptRef.Enabled = false

local TagHandler = {}

local DEFAULT_MOVEMENT_BEHAVIOR = "DefaultGround"
local DEFAULT_ATTACK_BEHAVIOR = "DefaultMelee"

function TagHandler.Apply(instance: Instance)
	-- Read EnemyType attribute and set stats from config
	local enemyType = instance:GetAttribute("EnemyType")
	if enemyType and EnemyConfig[enemyType] then
		local data = EnemyConfig[enemyType]

		-- Set humanoid stats
		local humanoid = instance:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = data.hp
			humanoid.Health = data.hp
		end

		-- Set config attributes for the controller to read
		instance:SetAttribute("Damage", data.damage)
		instance:SetAttribute("Defense", data.defense)
		instance:SetAttribute("WalkSpeed", data.walkSpeed)
		instance:SetAttribute("DetectionRadius", data.detectionRadius)
		instance:SetAttribute("AttackRange", data.attackRange)
		instance:SetAttribute("Behavior", data.behavior)
		instance:SetAttribute("MovementBehavior", data.movementBehavior or DEFAULT_MOVEMENT_BEHAVIOR)
		instance:SetAttribute("AttackBehavior", data.attackBehavior or DEFAULT_ATTACK_BEHAVIOR)
		instance:SetAttribute("XPReward", data.xpReward)
	end

	-- Create LastAttacker ObjectValue for tracking who killed the enemy
	if instance:FindFirstChild("LastAttacker") == nil then
		local lastAttacker = Instance.new("ObjectValue")
		lastAttacker.Name = "LastAttacker"
		lastAttacker.Parent = instance
	end

	if instance:IsA("Model") and BossEnemyService.IsBossEnemy(instance) then
		BossEnemyService.ConfigureBoss(instance)
	end

	-- Clone and enable the controller script
	local controller = controllerScriptRef:Clone()
	controller.Parent = instance
	controller.Enabled = true
end

return TagHandler
