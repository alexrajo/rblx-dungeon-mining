local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local globalConfig = require(ReplicatedStorage.GlobalConfig)

local BossEnemyService = {}

local DAMAGE_LOG_NAME = "DamageLog"
local DEFAULT_BOSS_ENEMY = "Cave Slime"

local function getEnemyRefsFolder(): Instance?
	local npcsFolder = ServerStorage:FindFirstChild("NPCs")
	if npcsFolder == nil then
		return nil
	end

	return npcsFolder:FindFirstChild("Enemies")
end

local function createFallbackEnemy(enemyType: string): Model
	local enemyModel = Instance.new("Model")
	enemyModel.Name = enemyType

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.BrickColor = BrickColor.new("Bright red")
	rootPart.Parent = enemyModel
	enemyModel.PrimaryPart = rootPart

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = enemyModel

	return enemyModel
end

local function createEnemyModel(enemyType: string): Model
	local enemyRefsFolder = getEnemyRefsFolder()
	local enemyRef = if enemyRefsFolder ~= nil then enemyRefsFolder:FindFirstChild(enemyType) else nil
	if enemyRef == nil or not enemyRef:IsA("Model") or enemyRef:FindFirstChild("HumanoidRootPart") == nil then
		return createFallbackEnemy(enemyType)
	end

	return enemyRef:Clone()
end

local function ensureDamageLog(enemyModel: Model): Folder
	local damageLog = enemyModel:FindFirstChild(DAMAGE_LOG_NAME)
	if damageLog ~= nil and damageLog:IsA("Folder") then
		return damageLog
	end

	if damageLog ~= nil then
		damageLog:Destroy()
	end

	local newDamageLog = Instance.new("Folder")
	newDamageLog.Name = DAMAGE_LOG_NAME
	newDamageLog.Parent = enemyModel
	return newDamageLog
end

local function getRootPart(enemyModel: Model): BasePart?
	local rootPart = enemyModel:FindFirstChild("HumanoidRootPart")
	if rootPart ~= nil and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

function BossEnemyService.IsBossEnemy(enemyModel: Instance?): boolean
	return enemyModel ~= nil and enemyModel:GetAttribute("isBossEnemy") == true
end

function BossEnemyService.ConfigureBoss(enemyModel: Model)
	enemyModel:SetAttribute("isBossEnemy", true)
	ensureDamageLog(enemyModel)
end

function BossEnemyService.RecordDamage(enemyModel: Model, player: Player, damage: number)
	if not BossEnemyService.IsBossEnemy(enemyModel) then
		return
	end
	if player.Parent == nil or damage <= 0 then
		return
	end

	local damageLog = ensureDamageLog(enemyModel)
	local contributorKey = tostring(player.UserId)
	local contributorFolder = damageLog:FindFirstChild(contributorKey)
	if contributorFolder == nil or not contributorFolder:IsA("Folder") then
		if contributorFolder ~= nil then
			contributorFolder:Destroy()
		end
		contributorFolder = Instance.new("Folder")
		contributorFolder.Name = contributorKey
		contributorFolder.Parent = damageLog
	end

	local playerValue = contributorFolder:FindFirstChild("Player")
	if playerValue == nil or not playerValue:IsA("ObjectValue") then
		if playerValue ~= nil then
			playerValue:Destroy()
		end
		playerValue = Instance.new("ObjectValue")
		playerValue.Name = "Player"
		playerValue.Parent = contributorFolder
	end
	playerValue.Value = player

	local damageValue = contributorFolder:FindFirstChild("Damage")
	if damageValue == nil or not damageValue:IsA("NumberValue") then
		if damageValue ~= nil then
			damageValue:Destroy()
		end
		damageValue = Instance.new("NumberValue")
		damageValue.Name = "Damage"
		damageValue.Parent = contributorFolder
	end
	damageValue.Value += damage
end

