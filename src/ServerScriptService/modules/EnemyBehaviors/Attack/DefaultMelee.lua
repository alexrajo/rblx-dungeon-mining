local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local configs = ReplicatedStorage.configs
local HotbarConfig = require(configs.HotbarConfig)

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

local DefaultMelee = {}

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

function DefaultMelee.Init(context)
	context.state.nextAttackAt = 0
end

function DefaultMelee.Update(context, _dt, targetCharacter, targetPosition)
	if targetCharacter == nil or targetPosition == nil then
		return
	end

	local rootPosition = context.root.Position
	local distance = (targetPosition - rootPosition).Magnitude
	if distance > context.stats.attackRange then
		return
	end

	local now = os.clock()
	if now < context.state.nextAttackAt then
		return
	end

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if targetHumanoid == nil or targetHumanoid.Health <= 0 then
		return
	end

	local targetPlayer = context.players:GetPlayerFromCharacter(targetCharacter)
	if targetPlayer ~= nil and context.mineTransitionService.IsPlayerProtected(targetPlayer) then
		return
	end

	context.state.nextAttackAt = now + context.stats.attackInterval
	context:PlayAttackAnimation()

	local defense = targetPlayer ~= nil and getPlayerDefense(targetPlayer) or 0
	targetHumanoid:TakeDamage(math.max(1, context.stats.damage - defense))
end

return DefaultMelee
