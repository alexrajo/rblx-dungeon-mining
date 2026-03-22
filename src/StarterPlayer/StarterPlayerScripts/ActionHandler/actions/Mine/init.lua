local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))

local MineAction = {}

function MineAction.Activate()
	local character = plr.Character
	if character == nil or character.Parent == nil then return 0.5 end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoidRootPart == nil or humanoid == nil or humanoid.Health <= 0 then return 0.5 end

	-- Raycast from camera to find an OreNode
	local mouse = plr:GetMouse()
	local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}

	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * globalConfig.MINE_REACH_DISTANCE, raycastParams)
	if raycastResult == nil then return 0.2 end

	local hitInstance = raycastResult.Instance
	local hitPosition = raycastResult.Position

	-- Walk up the hierarchy to find a tagged OreNode
	local targetNode = nil
	local current = hitInstance
	while current and current ~= workspace do
		if CollectionService:HasTag(current, "OreNode") then
			targetNode = current
			break
		end
		current = current.Parent
	end

	if targetNode == nil then return 0.2 end

	-- TODO: Play pickaxe swing animation here

	-- Invoke server
	local func = APIService.GetFunction("Mine")
	local result = func:InvokeServer(targetNode, hitPosition)

	if result and result.cooldown then
		return result.cooldown
	end
	return globalConfig.MINE_SWING_COOLDOWN
end

return MineAction
