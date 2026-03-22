local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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

function endpoint.Call(player: Player, targetInstance: Instance)
	if debounce[player] then return { success = false, cooldown = 0.1 } end

	-- Validate target
	if targetInstance == nil or targetInstance.Parent == nil then
		return { success = false, cooldown = 0.1 }
	end

	-- Find the Enemy-tagged ancestor
	local enemyModel = nil
	local current = targetInstance
	while current and current ~= workspace do
		if CollectionService:HasTag(current, "Enemy") then
			enemyModel = current
			break
		end
		current = current.Parent
	end
	if enemyModel == nil then return { success = false, cooldown = 0.1 } end

	-- Validate player character and range
	local character = player.Character
	if character == nil then return { success = false, cooldown = 0.5 } end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart == nil then return { success = false, cooldown = 0.5 } end

	local enemyRoot = enemyModel:FindFirstChild("HumanoidRootPart")
	if enemyRoot == nil then return { success = false, cooldown = 0.5 } end

	local distance = (enemyRoot.Position - humanoidRootPart.Position).Magnitude
	if distance > globalConfig.ATTACK_REACH_DISTANCE then
		return { success = false, cooldown = 0.1 }
	end

	-- Validate enemy is alive
	local enemyHumanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	if enemyHumanoid == nil or enemyHumanoid.Health <= 0 then
		return { success = false, cooldown = 0.1 }
	end

	-- Apply cooldown
	debounce[player] = true
	task.delay(globalConfig.ATTACK_SWING_COOLDOWN, function()
		debounce[player] = nil
	end)

	-- Calculate damage
	local equippedWeapon = PlayerDataHandler.GetEquippedWeapon(player)
	local weaponTier = GearConfig.GetTierForItem(equippedWeapon) or 1
	local level = PlayerDataHandler.GetClient(player) and PlayerDataHandler.GetClient(player):GetDataValue("Level", 1) or 1

	local enemyType = enemyModel:GetAttribute("EnemyType") or "Cave Slime"
	local enemyData = EnemyConfig[enemyType]
	local enemyDefense = 0
	if enemyData then
		enemyDefense = enemyData.defense
	end

	local damage = math.max(1, StatCalculation.GetCombatDamage(weaponTier, level) - enemyDefense)

	-- Track last attacker for loot drops
	local lastAttacker = enemyModel:FindFirstChild("LastAttacker")
	if lastAttacker then
		lastAttacker.Value = player
	end

	enemyHumanoid:TakeDamage(damage)

	return { success = true, cooldown = globalConfig.ATTACK_SWING_COOLDOWN, damage = damage }
end

return endpoint
