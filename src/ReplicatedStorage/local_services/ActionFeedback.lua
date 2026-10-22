local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local APIService = require(ReplicatedStorage.services.APIService)
local Config = require(ReplicatedStorage.configs.ActionConfig)
local Prediction = require(ReplicatedStorage.utils.MiningPrediction)
local Targeting = require(ReplicatedStorage.utils.ActionTargeting)
local StatCalculation = require(ReplicatedStorage.utils.StatCalculation)
local Effects = require(ReplicatedStorage.local_services.ActionEffects)
local Display = require(ReplicatedStorage.local_services.MiningHealthDisplay)

local Feedback = {}
local player = Players.LocalPlayer
local nodes = {}
local attackSounds = {}
local latestNode: string? = nil
local latestHitAt = 0
local initialized = false

local function currentFloor(): number
	local data = ReplicatedStorage:FindFirstChild("PlayerData")
	local mine = data and data:FindFirstChild(player.Name)
	local floor = mine and mine:FindFirstChild("CurrentFloor")
	return floor and floor.Value or 0
end

local function overlapsCharacter(node: Instance): boolean
	local character = player.Character
	if not character or not node:IsDescendantOf(workspace) then return false end
	local cf, size
	if node:IsA("Model") then cf, size = node:GetBoundingBox()
	elseif node:IsA("BasePart") then cf, size = node.CFrame, node.Size
	else return false end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {character}
	return #workspace:GetPartBoundsInBox(cf, size, params) > 0
end

local function restoreParts(state: any): ()
	if state.restoreConnection then state.restoreConnection:Disconnect() state.restoreConnection = nil end
	if not state.parts then return end
	state.hidden = false
	for part, properties in pairs(state.parts) do
		if part.Parent then
			part.LocalTransparencyModifier = properties.transparency
			part.CanQuery = properties.query
		end
	end
	local function finish(): boolean
		if overlapsCharacter(state.node) then return false end
		for part, properties in pairs(state.parts or {}) do
			if part.Parent then part.CanCollide = properties.collide part.CanQuery = properties.query end
		end
		state.parts = nil
		return true
	end
	if not finish() then
		state.restoreConnection = RunService.Heartbeat:Connect(function()
			if finish() then state.restoreConnection:Disconnect() state.restoreConnection = nil end
		end)
	end
end

local function hideParts(state: any): ()
	if state.restoreConnection then state.restoreConnection:Disconnect() state.restoreConnection = nil end
	if not state.parts then
		state.parts = {}
		for _, part in ipairs(state.node:GetDescendants()) do
			if part:IsA("BasePart") then
				state.parts[part] = {transparency = part.LocalTransparencyModifier, collide = part.CanCollide, query = part.CanQuery}
			end
		end
	end
	state.hidden = true
	for part in pairs(state.parts) do
		if part.Parent then part.LocalTransparencyModifier = 1 part.CanCollide = false part.CanQuery = false end
	end
end

local function update(state: any): ()
	local hp = state.prediction:GetHP()
	if hp <= 0 then
		-- A confirmed break must not need another speculative effect. The break
		-- event is responsible for presentation if this client did not predict it.
		if next(state.prediction.pending) ~= nil and not state.hidden then
			local position = Targeting.GetPosition(state.node)
			if position then Effects.Break(state.id, "Ore", position) end
			hideParts(state)
		end
		if latestNode == state.id then Display.Clear() end
	else
		if state.parts then restoreParts(state) Effects.ForgetBreak(state.id) end
		if latestNode == state.id and os.clock() - latestHitAt < 2 and state.node:IsDescendantOf(workspace) then
			Display.Show(state.node, hp, state.maxHP)
		end
	end
end

local function removeNode(id: string): ()
	local state = nodes[id]
	if not state then return end
	nodes[id] = nil
	if state.removalConnection then state.removalConnection:Disconnect() end
	restoreParts(state)
	if latestNode == id then latestNode = nil Display.Clear() end
end

function Feedback.Reset(): ()
	local ids = {}
	for id in pairs(nodes) do table.insert(ids, id) end
	for _, id in ipairs(ids) do removeNode(id) end
	latestNode = nil
	Display.Clear()
	Effects.Reset()
end

