local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalConfig = require(ReplicatedStorage.GlobalConfig)
local ActionTargeting = {}

function ActionTargeting.GetPosition(target: Instance): Vector3?
	if target:IsA("Model") then return target:GetPivot().Position end
	if target:IsA("BasePart") then return target.Position end
	return nil
end

function ActionTargeting.FindTaggedAncestor(instance: Instance?, tag: string): Instance?
	local current = instance
	while current and current ~= workspace do
		if CollectionService:HasTag(current, tag) then return current end
		current = current.Parent
	end
	return nil
end

function ActionTargeting.IsInRange(root: BasePart, target: Instance, reach: number): boolean
	local position = ActionTargeting.GetPosition(target)
	if CollectionService:HasTag(target, "Enemy") then
		local enemyRoot = target:FindFirstChild("HumanoidRootPart")
		position = enemyRoot and enemyRoot:IsA("BasePart") and enemyRoot.Position or nil
	end
	return position ~= nil and (position - root.Position).Magnitude <= reach
end

function ActionTargeting.FindMineTarget(character: Model, root: BasePart, floor: number): (Instance?, Vector3?)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	for _, angle in ipairs({0, -45, 45}) do
		local direction = (root.CFrame * CFrame.Angles(math.rad(angle), 0, 0)).LookVector
		local hit = workspace:Raycast(root.Position, direction * GlobalConfig.MINE_REACH_DISTANCE, params)
		if hit then
			local target = ActionTargeting.FindTaggedAncestor(hit.Instance, "OreNode")
				or ActionTargeting.FindTaggedAncestor(hit.Instance, "MineCrate")
			if target and not target:GetAttribute("Broken")
				and (target:GetAttribute("FloorNumber") == nil or target:GetAttribute("FloorNumber") == floor)
				and ActionTargeting.IsInRange(root, target, GlobalConfig.MINE_REACH_DISTANCE) then
				return target, hit.Position
			end
		end
	end
	return nil, nil
end

function ActionTargeting.FindAttackTargets(character: Model, root: BasePart, floor: number): {Instance}
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	local targets, seen = {}, {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(root.Position, GlobalConfig.ATTACK_REACH_DISTANCE, params)) do
		local target = ActionTargeting.FindTaggedAncestor(part, "Enemy")
			or ActionTargeting.FindTaggedAncestor(part, "MineCrate")
		if target and not seen[target] and not target:GetAttribute("Broken")
			and (target:GetAttribute("FloorNumber") == nil or target:GetAttribute("FloorNumber") == floor)
			and ActionTargeting.IsInRange(root, target, GlobalConfig.ATTACK_REACH_DISTANCE) then
			local position = ActionTargeting.GetPosition(target)
			local offset = position and position - root.Position
			if offset and offset.Magnitude > 0 and offset.Unit:Dot(root.CFrame.LookVector) >= 0 then
				seen[target] = true
				table.insert(targets, target)
			end
		end
	end
	return targets
end

return ActionTargeting
