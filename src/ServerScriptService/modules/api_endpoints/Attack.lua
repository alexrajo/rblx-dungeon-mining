local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local APIService = require(ReplicatedStorage.services.APIService)

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

local configs = ReplicatedStorage.configs
local GearConfig = require(configs.GearConfig)
local EnemyConfig = require(configs.EnemyConfig)
local globalConfig = require(ReplicatedStorage.GlobalConfig)

local debounce = {}

local endpoint = {}

local function applyKnockback(attackerRoot: BasePart, enemyRoot: BasePart, knockback: number)
	if knockback <= 0 or enemyRoot.Anchored then
		return
	end

	local direction = enemyRoot.Position - attackerRoot.Position
	if direction.Magnitude <= 0.001 then
		direction = attackerRoot.CFrame.LookVector
	else
		direction = direction.Unit
	end

	local impulseDirection = Vector3.new(direction.X, 0.15, direction.Z)
	if impulseDirection.Magnitude <= 0.001 then
		return
	end

	enemyRoot:ApplyImpulse(impulseDirection.Unit * knockback * enemyRoot.AssemblyMass)
end

function endpoint.Call(player: Player, enemies: {Instance})
	if debounce[player] then return { success = false, cooldown = 0.1 } end

	if type(enemies) ~= "table" then
		return { success = false, cooldown = 0.1 }
	end

	local character = player.Character
	if character == nil then return { success = false, cooldown = 0.5 } end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart == nil then return { success = false, cooldown = 0.5 } end

	-- Apply cooldown immediately to prevent spam
	local equippedWeapon = PlayerDataHandler.GetEquippedWeapon(player)
	local weaponStats = GearConfig.GetWeaponCombatStats(equippedWeapon)
	local attackCooldown = weaponStats.attackCooldown or globalConfig.ATTACK_SWING_COOLDOWN

	debounce[player] = true
	task.delay(attackCooldown, function()
		debounce[player] = nil
	end)

	-- Calculate attacker stats once for all hits
	local level = PlayerDataHandler.GetClient(player) and PlayerDataHandler.GetClient(player):GetDataValue("Level", 1) or 1
	local baseCombatDamage = StatCalculation.GetCombatDamage(equippedWeapon, level)

	local totalDamage = 0
	local hitCount = 0
	local hitData: {{enemy: Model, damage: number, isCritical: boolean}} = {}

	for _, targetInstance in ipairs(enemies) do
		if targetInstance == nil or targetInstance.Parent == nil then continue end

		-- Confirm Enemy tag (server re-validates client claim)
		local enemyModel = nil
		local current = targetInstance
		while current and current ~= workspace do
			if CollectionService:HasTag(current, "Enemy") then
				enemyModel = current
				break
			end
			current = current.Parent
		end
		if enemyModel == nil then continue end

		-- Validate distance
		local enemyRoot = enemyModel:FindFirstChild("HumanoidRootPart")
		if enemyRoot == nil then continue end
		local distance = (enemyRoot.Position - humanoidRootPart.Position).Magnitude
		if distance > globalConfig.ATTACK_REACH_DISTANCE then continue end

		-- Validate enemy is alive
		local enemyHumanoid = enemyModel:FindFirstChildOfClass("Humanoid")
		if enemyHumanoid == nil or enemyHumanoid.Health <= 0 then continue end

		-- Calculate damage using this enemy's defense
		local enemyType = enemyModel:GetAttribute("EnemyType") or "Cave Slime"
		local enemyData = EnemyConfig[enemyType]
		local enemyDefense = enemyData and enemyData.defense or 0

		local damage = math.max(1, baseCombatDamage - enemyDefense)
		local isCritical = math.random() < weaponStats.criticalHitChance
		if isCritical then
			damage = math.max(1, math.round(damage * weaponStats.criticalHitDamage))
		end

		-- Track last attacker for loot drops
		local lastAttacker = enemyModel:FindFirstChild("LastAttacker")
		if lastAttacker then
			lastAttacker.Value = player
		end

		enemyHumanoid:TakeDamage(damage)
		applyKnockback(humanoidRootPart, enemyRoot, weaponStats.knockback)
		totalDamage += damage
		hitCount += 1
		table.insert(hitData, { enemy = enemyModel, damage = damage, isCritical = isCritical })
	end

	if hitCount > 0 then
		APIService.GetEvent("VisualizeAttackHit"):FireClient(player, hitData)
	end

	return { success = hitCount > 0, cooldown = attackCooldown, damage = totalDamage, hitCount = hitCount }
end

return endpoint
