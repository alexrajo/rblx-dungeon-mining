local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Configs = ReplicatedStorage.configs
local MineRewardFloorConfig = require(Configs.MineRewardFloorConfig)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local TagHandler = {}

local PROMPT_NAME = "MineRewardChestPrompt"
local debounceByPlayer: {[Player]: boolean} = {}

local function getRewardDescription(rewardData): string
	if rewardData.amount == 1 then
		return rewardData.itemName
	end

	return string.format("%dx %s", rewardData.amount, rewardData.itemName)
end

function TagHandler.Apply(instance: Instance)
	if not instance:IsA("Model") then
		warn("MineRewardChest: Expected a Model, got", instance:GetFullName())
		return
	end

	local chestModel = instance :: Model
	local promptHost = chestModel.PrimaryPart
	if promptHost == nil then
		warn("MineRewardChest: Chest model is missing PrimaryPart", chestModel:GetFullName())
		return
	end

	local existingPrompt = promptHost:FindFirstChild(PROMPT_NAME)
	if existingPrompt ~= nil then
		existingPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = "Open"
	prompt.ObjectText = "Chest"
	prompt.HoldDuration = 3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptHost

	prompt.Triggered:Connect(function(player: Player)
		if Players:GetPlayerFromCharacter(player.Character) ~= player then
			return
		end

		if debounceByPlayer[player] then
			return
		end

		local floorNumber = chestModel:GetAttribute("FloorNumber")
		if type(floorNumber) ~= "number" then
			return
		end

		if PlayerDataHandler.GetCurrentFloor(player) ~= floorNumber then
			return
		end

		local rewardData = MineRewardFloorConfig.GetRewardForFloor(floorNumber)
		if rewardData == nil then
			warn("MineRewardChest: Missing reward config for floor", floorNumber)
			return
		end

		debounceByPlayer[player] = true

		if not PlayerDataHandler.MarkMineChestOpened(player, floorNumber) then
			debounceByPlayer[player] = nil
			return
		end

		PlayerDataHandler.GiveItems(player, {
			[rewardData.itemName] = rewardData.amount,
		})

		APIService.GetEvent("MineChestOpened"):FireClient(player, floorNumber)
		APIService.GetEvent("SendNotification"):FireClient(player, {
			Type = "reward",
			Title = "Chest Opened!",
			Description = getRewardDescription(rewardData),
		})

		task.delay(0.5, function()
			debounceByPlayer[player] = nil
		end)
	end)
end

return TagHandler
