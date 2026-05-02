local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local APIService = require(ReplicatedStorage.services.APIService)

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local HotbarToolValidator = require(modules.HotbarToolValidator)
local BuffsManager = require(modules.BuffsManager)
local CrateService = require(modules.CrateService)
local BossEnemyService = require(modules.BossEnemyService)

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

local configs = ReplicatedStorage.configs
local GearConfig = require(configs.GearConfig)
local EnemyConfig = require(configs.EnemyConfig)
local globalConfig = require(ReplicatedStorage.GlobalConfig)

-- Timestamp-based per-player cooldown. Keyed by Player instance so entries
-- are automatically distinct across sessions; cleaned up on PlayerRemoving.
local lastAttackTime: {[Player]: number} = {}

Players.PlayerRemoving:Connect(function(player)
	lastAttackTime[player] = nil
end)

local endpoint = {}

local function findTaggedAncestor(instance: Instance, tagName: string): Instance?
	local current = instance
	while current and current ~= workspace do
		if CollectionService:HasTag(current, tagName) then
			return current
		end
		current = current.Parent
	end

	return nil
end

local function isOnPlayerFloor(player: Player, instance: Instance): boolean
	local floorNumber = instance:GetAttribute("FloorNumber")
	return type(floorNumber) ~= "number" or PlayerDataHandler.GetCurrentFloor(player) == floorNumber
end

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

function endpoint.Call(player: Player, tool: Instance?, enemies: {Instance})
	if type(enemies) ~= "table" then
		return { success = false, cooldown = 0.1 }
	end

	local validTool, weaponItemName, toolReason = HotbarToolValidator.Validate(player, tool, "Attack", "Weapon")
	if not validTool or weaponItemName == nil then
		return { success = false, cooldown = 0.1, reason = toolReason }
	end

	local character = player.Character
	if character == nil then return { success = false, cooldown = 0.5 } end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart == nil then return { success = false, cooldown = 0.5 } end

	-- Compute weapon cooldown first so it can be used in the server-side window check.
	local weaponStats = GearConfig.GetWeaponCombatStats(weaponItemName)
	local attackCooldown = weaponStats.attackCooldown or globalConfig.ATTACK_SWING_COOLDOWN

	local now = os.clock()
	local serverWindow = attackCooldown - globalConfig.SERVER_ACTION_LENIENCY
	if lastAttackTime[player] and (now - lastAttackTime[player]) < serverWindow then
		return { success = false, cooldown = 0.1 }
	end
	lastAttackTime[player] = os.clock()

	-- Calculate attacker stats once for all hits
	local level = PlayerDataHandler.GetClient(player) and PlayerDataHandler.GetClient(player):GetDataValue("Level", 1) or 1
	local baseCombatDamage = StatCalculation.GetCombatDamage(weaponItemName, level)
		* BuffsManager.GetDamageMultiplier(player)

	local totalDamage = 0
	local hitCount = 0
	local hitData: {{enemy: Model, damage: number, isCritical: boolean}} = {}

	for _, targetInstance in ipairs(enemies) do
		if targetInstance == nil or targetInstance.Parent == nil then continue end

		local crateInstance = findTaggedAncestor(targetInstance, "MineCrate")
		if crateInstance ~= nil then
			if not isOnPlayerFloor(player, crateInstance) then
				continue
			end

			local cratePosition = CrateService.GetPosition(crateInstance)
			local distance = (cratePosition - humanoidRootPart.Position).Magnitude
			if distance > globalConfig.ATTACK_REACH_DISTANCE then
				continue
			end

			if CrateService.BreakCrate(player, crateInstance) then
				hitCount += 1
			end
			continue
		end

		-- Confirm Enemy tag (server re-validates client claim)
		local enemyModel = findTaggedAncestor(targetInstance, "Enemy")
		if enemyModel == nil then continue end
		if not isOnPlayerFloor(player, enemyModel) then
			continue
		end

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

		BossEnemyService.RecordDamage(enemyModel :: Model, player, damage)
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
