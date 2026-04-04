local DefaultMelee = {}

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
	targetHumanoid:TakeDamage(context.stats.damage)
end

return DefaultMelee
