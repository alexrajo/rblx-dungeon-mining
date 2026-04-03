local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local OreNodeService = require(modules.OreNodeService)

local configs = ReplicatedStorage.configs
local BombConfig = require(configs.BombConfig)

local BombService = {}

local function getInstancePosition(instance: Instance): Vector3?
	if instance:IsA("Model") then
		return instance:GetPivot().Position
	elseif instance:IsA("BasePart") then
		return instance.Position
	end

	return nil
end

local function getHorizontalDistance(origin: Vector3, target: Vector3): number
	local offset = target - origin
	return Vector2.new(offset.X, offset.Z).Magnitude
end

function BombService.CreatePlacedBombVisual(handleTemplate: Instance?, position: Vector3): BasePart?
	local visual = nil
	if handleTemplate ~= nil and handleTemplate:IsA("BasePart") then
		visual = handleTemplate:Clone()
	else
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(2, 2, 2)
		part.Color = Color3.fromRGB(36, 36, 36)
		part.Material = Enum.Material.Metal
		visual = part
	end

	visual.Name = "PlacedBomb"
	visual.Anchored = true
	visual.CanCollide = false
	visual.AssemblyLinearVelocity = Vector3.zero
	visual.AssemblyAngularVelocity = Vector3.zero
	visual.CFrame = CFrame.new(position + Vector3.new(0, visual.Size.Y * 0.5, 0))
	visual.Parent = workspace

	return visual
end

function BombService.ResolveExplosion(player: Player, bombItemName: string, position: Vector3, floorNumber: number)
	local bombData = BombConfig.GetBombData(bombItemName)
	if bombData == nil then
		return
	end

	for _, nodeInstance in ipairs(CollectionService:GetTagged("OreNode")) do
		if nodeInstance.Parent == nil then
			continue
		end

		if nodeInstance:GetAttribute("FloorNumber") ~= floorNumber then
			continue
		end

		local nodePosition = getInstancePosition(nodeInstance)
		if nodePosition == nil then
			continue
		end

		if getHorizontalDistance(position, nodePosition) <= bombData.radius then
			OreNodeService.BreakNode(player, nodeInstance)
		end
	end

	for _, enemyModel in ipairs(CollectionService:GetTagged("Enemy")) do
		if enemyModel.Parent == nil then
			continue
		end

		if enemyModel:GetAttribute("FloorNumber") ~= floorNumber then
			continue
		end

		local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
		if humanoid == nil or humanoid.Health <= 0 then
			continue
		end

		local enemyPosition = getInstancePosition(enemyModel)
		if enemyPosition == nil then
			continue
		end

		local distance = getHorizontalDistance(position, enemyPosition)
		if distance > bombData.radius then
			continue
		end

		local falloffAlpha = 1 - (distance / bombData.radius)
		local damage = math.max(1, math.round(bombData.enemyDamage * falloffAlpha))

		local lastAttacker = enemyModel:FindFirstChild("LastAttacker")
		if lastAttacker then
			lastAttacker.Value = player
		end

		humanoid:TakeDamage(damage)
	end
end

return BombService
