local plr = game.Players.LocalPlayer

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))

local HIT_DELAY = 0.27

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

	-- Delay hit registration to sync with animation
	task.wait(HIT_DELAY)

	-- No valid target — return 0 (delay already elapsed)
	if targetNode == nil then return 0 end

	-- Play local shake animation on the hit node
	task.spawn(shakeNode, targetNode)

	-- Invoke server
	local func = APIService.GetFunction("Mine")
	local result = func:InvokeServer(targetNode, hitPosition)

	local cooldown = (result and result.cooldown) or globalConfig.MINE_SWING_COOLDOWN
	return math.max(0, cooldown - HIT_DELAY)
end

return MineAction
