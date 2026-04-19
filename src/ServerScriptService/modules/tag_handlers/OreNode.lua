local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local OreNodeUtil = require(modules.OreNodeUtil)

local configs = ReplicatedStorage.configs
local OreConfig = require(configs.OreConfig)

local TagHandler = {}

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
end

return TagHandler
