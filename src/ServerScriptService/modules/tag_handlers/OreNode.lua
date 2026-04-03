local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	-- Read ore type and set defaults from config if needed
	local oreType = instance:GetAttribute("OreType") or "Stone"
	local oreData = OreConfig.byName[oreType]

	if oreData then
		if instance:GetAttribute("TierRequired") == nil then
			instance:SetAttribute("TierRequired", oreData.minPickaxeTier)
		end
		if instance:GetAttribute("NodeHP") == nil then
			instance:SetAttribute("NodeHP", oreData.nodeHP)
		end
		if instance:GetAttribute("DropType") == nil then
			instance:SetAttribute("DropType", oreType .. "Node")
		end
	end

	-- Initialize current HP
	local maxHP = instance:GetAttribute("NodeHP") or 4
	instance:SetAttribute("CurrentHP", maxHP)

	-- Create a BindableEvent for the server Mine endpoint to signal when the node breaks
	local breakEvent = Instance.new("BindableEvent")
	breakEvent.Name = "NodeBreak"
	breakEvent.Parent = instance

	local breakConnection
	breakConnection = breakEvent.Event:Connect(function()
		if breakConnection then
			breakConnection:Disconnect()
			breakConnection = nil
		end

		local originalParent = instance.Parent
		local revealPosition = instance.Position + Vector3.new(0, 3, 0)
		local floorNumber = instance:GetAttribute("FloorNumber")

		if instance:GetAttribute("RevealsLadder") and originalParent and originalParent.Parent then
			createLadder(revealPosition, originalParent, floorNumber)
		end

		instance:Destroy()
	end)
end

return TagHandler
