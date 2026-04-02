local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local ModuleIndex = require(script.Parent.ModuleIndex)
local EnemyBillboard = require(ModuleIndex.EnemyBillboard)

local BILLBOARD_NAME = "EnemyBillboardGui"
local BILLBOARD_SIZE = UDim2.new(5, 16, 1.5, 5)
local BILLBOARD_OFFSET = Vector3.new(0, 3.6, 0)
local BILLBOARD_MAX_DISTANCE = 120
local CHILD_WAIT_TIMEOUT = 5

local mountedBillboards: {[Model]: {billboardGui: BillboardGui, handle: any}} = {}

local function cleanupEnemyBillboard(enemyModel: Model)
	local mounted = mountedBillboards[enemyModel]
	if mounted == nil then return end

	Roact.unmount(mounted.handle)

	if mounted.billboardGui.Parent ~= nil then
		mounted.billboardGui:Destroy()
	end

	mountedBillboards[enemyModel] = nil
end

local function attachEnemyBillboard(enemyModel: Model)
	if mountedBillboards[enemyModel] ~= nil then return end
	if not enemyModel:IsA("Model") then return end
	if enemyModel.Parent == nil then return end

	local rootPart = enemyModel:FindFirstChild("HumanoidRootPart") or enemyModel:WaitForChild("HumanoidRootPart", CHILD_WAIT_TIMEOUT)
	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid") or enemyModel:WaitForChild("Humanoid", CHILD_WAIT_TIMEOUT)
	if rootPart == nil or humanoid == nil then return end
	if enemyModel.Parent == nil then return end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = BILLBOARD_NAME
	billboardGui.AlwaysOnTop = false
	billboardGui.LightInfluence = 0
	billboardGui.MaxDistance = BILLBOARD_MAX_DISTANCE
	billboardGui.Size = BILLBOARD_SIZE
	billboardGui.StudsOffset = BILLBOARD_OFFSET
	billboardGui.Adornee = rootPart
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboardGui.Parent = rootPart

	local handle = Roact.mount(Roact.createElement(EnemyBillboard, {
		enemyModel = enemyModel,
	}), billboardGui, "EnemyBillboard")

	mountedBillboards[enemyModel] = {
		billboardGui = billboardGui,
		handle = handle,
	}
end

for _, enemyModel in ipairs(CollectionService:GetTagged("Enemy")) do
	task.defer(attachEnemyBillboard, enemyModel)
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(function(enemyModel)
	task.defer(attachEnemyBillboard, enemyModel)
end)

CollectionService:GetInstanceRemovedSignal("Enemy"):Connect(function(enemyModel)
	cleanupEnemyBillboard(enemyModel)
end)
