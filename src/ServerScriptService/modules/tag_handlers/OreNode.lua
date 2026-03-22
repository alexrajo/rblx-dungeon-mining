local ReplicatedStorage = game:GetService("ReplicatedStorage")
local configs = ReplicatedStorage.configs
local OreConfig = require(configs.OreConfig)
local globalConfig = require(ReplicatedStorage.GlobalConfig)

local ORE_NODE_RESPAWN_TIME = globalConfig.ORE_NODE_RESPAWN_TIME

local TagHandler = {}

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

	-- Store a clone for respawning
	local clone = instance:Clone()
	local originalParent = instance.Parent

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

		-- Hide/destroy the node
		instance:Destroy()

		-- Respawn after timer
		task.delay(ORE_NODE_RESPAWN_TIME, function()
			if originalParent and originalParent.Parent then
				local newNode = clone:Clone()
				newNode.Parent = originalParent
				-- The TagManager will re-apply the tag handler to the new clone
			end
		end)
	end)
end

return TagHandler
