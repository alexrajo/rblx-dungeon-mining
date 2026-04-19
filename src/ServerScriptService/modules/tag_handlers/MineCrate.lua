local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local CrateService = require(modules.CrateService)

local configs = ReplicatedStorage.configs
local CrateConfig = require(configs.CrateConfig)

local TagHandler = {}

function TagHandler.Apply(instance: Instance)
	if not instance:IsA("Model") and not instance:IsA("BasePart") then
		warn("MineCrate tag can only be applied to Model or BasePart instances", instance:GetFullName())
		return
	end

	CrateService.AnchorCrate(instance)

	if instance:GetAttribute("CrateHP") == nil then
		instance:SetAttribute("CrateHP", CrateConfig.defaultHealth)
	end

	local maxHP = instance:GetAttribute("CrateHP") or CrateConfig.defaultHealth
	instance:SetAttribute("CurrentHP", maxHP)
end

return TagHandler
