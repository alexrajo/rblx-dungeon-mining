local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local APIService = require(ReplicatedStorage.services.APIService)
local ActionTargeting = require(ReplicatedStorage.utils.ActionTargeting)
local MiningPrediction = require(ReplicatedStorage.utils.MiningPrediction)

local DestructibleStateService = {}
-- Keep the Lua Instance key alive for the node's lifetime. Engine parenting
-- alone does not retain a weak Lua wrapper, which can otherwise regenerate IDs
-- and lose receipts between requests after garbage collection.
local states = {}

function DestructibleStateService.Initialize(node: Instance): ()
	if states[node] then return end
	local id = HttpService:GenerateGUID(false)
	node:SetAttribute("DestructibleId", id)
	node:SetAttribute("MiningRevision", 0)
	states[node] = { id = id, revision = 0, appliedActions = {} }
	node.Destroying:Once(function()
		-- Mine returns a final snapshot after BreakNode destroys the instance.
		-- Release only after that synchronous request has built its response.
		task.defer(function() states[node] = nil end)
	end)
end

function DestructibleStateService.Snapshot(node: Instance): MiningPrediction.Snapshot
	DestructibleStateService.Initialize(node)
	local state = states[node]
	return {
		node = node, targetId = state.id, revision = state.revision,
		remainingHP = math.max(0, node:GetAttribute("CurrentHP") or 0),
		maxHP = node:GetAttribute("NodeHP") or node:GetAttribute("CrateHP") or 1,
		appliedActions = table.clone(state.appliedActions), broken = node:GetAttribute("Broken") == true,
		floorNumber = node:GetAttribute("FloorNumber"),
	}
end

function DestructibleStateService.HasApplied(node: Instance, actionId: string?): boolean
	DestructibleStateService.Initialize(node)
	return actionId ~= nil and states[node].appliedActions[actionId] == true
end

function DestructibleStateService.Damage(node: Instance, damage: number, actionId: string?): MiningPrediction.Snapshot
	DestructibleStateService.Initialize(node)
	local state = states[node]
	if actionId then state.appliedActions[actionId] = true end
	state.revision += 1
	node:SetAttribute("CurrentHP", math.max(0, (node:GetAttribute("CurrentHP") or 1) - damage))
	node:SetAttribute("MiningRevision", state.revision)
	local snapshot = DestructibleStateService.Snapshot(node)
	APIService.GetEvent("VisualizeMineHit"):FireAllClients(snapshot)
	return snapshot
end

function DestructibleStateService.PublishBreak(node: Instance, kind: string, player: Player, actionId: string?): ()
	DestructibleStateService.Initialize(node)
	local state = states[node]
	state.revision += 1
	node:SetAttribute("CurrentHP", 0)
	node:SetAttribute("MiningRevision", state.revision)
	local snapshot = DestructibleStateService.Snapshot(node)
	APIService.GetEvent("VisualizeMineHit"):FireAllClients(snapshot)
	APIService.GetEvent("DestructibleBroken"):FireAllClients({
		targetId = state.id, kind = kind, position = ActionTargeting.GetPosition(node),
		floorNumber = snapshot.floorNumber, actionId = actionId, actorUserId = player.UserId,
	})
end

return DestructibleStateService
