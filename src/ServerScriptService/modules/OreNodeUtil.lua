local ServerStorage = game:GetService("ServerStorage")

local OreNodeUtil = {}

local ORE_NODE_FLOOR_OFFSET = Vector3.new(0, 4, 0)

function OreNodeUtil.GetFloorPlacementPosition(floorPosition: Vector3): Vector3
	return floorPosition - ORE_NODE_FLOOR_OFFSET
end

function OreNodeUtil.GetRef(oreType: string): Model?
	local refsFolder = ServerStorage:FindFirstChild("OreNodeRefs")
	if refsFolder == nil then
		warn("OreNodeUtil: Missing ServerStorage.OreNodeRefs")
		return nil
	end

	local ref = refsFolder:FindFirstChild(oreType)
	if ref == nil then
		warn("OreNodeUtil: Missing ore node ref for ore type", oreType)
		return nil
	end

	if not ref:IsA("Model") then
		warn("OreNodeUtil: Ore node ref must be a Model", oreType)
		return nil
	end

	return ref
end

function OreNodeUtil.EnsurePrimaryPart(model: Model): BasePart?
	if model.PrimaryPart ~= nil then
		return model.PrimaryPart
	end

	local root = model:FindFirstChild("Root")
	if root ~= nil and root:IsA("BasePart") then
		model.PrimaryPart = root
		warn("OreNodeUtil: Ore node model had no PrimaryPart; using Root", model.Name)
		return root
	end

	warn("OreNodeUtil: Ore node model is missing Root BasePart", model.Name)
	return nil
end

function OreNodeUtil.AnchorModel(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
end

function OreNodeUtil.GetPosition(model: Model): Vector3
	return model:GetPivot().Position
end

function OreNodeUtil.ApplyAttributes(model: Model, floorNumber: number, oreType: string, oreData: any)
	model:SetAttribute("FloorNumber", floorNumber)
	model:SetAttribute("OreType", oreType)
	model:SetAttribute("NodeHP", oreData.nodeHP)
end

return OreNodeUtil
