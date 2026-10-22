-- Run sequentially on the client, after server suites restore player state.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
assert(RunService:IsStudio() and RunService:IsClient(), "Run in a Studio client playtest")
local Feedback = require(ReplicatedStorage.local_services.ActionFeedback)
local Effects = require(ReplicatedStorage.local_services.ActionEffects)
local Config = require(ReplicatedStorage.configs.ActionConfig)
local player = Players.LocalPlayer
local character = assert(player.Character)
local root = assert(character:FindFirstChild("HumanoidRootPart")) :: BasePart
local originalPivot, originalAnchored = character:GetPivot(), root.Anchored
local fixtures = Instance.new("Folder")
fixtures.Name = "ResponsiveFeedbackFixtures"
fixtures.Parent = workspace
local tool = Instance.new("Tool")
tool:SetAttribute("HotbarItemName", "Wood Pickaxe")
local checks, timings = 0, {}
local function check(condition: boolean, context: string): ()
	assert(condition, context)
	checks += 1
end

local serial = 0
local function ore(position: Vector3, hp: number): (Model, Part, string)
	serial += 1
	local node = Instance.new("Model")
	node.Name = "FeedbackOre"
	local rock = Instance.new("Part")
	rock.Anchored = true
	rock.Size = Vector3.new(4, 4, 4)
	rock.Position = position
	rock.Parent = node
	node.PrimaryPart = rock
	local id = "feedback-test-" .. serial
	node:SetAttribute("DestructibleId", id)
	node:SetAttribute("CurrentHP", hp)
	node:SetAttribute("NodeHP", hp)
	node:SetAttribute("MiningRevision", 0)
	node:SetAttribute("OreType", "Stone")
	node.Parent = fixtures
	CollectionService:AddTag(node, "OreNode")
	return node, rock, id
end

local function effectCount(): number
	local count = 0
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "LocalActionEffect" then count += 1 end
	end
	return count
end

local ok, failure = xpcall(function()
	root.Anchored = true
	for _, delaySeconds in ipairs({0, 0.1, 0.2}) do
		local node, rock, id = ore(root.Position + Vector3.new(0, 0, -10), 1)
		local actionId = id .. "-action"
		local startedAt = os.clock()
		Feedback.PredictMine(node, tool, actionId)
		table.insert(timings, { simulatedConfirmationDelayMs = delaySeconds * 1000,
			predictionMs = (os.clock() - startedAt) * 1000 })
		check(rock.LocalTransparencyModifier == 1 and not rock.CanCollide and not rock.CanQuery,
			"Finishing feedback hides and clears collision synchronously")
		if delaySeconds > 0 then task.wait(delaySeconds) end
		local before = effectCount()
		Feedback.ApplyMiningState({ targetId = id, revision = 1, remainingHP = 0, maxHP = 1,
			appliedActions = {[actionId] = true}, node = node, broken = true })
		Effects.Break(id, "Ore", rock.Position)
		check(effectCount() == before, "Confirmed break does not repeat predicted presentation")
		node:Destroy()
	end
	local rejected, rock = ore(root.Position + Vector3.new(0, 0, -10), 1)
	Feedback.PredictMine(rejected, tool, "rejected")
	Feedback.ResolveMine(rejected, "rejected", { success = false, reason = "out_of_range" })
	check(rock.LocalTransparencyModifier == 0 and rock.CanCollide and rock.CanQuery,
		"Rejected break restores visible/query/collision properties")
	local overlapNode, overlapRock = ore(root.Position, 1)
	Feedback.PredictMine(overlapNode, tool, "overlap")
	Feedback.ResolveMine(overlapNode, "overlap", { success = false })
	check(overlapRock.LocalTransparencyModifier == 0 and not overlapRock.CanCollide,
		"Rejected overlapping ore becomes visible without trapping the character")
	character:PivotTo(originalPivot + Vector3.new(20, 0, 0))
	task.wait(0.15)
	check(overlapRock.CanCollide, "Collision restores after character clears rejected ore")
	local timeoutNode, timeoutRock = ore(root.Position + Vector3.new(0, 0, -10), 1)
	Feedback.PredictMine(timeoutNode, tool, "timeout")
	task.wait(Config.PREDICTION_TIMEOUT + 0.2)
	check(timeoutRock.LocalTransparencyModifier == 0 and timeoutRock.CanCollide,
		"Unresolved prediction rolls back after timeout")
	local hpNode = ore(root.Position + Vector3.new(0, 0, -10), 4)
	Feedback.PredictMine(hpNode, tool, "hp-hit")
	local billboard = player.PlayerGui:FindFirstChild("MiningHP")
	check(billboard ~= nil and billboard:FindFirstChild("Name").Text == "Stone  3/4",
		"Non-finishing hit displays predicted HP immediately")
	Feedback.Reset()
	check(player.PlayerGui:FindFirstChild("MiningHP") == nil, "Reset removes HP UI")
	local before = effectCount()
	Effects.Break("dedup-only", "Ore", root.Position)
	local after = effectCount()
	Effects.Break("dedup-only", "Ore", root.Position)
	check(after > before and effectCount() == after, "Repeated authoritative break is deduplicated")
	local shake = ore(root.Position + Vector3.new(0, 0, -10), 4)
	local initial = shake:GetPivot()
	Effects.Shake(shake)
	Effects.Reset()
	task.wait(0.2)
	check((shake:GetPivot().Position - initial.Position).Magnitude < 0.001,
		"Canceling shake restores the original transform")
end, debug.traceback)

Feedback.Reset()
fixtures:Destroy()
tool:Destroy()
character:PivotTo(originalPivot)
root.Anchored = originalAnchored
assert(ok, failure)
return { suite = "ResponsiveActionsFeedback", checks = checks, timings = timings,

	latencyNote = "Delays are injected before confirmation handling; these are not measured network RTTs." }
