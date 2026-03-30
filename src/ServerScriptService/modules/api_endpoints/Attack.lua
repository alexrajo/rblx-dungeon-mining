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

function endpoint.Call(player: Player, enemies: {Instance})
	if debounce[player] then return { success = false, cooldown = 0.1 } end

	if type(enemies) ~= "table" or #enemies == 0 then
		return { success = false, cooldown = 0.1 }
	end

	local character = player.Character
	if character == nil then return { success = false, cooldown = 0.5 } end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart == nil then return { success = false, cooldown = 0.5 } end

	-- Apply cooldown immediately to prevent spam
	debounce[player] = true
	task.delay(globalConfig.ATTACK_SWING_COOLDOWN, function()
		debounce[player] = nil
	end)

	-- Calculate attacker stats once for all hits
	local equippedWeapon = PlayerDataHandler.GetEquippedWeapon(player)
	local weaponTier = GearConfig.GetTierForItem(equippedWeapon) or 1
	local level = PlayerDataHandler.GetClient(player) and PlayerDataHandler.GetClient(player):GetDataValue("Level", 1) or 1

	local totalDamage = 0
	local hitCount = 0
	local hitData: {{enemy: Model, damage: number}} = {}

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

		local damage = math.max(1, StatCalculation.GetCombatDamage(weaponTier, level) - enemyDefense)

		-- Track last attacker for loot drops
		local lastAttacker = enemyModel:FindFirstChild("LastAttacker")
		if lastAttacker then
			lastAttacker.Value = player
		end

		enemyHumanoid:TakeDamage(damage)
		totalDamage += damage
		hitCount += 1
		table.insert(hitData, { enemy = enemyModel, damage = damage })
	end

	if hitCount > 0 then
		APIService.GetEvent("VisualizeAttackHit"):FireClient(player, hitData)
	end

	return { success = hitCount > 0, cooldown = globalConfig.ATTACK_SWING_COOLDOWN, damage = totalDamage, hitCount = hitCount }
end

return endpoint
