local HEAD_HEIGHT_OFFSET = 1.5
local HOVER_RESPONSE = 10
local MAX_VERTICAL_SPEED = 20

local FlyingHover = {}

function FlyingHover.Init(context)
	context.state.hoverHeightOffset = context.enemy:GetAttribute("HoverHeightOffset") or HEAD_HEIGHT_OFFSET
	context.state.hoverResponse = context.enemy:GetAttribute("HoverResponse") or HOVER_RESPONSE
	context.state.maxVerticalSpeed = context.enemy:GetAttribute("MaxVerticalSpeed") or MAX_VERTICAL_SPEED
end

function FlyingHover.Update(context, _dt, targetCharacter, targetPosition)
	if targetPosition == nil then
		context.humanoid:Move(Vector3.zero)
		return
	end

	local horizontalTarget = Vector3.new(targetPosition.X, context.root.Position.Y, targetPosition.Z)
	local horizontalDiff = horizontalTarget - context.root.Position
	if horizontalDiff.Magnitude > 0.001 then
		context.humanoid:Move(horizontalDiff.Unit)
	else
		context.humanoid:Move(Vector3.zero)
	end

	local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	if targetRoot == nil or targetHumanoid == nil then
		return
	end

	local targetHeight = targetRoot.Position.Y + targetHumanoid.HipHeight + context.state.hoverHeightOffset
	local heightError = targetHeight - context.root.Position.Y
	local desiredYVelocity = math.clamp(
		heightError * context.state.hoverResponse,
		-context.state.maxVerticalSpeed,
		context.state.maxVerticalSpeed
	)

	local velocity = context.root.AssemblyLinearVelocity
	context.root.AssemblyLinearVelocity = Vector3.new(velocity.X, desiredYVelocity, velocity.Z)
end

return FlyingHover