function BossEnemyService.GetContributors(enemyModel: Model): {Player}
	local contributors = {}
	local seenPlayers: {[Player]: boolean} = {}
	local damageLog = enemyModel:FindFirstChild(DAMAGE_LOG_NAME)
	if damageLog == nil or not damageLog:IsA("Folder") then
		return contributors
	end

	for _, entry in ipairs(damageLog:GetChildren()) do
		if not entry:IsA("Folder") then
			continue
		end

		local playerValue = entry:FindFirstChild("Player")
		local damageValue = entry:FindFirstChild("Damage")
		if playerValue == nil or not playerValue:IsA("ObjectValue") then
			continue
		end
		if damageValue == nil or not damageValue:IsA("NumberValue") or damageValue.Value <= 0 then
			continue
		end

		local player = playerValue.Value
		if player ~= nil and player:IsA("Player") and player.Parent ~= nil and not seenPlayers[player] then
			seenPlayers[player] = true
			table.insert(contributors, player)
		end
	end

	return contributors
end

local function spawnBossAtCFrame(parent: Instance, enemyType: string, floorNumber: number, spawnCFrame: CFrame): Model?
	local resolvedEnemyType = if type(enemyType) == "string" and enemyType ~= "" then enemyType else DEFAULT_BOSS_ENEMY
	local enemyModel = createEnemyModel(resolvedEnemyType)
	local rootPart = getRootPart(enemyModel)
	if rootPart == nil then
		warn("BossEnemyService: Boss enemy is missing HumanoidRootPart", resolvedEnemyType)
		enemyModel:Destroy()
		return nil
	end

	enemyModel.Name = resolvedEnemyType .. "Boss"
	enemyModel:SetAttribute("FloorNumber", floorNumber)
	enemyModel:SetAttribute("EnemyType", resolvedEnemyType)
	enemyModel:SetAttribute("BossSpawnCFrame", spawnCFrame)
	BossEnemyService.ConfigureBoss(enemyModel)
	enemyModel:PivotTo(spawnCFrame)
	enemyModel.Parent = parent
	CollectionService:AddTag(enemyModel, "Enemy")

	return enemyModel
end

function BossEnemyService.SpawnBoss(parent: Instance, enemyType: string?, floorNumber: number, spawnPart: BasePart): Model?
	local resolvedEnemyType = if type(enemyType) == "string" and enemyType ~= "" then enemyType else DEFAULT_BOSS_ENEMY
	local enemyModel = createEnemyModel(resolvedEnemyType)
	local rootPart = getRootPart(enemyModel)
	if rootPart == nil then
		warn("BossEnemyService: Boss enemy is missing HumanoidRootPart", resolvedEnemyType)
		enemyModel:Destroy()
		return nil
	end
	local rootSize = rootPart.Size
	enemyModel:Destroy()

	local spawnPosition = spawnPart.Position + Vector3.new(0, (spawnPart.Size.Y / 2) + (rootSize.Y / 2) + 0.1, 0)
	return spawnBossAtCFrame(parent, resolvedEnemyType, floorNumber, CFrame.new(spawnPosition))
end

function BossEnemyService.ScheduleRespawn(deadBoss: Model)
	if not BossEnemyService.IsBossEnemy(deadBoss) then
		return
	end

	local parent = deadBoss.Parent
	local enemyType = deadBoss:GetAttribute("EnemyType")
	local floorNumber = deadBoss:GetAttribute("FloorNumber")
	local spawnCFrame = deadBoss:GetAttribute("BossSpawnCFrame")
	if parent == nil or type(enemyType) ~= "string" or type(floorNumber) ~= "number" or typeof(spawnCFrame) ~= "CFrame" then
		return
	end

	task.delay(globalConfig.BOSS_RESPAWN_TIME or 60, function()
		if parent.Parent == nil then
			return
		end

		spawnBossAtCFrame(parent, enemyType, floorNumber, spawnCFrame)
	end)
end

return BossEnemyService
