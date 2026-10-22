local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local APIService = require(ReplicatedStorage.services.APIService)
local Feedback = require(ReplicatedStorage.local_services.ActionFeedback)
local Hotbar = require(ReplicatedStorage.local_services.HotbarService)
local GlobalConfig = require(ReplicatedStorage.GlobalConfig)
local player = Players.LocalPlayer
local control = APIService.GetFunction("ResponsiveTestsControl")
local mine = APIService.GetFunction("Mine")
local fixtures = workspace:WaitForChild("ResponsiveNetworkFixtures", 10)
local normal = fixtures:WaitForChild("NormalOre")
local normalId = normal:GetAttribute("DestructibleId")
local finishing = fixtures:WaitForChild("FinishingOre")
local unsolicited = fixtures:WaitForChild("UnsolicitedOre")
local finishingId = finishing:GetAttribute("DestructibleId")
local unsolicitedId = unsolicited:GetAttribute("DestructibleId")
local breakCounts = {}
local connection = APIService.GetEvent("DestructibleBroken").OnClientEvent:Connect(function(payload: any)
	breakCounts[payload.targetId] = (breakCounts[payload.targetId] or 0) + 1
end)
local checks, rttMs = 0, 0
local function check(condition: boolean, context: string): ()
	assert(condition, context)
	checks += 1
end
local ok, failure = xpcall(function()
	Hotbar.SyncSelectedSlot(1)
	local deadline = os.clock() + 5
	while not Hotbar.GetSelectedTool() and os.clock() < deadline do task.wait(0.1) end
	local tool = assert(Hotbar.GetSelectedTool(), "Network fixture tool did not equip")
	task.wait(0.2) -- Allow the equip and select event to reach the server.
	Feedback.PredictMine(normal, tool, "real-network-normal")
	local start = os.clock()
	local result = mine:InvokeServer(tool, normal, normal.PrimaryPart.Position, "real-network-normal")
	rttMs = (os.clock() - start) * 1000
	Feedback.ResolveMine(normal, "real-network-normal", result)
	check(result.success and result.remainingHP == 99, "Real RemoteFunction returns authoritative mining damage")
	check(result.state.targetId == normalId, "Destructible identity remains stable across the real request")
	check(result.state.appliedActions["real-network-normal"], "Real network confirmation preserves action receipt")
	local hp = player.PlayerGui:FindFirstChild("MiningHP")
	check(hp ~= nil and hp:FindFirstChild("Name").Text == "Stone  99/100", "Network event/response do not subtract predicted damage twice")
	task.wait(GlobalConfig.MINE_SWING_COOLDOWN)
	Feedback.PredictMine(finishing, tool, "real-network-finish")
	result = mine:InvokeServer(tool, finishing, finishing.PrimaryPart.Position, "real-network-finish")
	Feedback.ResolveMine(finishing, "real-network-finish", result)
	check(result.success and result.broken and result.state.remainingHP == 0, "Finishing request returns confirmed break state")
	task.wait(0.8) -- Permit replication even when Studio incoming lag is enabled.
	check(finishing.Parent == nil and breakCounts[finishingId] == 1,
		"Finishing ore disappears with one authoritative break event; parent=" .. tostring(finishing.Parent)
		.. ", eventCount=" .. tostring(breakCounts[finishingId]) .. ", expectedId=" .. tostring(finishingId)
		.. ", resultId=" .. tostring(result.state.targetId))
	local state = control:InvokeServer("inspect")
	check(state.xp == 5 and state.stone == 1 and state.ladders == 1, "Finishing hit grants exactly one XP/item award and reveals ladder")
	result = mine:InvokeServer(tool, finishing, Vector3.zero, "real-network-finish")
	state = control:InvokeServer("inspect")
	check(not result.success and state.xp == 5 and state.stone == 1 and state.ladders == 1,
		"Replay after destruction cannot duplicate rewards or ladder")
	local unsolicitedResult = control:InvokeServer("unsolicited")
	task.wait(0.8)
	check(unsolicitedResult.first and not unsolicitedResult.second and breakCounts[unsolicitedId] == 1,
		"Unsolicited BreakNode publishes one event and retains its single-break guard")
	check(unsolicitedResult.state.xp == 10 and unsolicitedResult.state.stone == 2,
		"Unsolicited break grants one additional reward")
end, debug.traceback)
connection:Disconnect()
Feedback.Reset()
local restoreResult = control:InvokeServer("finish")
assert(restoreResult.restored, "Network fixture did not restore data")
assert(ok, failure)
return { suite = "ResponsiveActionsNetwork", checks = checks, observedRoundTripMs = rttMs,
	playerDataRestored = true, clients = 1 }