local function trackNode(node: Instance, id: string, hp: number, revision: number): any
	local state = { id = id, node = node, maxHP = node:GetAttribute("NodeHP") or hp,
		prediction = Prediction.new(hp, revision) }
	nodes[id] = state
	state.removalConnection = node.AncestryChanged:Connect(function()
		if not node:IsDescendantOf(workspace) then removeNode(id) end
	end)
	return state
end

function Feedback.ApplyMiningState(snapshot: Prediction.Snapshot): ()
	if snapshot.floorNumber ~= nil and snapshot.floorNumber ~= currentFloor() then return end
	local state = nodes[snapshot.targetId]
	local node = snapshot.node
	if not state and node and node:IsDescendantOf(workspace) and CollectionService:HasTag(node, "OreNode") then
		state = trackNode(node, snapshot.targetId, snapshot.remainingHP, snapshot.revision)
	end
	if not state then return end
	state.prediction:Apply(snapshot)
	state.maxHP = snapshot.maxHP
	update(state)
end

function Feedback.PredictMine(node: Instance, tool: Tool, actionId: string): ()
	Effects.Shake(node)
	if not CollectionService:HasTag(node, "OreNode") then return end
	Effects.PlaySound(Config.oreHitSounds)
	local id = node:GetAttribute("DestructibleId")
	if type(id) ~= "string" then return end -- Identity may not have streamed in yet.
	local state = nodes[id]
	if not state then
		local hp = node:GetAttribute("CurrentHP") or node:GetAttribute("NodeHP") or 1
		state = trackNode(node, id, hp, node:GetAttribute("MiningRevision") or 0)
	end
	state.prediction:Predict(actionId, StatCalculation.GetMiningDamage(tool:GetAttribute("HotbarItemName")))
	latestNode, latestHitAt = id, os.clock()
	update(state)
	local hitStamp = latestHitAt
	task.delay(2, function() if latestNode == id and latestHitAt == hitStamp then Display.Clear() end end)
	task.delay(Config.PREDICTION_TIMEOUT, function()
		if nodes[id] ~= state or state.prediction.pending[actionId] == nil then return end
		state.prediction:Reject(actionId)
		update(state)
	end)
end

function Feedback.ResolveMine(node: Instance, actionId: string, result: any): ()
	local id = node:GetAttribute("DestructibleId")
	local state = nodes[id]
	if not state then return end
	if type(result) == "table" and result.state then Feedback.ApplyMiningState(result.state) end
	if type(result) ~= "table" or result.success ~= true then
		state.prediction:Reject(actionId)
		update(state)
	end
end

function Feedback.PredictAttack(actionId: string, targets: {Instance}): ()
	local hasEnemy = false
	for _, target in ipairs(targets) do
		if CollectionService:HasTag(target, "Enemy") then
			local humanoid = target:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then Effects.Flash(target) hasEnemy = true end
		else Effects.Shake(target) end
	end
	if hasEnemy then
		Effects.PlaySound(Config.impactSounds)
		attackSounds[actionId] = true
		task.delay(30, function() attackSounds[actionId] = nil end)
	end
end

function Feedback.ConfirmAttack(hitData: {any}, actionId: string?): ()
	if #hitData > 0 and not (actionId and attackSounds[actionId]) then
		Effects.PlaySound(Config.impactSounds)
		for _, hit in ipairs(hitData) do
			if hit.enemy and hit.enemy.Parent then Effects.Flash(hit.enemy) end
		end
	end
end

function Feedback.Initialize(): ()
	if initialized then return end
	initialized = true
	Effects.Initialize()
	player.CharacterRemoving:Connect(Feedback.Reset)
	player:GetAttributeChangedSignal("TeleportProtected"):Connect(function()
		if player:GetAttribute("TeleportProtected") then Feedback.Reset() end
	end)
	task.spawn(function()
		local data = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(player.Name)
		data:WaitForChild("CurrentFloor").Changed:Connect(Feedback.Reset)
	end)
	task.spawn(function()
		APIService.GetEvent("VisualizeMineHit").OnClientEvent:Connect(Feedback.ApplyMiningState)
		APIService.GetEvent("DestructibleBroken").OnClientEvent:Connect(function(payload: any)
			if payload.floorNumber == nil or payload.floorNumber == currentFloor() then
				Effects.Break(payload.targetId, payload.kind, payload.position)
			end
		end)
	end)
end

return Feedback
