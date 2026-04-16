local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local OreNodeUtil = require(modules.OreNodeUtil)

local configs = ReplicatedStorage.configs
local OreConfig = require(configs.OreConfig)

local TagHandler = {}

local function createLadder(position: Vector3, parent: Instance, floorNumber: number?)
	local ladder = Instance.new("Part")
	ladder.Name = "Ladder"
	ladder.Size = Vector3.new(4, 6, 4)
	ladder.Position = position
	ladder.Anchored = true
	ladder.Material = Enum.Material.Wood
	ladder.BrickColor = BrickColor.new("Brown")
	if floorNumber ~= nil then
		ladder:SetAttribute("FloorNumber", floorNumber)
	end
	ladder:SetAttribute("LadderAction", "descend")
	ladder:SetAttribute("LadderVariant", "descending")
	CollectionService:AddTag(ladder, "MineLadder")
	ladder.Parent = parent

	return ladder
end

function TagHandler.Apply(instance: Instance)
	if not instance:IsA("Model") then
		warn("OreNode tag can only be applied to Model instances", instance:GetFullName())
		return
	end

	local nodeModel = instance :: Model
	if OreNodeUtil.EnsurePrimaryPart(nodeModel) == nil then
		return
	end

	-- Read ore type and set defaults from config if needed
	local oreType = nodeModel:GetAttribute("OreType") or "Stone"
	local oreData = OreConfig.byName[oreType]

	if oreData then
		if nodeModel:GetAttribute("TierRequired") == nil then
			nodeModel:SetAttribute("TierRequired", oreData.minPickaxeTier)
		end
		if nodeModel:GetAttribute("NodeHP") == nil then
			nodeModel:SetAttribute("NodeHP", oreData.nodeHP)
		end
		if nodeModel:GetAttribute("DropType") == nil then
			nodeModel:SetAttribute("DropType", oreType .. "Node")
		end
	end

	-- Initialize current HP
	local maxHP = nodeModel:GetAttribute("NodeHP") or 4
	nodeModel:SetAttribute("CurrentHP", maxHP)

	if nodeModel:FindFirstChild("NodeBreak") ~= nil then
		return
	end

	-- Create a BindableEvent for the server Mine endpoint to signal when the node breaks
	local breakEvent = Instance.new("BindableEvent")
	breakEvent.Name = "NodeBreak"
	breakEvent.Parent = nodeModel

	local breakConnection
	breakConnection = breakEvent.Event:Connect(function()
		if breakConnection then
			breakConnection:Disconnect()
			breakConnection = nil
		end

		local originalParent = nodeModel.Parent
		local revealPosition = nodeModel:GetPivot().Position + Vector3.new(0, 3, 0)
		local floorNumber = nodeModel:GetAttribute("FloorNumber")

		if nodeModel:GetAttribute("RevealsLadder") and originalParent and originalParent.Parent then
			createLadder(revealPosition, originalParent, floorNumber)
		end

		nodeModel:Destroy()
	end)
end

return TagHandler
