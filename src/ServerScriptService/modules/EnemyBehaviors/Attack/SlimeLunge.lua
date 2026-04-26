local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local HotbarConfig = require(configs.HotbarConfig)

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

local CHARGE_DURATION = 0.35
local LUNGE_HORIZONTAL_SPEED = 44
local LUNGE_VERTICAL_SPEED = 32
local LUNGE_HIT_WINDOW = 0.35

local SlimeLunge = {}

local function getEquippedArmorItemName(player: Player, slotName: string): string
	local armor = PlayerDataHandler.GetEquippedArmor(player)
	local entryId = armor[slotName]
	if type(entryId) ~= "string" or entryId == "" then
		return ""
	end

	return HotbarConfig.ResolveEntryItemName(entryId, {
		Inventory = PlayerDataHandler.GetInventory(player),
	})
end

local function getPlayerDefense(player: Player): number
	return StatCalculation.GetPlayerDefense(
		getEquippedArmorItemName(player, "Helmet"),
		getEquippedArmorItemName(player, "Chestplate"),
		getEquippedArmorItemName(player, "Leggings"),
		getEquippedArmorItemName(player, "Boots")
	)
end

local function getTargetParts(targetCharacter: Model?): (Humanoid?, BasePart?)
	if targetCharacter == nil then
		return nil, nil
	end

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	if targetHumanoid == nil or targetHumanoid.Health <= 0 or targetRoot == nil or not targetRoot:IsA("BasePart") then
		return nil, nil
	end

	return targetHumanoid, targetRoot
end

local function isTargetProtected(context, targetCharacter: Model): boolean
	local targetPlayer = context.players:GetPlayerFromCharacter(targetCharacter)
	return targetPlayer ~= nil and context.mineTransitionService.IsPlayerProtected(targetPlayer)
end

local function damageTarget(context, targetCharacter: Model, targetHumanoid: Humanoid)
	local targetPlayer = context.players:GetPlayerFromCharacter(targetCharacter)
	local defense = targetPlayer ~= nil and getPlayerDefense(targetPlayer) or 0
	targetHumanoid:TakeDamage(math.max(1, context.stats.damage - defense))
end

local function clearAttackMovementLock(context)
	context.state.slimeAttackMovementLocked = false
end

local function resetAttack(context, now: number)
	context.state.slimeAttackPhase = "idle"
	context.state.nextAttackAt = now + context.stats.attackInterval
	clearAttackMovementLock(context)
end

function SlimeLunge.Init(context)
	context.state.nextAttackAt = 0
	context.state.slimeAttackPhase = "idle"
	context.state.slimeAttackMovementLocked = false
	context.state.attackChargeDuration = context.enemy:GetAttribute("AttackChargeDuration") or CHARGE_DURATION
	context.state.attackLungeHorizontalSpeed = context.enemy:GetAttribute("AttackLungeHorizontalSpeed") or LUNGE_HORIZONTAL_SPEED
	context.state.attackLungeVerticalSpeed = context.state.leapVerticalSpeed
		or context.enemy:GetAttribute("LeapVerticalSpeed")
		or LUNGE_VERTICAL_SPEED
	context.state.attackLungeHitWindow = context.enemy:GetAttribute("AttackLungeHitWindow") or LUNGE_HIT_WINDOW
	context.state.attackHitRange = context.enemy:GetAttribute("AttackHitRange") or context.stats.attackRange
end

function SlimeLunge.Update(context, _dt, targetCharacter, targetPosition)
	local now = os.clock()
	local phase = context.state.slimeAttackPhase

	if phase == "charging" then
		context.humanoid:Move(Vector3.zero)
		context.root.AssemblyLinearVelocity = Vector3.new(0, context.root.AssemblyLinearVelocity.Y, 0)

		if now < context.state.slimeChargeReleaseAt then
			return
		end

		local targetHumanoid, targetRoot = getTargetParts(targetCharacter)
		if targetHumanoid == nil or targetRoot == nil or isTargetProtected(context, targetCharacter) then
			resetAttack(context, now)
			return
		end

		local rootPosition = context.root.Position
		local flatDiff = Vector3.new(targetRoot.Position.X - rootPosition.X, 0, targetRoot.Position.Z - rootPosition.Z)
		if flatDiff.Magnitude <= 0.001 then
			resetAttack(context, now)
			return
		end

		local horizontalVelocity = flatDiff.Unit * context.state.attackLungeHorizontalSpeed
		context.humanoid.Jump = true
		context.root.AssemblyLinearVelocity = Vector3.new(
			horizontalVelocity.X,
			context.state.attackLungeVerticalSpeed,
			horizontalVelocity.Z
		)

		context.state.slimeAttackPhase = "lunging"
		context.state.slimeLungeEndsAt = now + context.state.attackLungeHitWindow
		context.state.slimeLungeHasHit = false
		return
	end

	if phase == "lunging" then
		if now > context.state.slimeLungeEndsAt then
			resetAttack(context, now)
			return
		end

		if context.state.slimeLungeHasHit then
			return
		end

		local targetHumanoid, targetRoot = getTargetParts(targetCharacter)
		if targetHumanoid == nil or targetRoot == nil or isTargetProtected(context, targetCharacter) then
			return
		end

		local distance = (targetRoot.Position - context.root.Position).Magnitude
		if distance <= context.state.attackHitRange then
			context.state.slimeLungeHasHit = true
			damageTarget(context, targetCharacter, targetHumanoid)
		end

		return
	end

	clearAttackMovementLock(context)
	if targetCharacter == nil or targetPosition == nil or now < context.state.nextAttackAt then
		return
	end

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if targetHumanoid == nil or targetHumanoid.Health <= 0 or isTargetProtected(context, targetCharacter) then
		return
	end

	local distance = (targetPosition - context.root.Position).Magnitude
	if distance > context.stats.attackRange then
		return
	end

	context.state.slimeAttackPhase = "charging"
	context.state.slimeAttackMovementLocked = true
	context.state.slimeChargeReleaseAt = now + context.state.attackChargeDuration
	context.humanoid:Move(Vector3.zero)
	context:PlayAttackAnimation()
end

function SlimeLunge.Cleanup(context)
	clearAttackMovementLock(context)
end

return SlimeLunge
