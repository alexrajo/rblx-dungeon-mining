local DefaultGround = {}

function DefaultGround.Update(context, _dt, _targetCharacter, targetPosition)
	if targetPosition == nil then
		context.humanoid:Move(Vector3.zero)
		return
	end

	local rootPosition = context.root.Position
	local diff = Vector3.new(targetPosition.X - rootPosition.X, 0, targetPosition.Z - rootPosition.Z)
	if diff.Magnitude <= 0.001 then
		context.humanoid:Move(Vector3.zero)
		return
	end

	context.humanoid:Move(diff.Unit)
end

return DefaultGround
