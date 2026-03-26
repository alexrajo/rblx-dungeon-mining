local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera

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

	-- Raycast from camera to find an OreNode
	local mouse = plr:GetMouse()
	local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}

	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * globalConfig.MINE_REACH_DISTANCE, raycastParams)

	local hitInstance = raycastResult and raycastResult.Instance
	local hitPosition = raycastResult and raycastResult.Position

	-- Walk up the hierarchy to find a tagged OreNode
	local targetNode = nil
	if hitInstance then
		local current = hitInstance
		while current and current ~= workspace do
			if CollectionService:HasTag(current, "OreNode") then
				targetNode = current
				break
			end
			current = current.Parent
		end
	end

	-- Delay hit registration to sync with animation
	task.wait(HIT_DELAY)

	-- No valid target — return 0 (delay already elapsed)
	if targetNode == nil then return 0 end

	-- Invoke server
	local func = APIService.GetFunction("Mine")
	local result = func:InvokeServer(targetNode, hitPosition)

	local cooldown = (result and result.cooldown) or globalConfig.MINE_SWING_COOLDOWN
	return math.max(0, cooldown - HIT_DELAY)
end

return MineAction
