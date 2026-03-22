local ReplicatedStorage = game:GetService("ReplicatedStorage")
local configs = ReplicatedStorage.configs
local EnemyConfig = require(configs.EnemyConfig)

local controllerScriptRef = script.EnemyController
controllerScriptRef.Enabled = false

local TagHandler = {}

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
		instance:SetAttribute("XPReward", data.xpReward)
	end

	-- Create LastAttacker ObjectValue for tracking who killed the enemy
	local lastAttacker = Instance.new("ObjectValue")
	lastAttacker.Name = "LastAttacker"
	lastAttacker.Parent = instance

	-- Clone and enable the controller script
	local controller = controllerScriptRef:Clone()
	controller.Parent = instance
	controller.Enabled = true
end

return TagHandler
