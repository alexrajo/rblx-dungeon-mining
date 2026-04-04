local LEAP_INTERVAL = 1.1
local LEAP_HORIZONTAL_SPEED = 24
local LEAP_VERTICAL_SPEED = 32

local SlimeLeap = {}

function SlimeLeap.Init(context)
	context.state.nextLeapAt = 0
	context.state.leapInterval = context.enemy:GetAttribute("LeapInterval") or LEAP_INTERVAL
	context.state.leapHorizontalSpeed = context.enemy:GetAttribute("LeapHorizontalSpeed") or LEAP_HORIZONTAL_SPEED
	context.state.leapVerticalSpeed = context.enemy:GetAttribute("LeapVerticalSpeed") or LEAP_VERTICAL_SPEED
end

function SlimeLeap.Update(context, _dt, _targetCharacter, targetPosition)
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
	if now < context.state.nextLeapAt or distance <= 0.001 then
		context.humanoid:Move(Vector3.zero)
		return
	end

	context.state.nextLeapAt = now + context.state.leapInterval
	context.humanoid.Jump = true

	local horizontalVelocity = flatDiff.Unit * context.state.leapHorizontalSpeed
	context.root.AssemblyLinearVelocity = Vector3.new(
		horizontalVelocity.X,
		context.state.leapVerticalSpeed,
		horizontalVelocity.Z
	)
end

return SlimeLeap
