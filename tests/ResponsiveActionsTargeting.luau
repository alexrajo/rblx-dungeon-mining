-- Run as a ModuleScript on the client: tags and fixtures remain local.
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
assert(RunService:IsStudio() and RunService:IsClient(), "Run in Studio's client context")
local Targeting = require(ReplicatedStorage.utils.ActionTargeting)
local checks = 0
local container = Instance.new("Folder")
container.Name = "ResponsiveTargetingFixtures"
container.Parent = workspace

local function check(condition: boolean, context: string): ()
	assert(condition, context)
	checks += 1
end

local function part(name: string, position: Vector3, parent: Instance): Part
	local result = Instance.new("Part")
	result.Name = name
	result.Anchored = true
	result.Size = Vector3.new(2, 2, 2)
	result.Position = position
	result.Parent = parent
	return result
end

local ok, failure = xpcall(function()
	local origin = Vector3.new(0, 20000, 0)
	local character = Instance.new("Model")
	character.Parent = container
	local root = part("HumanoidRootPart", origin, character)
	local ore = Instance.new("Model")
	ore.Parent = container
	local rock = part("Rock", origin + Vector3.new(0, 0, -6), ore)
	ore.PrimaryPart = rock
	ore:SetAttribute("FloorNumber", 7)
	CollectionService:AddTag(ore, "OreNode")
	check(Targeting.FindTaggedAncestor(rock, "OreNode") == ore, "Part resolves to tagged node")
	check(Targeting.FindMineTarget(character, root, 7) == ore, "Facing ore is found")
	check(Targeting.FindMineTarget(character, root, 8) == nil, "Wrong-floor node is ignored")
	ore:SetAttribute("Broken", true)
	check(Targeting.FindMineTarget(character, root, 7) == nil, "Broken node is ignored")
	ore:SetAttribute("Broken", false)
	ore:PivotTo(CFrame.new(origin + Vector3.new(0, 0, -13)))
	check(Targeting.FindMineTarget(character, root, 7) == nil, "Surface in reach cannot bypass pivot limit")
	ore:PivotTo(CFrame.new(origin + Vector3.new(6, 0, 0)))
	check(Targeting.FindMineTarget(character, root, 7) == nil, "Side ore is initially outside facing rays")
	root.CFrame = CFrame.lookAt(origin, rock.Position)
	check(Targeting.FindMineTarget(character, root, 7) == ore, "Retargeting sees new facing at contact")
	ore:Destroy()
	root.CFrame = CFrame.new(origin)
	local enemy = Instance.new("Model")
	enemy.Parent = container
	local enemyRoot = part("HumanoidRootPart", origin + Vector3.new(0, 0, -6), enemy)
	enemy.PrimaryPart = enemyRoot
	part("Body", enemyRoot.Position + Vector3.new(1, 0, 0), enemy)
	enemy:SetAttribute("FloorNumber", 7)
	CollectionService:AddTag(enemy, "Enemy")
	local targets = Targeting.FindAttackTargets(character, root, 7)
	check(#targets == 1 and targets[1] == enemy, "Multipart enemy occurs once")
	check(#Targeting.FindAttackTargets(character, root, 8) == 0, "Attack rejects wrong floor")
	enemy:PivotTo(CFrame.new(origin + Vector3.new(0, 0, 6)))
	check(#Targeting.FindAttackTargets(character, root, 7) == 0, "Attack excludes rear half-space")
	enemy:PivotTo(CFrame.new(origin + Vector3.new(0, 0, -9)))
	check(#Targeting.FindAttackTargets(character, root, 7) == 0, "Overlapping body cannot bypass enemy-root limit")
	enemy:PivotTo(CFrame.new(origin + Vector3.new(0, 0, -6)))
	check(#Targeting.FindAttackTargets(character, root, 7) == 1, "Enemy entering range is found on next contact query")
end, debug.traceback)
container:Destroy()
assert(ok, failure)
return { suite = "ResponsiveActionsTargeting", checks = checks }
