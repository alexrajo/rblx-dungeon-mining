local HEAD_HEIGHT_OFFSET = 1.5
local HOVER_RESPONSE = 10
local MAX_VERTICAL_SPEED = 20
local ROOF_RAY_DISTANCE = 80
local ROOF_SURFACE_CLEARANCE = 0.05

local FlyingHover = {}

function FlyingHover.Init(context)
	context.state.hoverHeightOffset = context.enemy:GetAttribute("HoverHeightOffset") or HEAD_HEIGHT_OFFSET
	context.state.hoverResponse = context.enemy:GetAttribute("HoverResponse") or HOVER_RESPONSE
	context.state.maxVerticalSpeed = context.enemy:GetAttribute("MaxVerticalSpeed") or MAX_VERTICAL_SPEED
	context.state.roofRayDistance = context.enemy:GetAttribute("RoofRayDistance") or ROOF_RAY_DISTANCE
	context.state.roofSurfaceClearance = context.enemy:GetAttribute("RoofSurfaceClearance") or ROOF_SURFACE_CLEARANCE
end

local function zeroMovement(context)
	context.humanoid:Move(Vector3.zero)
	context.root.AssemblyLinearVelocity = Vector3.zero
	context.root.AssemblyAngularVelocity = Vector3.zero
end

function FlyingHover.EnterIdle(context)
	zeroMovement(context)
end

function FlyingHover.UpdateIdle(context, _dt)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { context.enemy }

	local raycastResult = context.workspace:Raycast(
		context.root.Position,
		Vector3.new(0, context.state.roofRayDistance, 0),
		raycastParams
	)

	if raycastResult == nil then
		context.root.Anchored = false
		zeroMovement(context)
		return
	end

	local rootHalfHeight = context.root.Size.Y / 2
	local surfaceOffset = rootHalfHeight + context.state.roofSurfaceClearance
	local targetPosition = raycastResult.Position + raycastResult.Normal * surfaceOffset

	context.root.Anchored = true
	context.root.CFrame = CFrame.new(targetPosition) * context.root.CFrame.Rotation
	zeroMovement(context)
end

function FlyingHover.ExitIdle(context)
	context.root.Anchored = false
	zeroMovement(context)
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
