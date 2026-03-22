local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))

local AttackAction = {}

function AttackAction.Activate()
	local character = plr.Character
	if character == nil or character.Parent == nil then return 0.5 end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoidRootPart == nil or humanoid == nil or humanoid.Health <= 0 then return 0.5 end

	-- Raycast from camera to find an Enemy
	local mouse = plr:GetMouse()
	local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}

	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * globalConfig.ATTACK_REACH_DISTANCE, raycastParams)
	if raycastResult == nil then return 0.2 end

	local hitInstance = raycastResult.Instance

	-- Walk up the hierarchy to find a tagged Enemy
	local targetEnemy = nil
	local current = hitInstance
	while current and current ~= workspace do
		if CollectionService:HasTag(current, "Enemy") then
			targetEnemy = current
			break
		end
		current = current.Parent
	end

	if targetEnemy == nil then return 0.2 end

	-- TODO: Play weapon swing animation here

	-- Invoke server
	local func = APIService.GetFunction("Attack")
	local result = func:InvokeServer(targetEnemy)

	if result and result.cooldown then
		return result.cooldown
	end
	return globalConfig.ATTACK_SWING_COOLDOWN
end

return AttackAction
