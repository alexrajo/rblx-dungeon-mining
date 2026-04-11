local plr = game.Players.LocalPlayer

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))

local HIT_DELAY = 0.27
local TIER_WARNING_DURATION = 1.35
local TIER_WARNING_RISE_OFFSET = 1.25
local TIER_WARNING_INITIAL_OFFSET = Vector3.new(0, 3.6, 0)

type TierWarningState = {
	gui: BillboardGui,
	version: number,
}

local mineAnim = Instance.new("Animation")
mineAnim.AnimationId = "rbxassetid://135782976252428"

local cachedCharacter: Model? = nil
local cachedTrack: AnimationTrack? = nil

local function getTrack(humanoid: Humanoid): AnimationTrack?
	local character = humanoid.Parent
	if character ~= cachedCharacter then
		cachedCharacter = character
		cachedTrack = nil
	end
	if cachedTrack == nil then
		local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5)
		if animator == nil then return nil end
		cachedTrack = animator:LoadAnimation(mineAnim)
		cachedTrack.Looped = false
		cachedTrack.Priority = Enum.AnimationPriority.Action
	end
	return cachedTrack
end

-- Per-node shake state (client-local)
local nodeOrigins: {[Instance]: CFrame} = {}
local shakeVersion: {[Instance]: number} = {}
local tierWarnings: {[Instance]: TierWarningState} = {}

local function getNodeCFrame(node: Instance): CFrame
	if node:IsA("Model") then
		return (node :: Model):GetPivot()
	end
	return (node :: BasePart).CFrame
end

local function setNodeCFrame(node: Instance, cf: CFrame)
	if node:IsA("Model") then
		(node :: Model):PivotTo(cf)
	else
		(node :: BasePart).CFrame = cf
	end
end

local function shakeNode(node: Instance)
	-- Store origin on first hit so rapid successive hits restore to the same position
	if not nodeOrigins[node] then
		nodeOrigins[node] = getNodeCFrame(node)
		node.Destroying:Connect(function()
			nodeOrigins[node] = nil
			shakeVersion[node] = nil
		end)
	end
	local origin = nodeOrigins[node]

	-- Bump version to cancel any in-progress shake
	local version = (shakeVersion[node] or 0) + 1
	shakeVersion[node] = version

	local STEPS = 3
	local MAGNITUDE = 0.15
	local STEP_TIME = 0.045

	for _ = 1, STEPS do
		if shakeVersion[node] ~= version then return end
		local offset = Vector3.new(
			(math.random() * 2 - 1) * MAGNITUDE,
			0,
			(math.random() * 2 - 1) * MAGNITUDE
		)
		setNodeCFrame(node, origin * CFrame.new(offset))
		task.wait(STEP_TIME)
	end

	if shakeVersion[node] == version then
		setNodeCFrame(node, origin)
	end
end

local function createTierWarningLabel(text: string, color: Color3, position: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0.5, 0)
	label.Position = position
	label.Font = Enum.Font.LuckiestGuy
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextTransparency = 0

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Parent = label

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 10
	constraint.MaxTextSize = 22
	constraint.Parent = label

	return label
end

local function clearTierWarning(node: Instance, gui: BillboardGui)
	local state = tierWarnings[node]
	if state and state.gui == gui then
		tierWarnings[node] = nil
	end
	if gui.Parent ~= nil then
		gui:Destroy()
	end
end

