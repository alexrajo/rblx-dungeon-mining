local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerScriptService.modules
local CrateService = require(modules.CrateService)
local HotbarToolValidator = require(modules.HotbarToolValidator)
local OreNodeService = require(modules.OreNodeService)
local PlayerDataHandler = require(modules.PlayerDataHandler)
local DestructibleStateService = require(modules.DestructibleStateService)
local ActionTargeting = require(ReplicatedStorage.utils.ActionTargeting)
local StatCalculation = require(ReplicatedStorage.utils.StatCalculation)
local OreConfig = require(ReplicatedStorage.configs.OreConfig)
local GlobalConfig = require(ReplicatedStorage.GlobalConfig)

local signalTutorialEvent = ServerStorage.CrossScriptCommunicationBindables.SignalTutorial
local lastMineTime: {[Player]: number} = {}
Players.PlayerRemoving:Connect(function(player: Player) lastMineTime[player] = nil end)

local endpoint = {}

function endpoint.Call(player: Player, tool: Instance?, nodeInstance: Instance?, _hitPosition: Vector3?, actionId: string?): any
	local function failure(reason: string): any
		return { success = false, cooldown = 0.1, reason = reason, actionId = actionId }
	end
	if actionId ~= nil and (type(actionId) ~= "string" or #actionId > 80) then return failure("invalid_action") end
	local validTool, pickaxeName, reason, levelFailure = HotbarToolValidator.Validate(player, tool, "Mine", "Pickaxe")
	if not validTool or pickaxeName == nil then return levelFailure or failure(reason or "invalid_tool") end
	if typeof(nodeInstance) ~= "Instance" or not nodeInstance:IsDescendantOf(workspace) then return failure("missing_target") end
	local crate = ActionTargeting.FindTaggedAncestor(nodeInstance, "MineCrate")
	local node = crate or ActionTargeting.FindTaggedAncestor(nodeInstance, "OreNode")
	if not node or (not crate and not node:IsA("Model")) then return failure("invalid_target") end
	local floor = node:GetAttribute("FloorNumber")
	if type(floor) == "number" and floor ~= PlayerDataHandler.GetCurrentFloor(player) then return failure("wrong_floor") end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0
		or player:GetAttribute("TeleportProtected") then return failure("invalid_character") end
	if not ActionTargeting.IsInRange(root, node, GlobalConfig.MINE_REACH_DISTANCE) then return failure("out_of_range") end
	if DestructibleStateService.HasApplied(node, actionId) then
		return { success = true, cooldown = GlobalConfig.MINE_SWING_COOLDOWN, actionId = actionId,
			state = DestructibleStateService.Snapshot(node) }
	end
	if node:GetAttribute("Broken") then return failure("already_broken") end
	local now = os.clock()
	if lastMineTime[player] and now - lastMineTime[player] < GlobalConfig.MINE_SWING_COOLDOWN - GlobalConfig.SERVER_ACTION_LENIENCY then
		return failure("cooldown")
	end
	if not crate and not OreConfig.byName[node:GetAttribute("OreType") or "Stone"] then return failure("invalid_ore") end
	lastMineTime[player] = now
	local state = DestructibleStateService.Damage(node, StatCalculation.GetMiningDamage(pickaxeName), actionId)
	signalTutorialEvent:Fire(player, "mine")
	local broken = state.remainingHP <= 0
	if broken then
		if crate then CrateService.BreakCrate(player, node, actionId) else OreNodeService.BreakNode(player, node, actionId) end
		state = DestructibleStateService.Snapshot(node)
	end
	return { success = true, cooldown = GlobalConfig.MINE_SWING_COOLDOWN, actionId = actionId,
		broken = broken, remainingHP = state.remainingHP, state = state }
end

return endpoint
