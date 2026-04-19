local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local configs = ReplicatedStorage.configs
local CrateConfig = require(configs.CrateConfig)
local dropsConfig = require(configs.DropsConfig)

local CrateService = {}

local RE_ItemDrop = APIService.GetEvent("DropItems")

local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial

local function getRewardDescription(rewards: {[string]: number}): string
	local parts = {}

	for itemName, amount in pairs(rewards) do
		if amount == 1 then
			table.insert(parts, itemName)
		else
			table.insert(parts, string.format("%dx %s", amount, itemName))
		end
	end

	table.sort(parts)
	return table.concat(parts, ", ")
end

function CrateService.AnchorCrate(crate: Instance)
	if crate:IsA("BasePart") then
		crate.Anchored = true
		return
	end

	for _, descendant in ipairs(crate:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
end

function CrateService.GetPosition(crate: Instance): Vector3
	if crate:IsA("BasePart") then
		return crate.Position
	end

	if crate:IsA("Model") then
		return crate:GetPivot().Position
	end

	return Vector3.zero
end

function CrateService.PlaceOnFloor(crate: Instance, floorPosition: Vector3)
	if crate:IsA("BasePart") then
		crate.CFrame = CFrame.new(floorPosition + Vector3.new(0, crate.Size.Y / 2, 0))
		return
	end

	if crate:IsA("Model") then
		local _, size = crate:GetBoundingBox()
		crate:PivotTo(CFrame.new(floorPosition + Vector3.new(0, size.Y / 2, 0)))
	end
end

function CrateService.BreakCrate(player: Player, crate: Instance): boolean
	if crate == nil or crate.Parent == nil then
		return false
	end

	if crate:GetAttribute("Broken") then
		return false
	end
	crate:SetAttribute("Broken", true)

	local cratePosition = CrateService.GetPosition(crate)
	local itemRewards = CrateConfig.RollLoot()

	if next(itemRewards) then
		PlayerDataHandler.GiveItems(player, itemRewards)

		if RE_ItemDrop then
			for itemName, amount in pairs(itemRewards) do
				local itemDefinition = dropsConfig.itemDefinitions[itemName]
				if itemDefinition then
					RE_ItemDrop:FireClient(player, amount, cratePosition, itemDefinition)
				end
			end
		end

		APIService.GetEvent("SendNotification"):FireClient(player, {
			Type = "reward",
			Title = "Crate Broken!",
			Description = getRewardDescription(itemRewards),
		})

		signalTutorialEvent:Fire(player, "getItem")
	end

	crate:Destroy()

	return true
end

return CrateService