local function showTierWarning(node: Instance, requiredTier: number, pickaxeTier: number)
	local previousState = tierWarnings[node]
	local version = (previousState and previousState.version or 0) + 1
	if previousState then
		clearTierWarning(node, previousState.gui)
	end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "TierWarning"
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 0
	billboardGui.MaxDistance = 80
	billboardGui.Size = UDim2.fromOffset(200, 56)
	billboardGui.StudsOffset = TIER_WARNING_INITIAL_OFFSET
	billboardGui.Parent = node

	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromScale(1, 1)
	container.Parent = billboardGui

	local requiredLabel = createTierWarningLabel(
		string.format("Requires pickaxe tier %d", requiredTier),
		Color3.fromRGB(255, 214, 92),
		UDim2.fromScale(0, 0)
	)
	requiredLabel.Parent = container

	local currentLabel = createTierWarningLabel(
		string.format("Your pickaxe tier %d", pickaxeTier),
		Color3.fromRGB(255, 120, 120),
		UDim2.fromScale(0, 0.5)
	)
	currentLabel.Parent = container

	local state = {
		gui = billboardGui,
		version = version,
	}
	tierWarnings[node] = state

	local connection
	connection = node.Destroying:Connect(function()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		clearTierWarning(node, billboardGui)
	end)

	local riseTween = TweenService:Create(
		billboardGui,
		TweenInfo.new(TIER_WARNING_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = TIER_WARNING_INITIAL_OFFSET + Vector3.new(0, TIER_WARNING_RISE_OFFSET, 0) }
	)
	riseTween:Play()

	task.delay(0.6, function()
		local currentState = tierWarnings[node]
		if currentState == nil or currentState.version ~= version or currentState.gui ~= billboardGui then
			return
		end

		local fadeInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, descendant in ipairs(container:GetChildren()) do
			if descendant:IsA("TextLabel") then
				TweenService:Create(descendant, fadeInfo, { TextTransparency = 1 }):Play()
				local stroke = descendant:FindFirstChildOfClass("UIStroke")
				if stroke then
					TweenService:Create(stroke, fadeInfo, { Transparency = 1 }):Play()
				end
			end
		end
	end)

	task.delay(TIER_WARNING_DURATION, function()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		local currentState = tierWarnings[node]
		if currentState == nil or currentState.version ~= version or currentState.gui ~= billboardGui then
			return
		end
		clearTierWarning(node, billboardGui)
	end)
end

local MineAction = {}

function MineAction.Activate()
	local character = plr.Character
	if character == nil or character.Parent == nil then return 0.5 end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoidRootPart == nil or humanoid == nil or humanoid.Health <= 0 then return 0.5 end

	-- Play pickaxe swing animation
	local track = getTrack(humanoid)
	if track then
		track:Play()
	end

	-- Raycast forward from HumanoidRootPart in three directions to find an OreNode
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}

	local hrpCFrame = humanoidRootPart.CFrame
	local rayDirections = {
		hrpCFrame.LookVector,                                           -- straight ahead
		(hrpCFrame * CFrame.Angles(-math.rad(45), 0, 0)).LookVector,  -- 45° up
		(hrpCFrame * CFrame.Angles( math.rad(45), 0, 0)).LookVector,  -- 45° down
	}

	local targetNode = nil
	local hitPosition = nil

	for _, direction in ipairs(rayDirections) do
		local result = workspace:Raycast(humanoidRootPart.Position, direction * globalConfig.MINE_REACH_DISTANCE, raycastParams)
		if result then
			local current = result.Instance
			while current and current ~= workspace do
				if CollectionService:HasTag(current, "OreNode") then
					targetNode = current
					hitPosition = result.Position
					break
				end
				current = current.Parent
			end
		end
		if targetNode then break end
	end

	-- Spawn the hit-registration and server call in the background so the
	-- cooldown timer starts immediately regardless of server latency.
	if targetNode ~= nil then
		task.spawn(function()
			task.wait(HIT_DELAY)

			-- Re-validate: node may have been destroyed during the delay
			if targetNode.Parent == nil then return end

			task.spawn(shakeNode, targetNode)

			local func = APIService.GetFunction("Mine")
			local result = func:InvokeServer(targetNode, hitPosition)

			if result and result.reason == "tier_too_low" then
				showTierWarning(targetNode, result.requiredTier or 1, result.pickaxeTier or 1)
			end
		end)
	end

	return globalConfig.MINE_SWING_COOLDOWN
end

return MineAction
