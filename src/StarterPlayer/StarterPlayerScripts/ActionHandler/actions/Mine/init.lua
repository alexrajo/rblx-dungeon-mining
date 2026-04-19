local plr = game.Players.LocalPlayer

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))

local HIT_DELAY = 0.27
local ORE_HIT_SOUND_IDS = {
	8666676588,
	8666677396,
	8666678078,
	8666678762,
	8666679694,
	8666680446,
	8666681117,
	8666681736,
	8666682639,
	8666683381,
	8666684072,
	8666684617,
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

local function getNodeCFrame(node: Instance): CFrame
	if node:IsA("BasePart") then
		return node.CFrame
	end

	if node:IsA("Model") then
		return node:GetPivot()
	end

	return CFrame.new()
end

local function setNodeCFrame(node: Instance, cf: CFrame)
	if node:IsA("BasePart") then
		node.CFrame = cf
	elseif node:IsA("Model") then
		node:PivotTo(cf)
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

local function playRandomOreHitSound()
	local soundId = ORE_HIT_SOUND_IDS[math.random(1, #ORE_HIT_SOUND_IDS)]
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	SoundService:PlayLocalSound(sound)

	task.spawn(function()
		sound.Ended:Wait()
		sound:Destroy()
	end)
end

local MineAction = {}

function MineAction.Activate(tool: Tool?)
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

	-- Raycast forward from HumanoidRootPart in three directions to find a mineable target.
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}

	local hrpCFrame = humanoidRootPart.CFrame
	local rayDirections = {
		hrpCFrame.LookVector,                                           -- straight ahead
		(hrpCFrame * CFrame.Angles(-math.rad(45), 0, 0)).LookVector,  -- 45° up
		(hrpCFrame * CFrame.Angles( math.rad(45), 0, 0)).LookVector,  -- 45° down
	}

	local targetNode: Instance? = nil
	local targetIsOreNode = false
	local hitPosition = nil

	for _, direction in ipairs(rayDirections) do
		local result = workspace:Raycast(humanoidRootPart.Position, direction * globalConfig.MINE_REACH_DISTANCE, raycastParams)
		if result then
			local current = result.Instance
			while current and current ~= workspace do
				local isOreNode = current:IsA("Model") and CollectionService:HasTag(current, "OreNode")
				local isMineCrate = CollectionService:HasTag(current, "MineCrate")
					and (current:IsA("Model") or current:IsA("BasePart"))
				if isOreNode or isMineCrate then
					targetNode = current
					targetIsOreNode = isOreNode
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
		if targetIsOreNode then
			playRandomOreHitSound()
		end

		task.spawn(function()
			task.wait(HIT_DELAY)

			-- Re-validate: node may have been destroyed during the delay
			if targetNode.Parent == nil then return end

			task.spawn(shakeNode, targetNode)

			local func = APIService.GetFunction("Mine")
			func:InvokeServer(tool, targetNode, hitPosition)
		end)
	end

	return globalConfig.MINE_SWING_COOLDOWN
end

return MineAction
