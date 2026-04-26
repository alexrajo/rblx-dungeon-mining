local WALK_HOP_INTERVAL = 0.7
local WALK_HOP_HORIZONTAL_SPEED = 10
local LEAP_VERTICAL_SPEED = 32

local SlimeLeap = {}

function SlimeLeap.Init(context)
	context.state.nextWalkHopAt = 0
	context.state.walkHopInterval = context.enemy:GetAttribute("WalkHopInterval") or WALK_HOP_INTERVAL
	context.state.walkHopHorizontalSpeed = context.enemy:GetAttribute("WalkHopHorizontalSpeed") or WALK_HOP_HORIZONTAL_SPEED
	context.state.leapVerticalSpeed = context.enemy:GetAttribute("LeapVerticalSpeed") or LEAP_VERTICAL_SPEED
end

function SlimeLeap.Update(context, _dt, _targetCharacter, targetPosition)
	if context.state.slimeAttackMovementLocked then
		context.humanoid:Move(Vector3.zero)
		return
	end

	if targetPosition == nil then
		context.humanoid:Move(Vector3.zero)
		return
	end

	local rootPosition = context.root.Position
	local flatDiff = Vector3.new(targetPosition.X - rootPosition.X, 0, targetPosition.Z - rootPosition.Z)
	local distance = flatDiff.Magnitude

	if distance <= context.stats.attackRange then
		context.humanoid:Move(Vector3.zero)
		return
	end

	local now = os.clock()
	if now < context.state.nextWalkHopAt or distance <= 0.001 then
		context.humanoid:Move(Vector3.zero)
		return
	end

	context.state.nextWalkHopAt = now + context.state.walkHopInterval
	context.humanoid.Jump = true

	local horizontalVelocity = flatDiff.Unit * context.state.walkHopHorizontalSpeed
	context.root.AssemblyLinearVelocity = Vector3.new(
		horizontalVelocity.X,
		context.state.leapVerticalSpeed,
		horizontalVelocity.Z
	)
end

return SlimeLeap
