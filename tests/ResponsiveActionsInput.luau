-- Boundary tests use the real scheduler with an isolated local tool and action
-- callback. No gameplay remote is invoked. All replacements are restored.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
assert(RunService:IsStudio() and RunService:IsClient(), "Run in Studio client context")
local player = Players.LocalPlayer
local Hotbar = require(ReplicatedStorage.local_services.HotbarService)
local Actions = require(ReplicatedStorage.local_services.HotbarActionService)
local Runtime = require(ReplicatedStorage.local_services.ActionRuntime)
local mineModule = require(player.PlayerScripts.ActionHandler.actions.Mine)
local originalGetTool, originalActivate = Hotbar.GetSelectedTool, mineModule.Activate
local originalIsValid = Runtime.IsValid
local tool = Instance.new("Tool")
tool.Name = "ResponsiveInputFixture"
tool.RequiresHandle = false
tool:SetAttribute("HotbarItemName", "Wood Pickaxe")
tool:SetAttribute("HotbarActionName", "Mine")
tool.Parent = player.Character
local checks, calls, cooldown = 0, 0, 0.3
local function check(condition: boolean, context: string): ()
	assert(condition, context)
	checks += 1
end
local function waitReady(): ()
	local deadline = os.clock() + 3
	while not Actions.IsActionReady() and os.clock() < deadline do task.wait() end
	assert(Actions.IsActionReady(), "Scheduler did not become ready")
end
local ok, failure = xpcall(function()
	Hotbar.GetSelectedTool = function() return tool end
	-- MCP's background Studio window emits WindowFocusReleased. Keep the real
	-- scheduler/contact code and omit only the OS-focus dependency in this suite.
	Runtime.IsValid = function(candidate: Tool?, character: Model?): boolean
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return candidate == tool and tool.Parent == character and character == player.Character
			and humanoid ~= nil and humanoid.Health > 0 and not player:GetAttribute("TeleportProtected")
	end
	mineModule.Activate = function() calls += 1 return cooldown end
	Runtime.Cancel()
	waitReady()
	check(Runtime.IsValid(tool, player.Character), "Isolated selected tool is valid; parent=" .. tostring(tool.Parent)
		.. ", selected=" .. tostring(Hotbar.GetSelectedTool() == tool)
		.. ", protected=" .. tostring(player:GetAttribute("TeleportProtected"))
		.. ", health=" .. tostring(player.Character:FindFirstChildOfClass("Humanoid").Health))
	check(Actions.ActivateAction("Mine", tool), "Ready input activates")
	task.wait(0.04)
	check(not Actions.ActivateAction("Mine", tool), "Input earlier than final 100ms is ignored")
	task.wait(0.2)
	check(Actions.ActivateAction("Mine", tool), "Input in final 100ms is accepted")
	check(Actions.ActivateAction("Mine", tool), "Repeated buffered input replaces pending input")
	task.wait(0.12)
	check(calls == 2, "Only one buffered action executes at readiness")
	waitReady()
	calls = 0
	Actions.ActivateAction("Mine", tool)
	task.wait(0.24)
	Actions.ActivateAction("Mine", tool)
	Runtime.Cancel()
	check(not Actions.IsActionReady(), "Cancel preserves current cooldown")
	task.wait(0.12)
	check(calls == 1, "Cancellation clears buffered input")
	waitReady()
	cooldown, calls = 0.08, 0
	Actions.StartHoldingMine()
	task.wait(0.23)
	Actions.StopHoldingMine()
	local stoppedCalls = calls
	task.wait(0.15)
	check(stoppedCalls >= 2 and calls == stoppedCalls, "Hold repeats at readiness and release stops repeats")
	waitReady()
	local contacts = 0
	check(Runtime.PlaySwing("Mine", tool, function() contacts += 1 end), "Swing starts locally")
	task.wait(0.8)
	check(contacts == 1, "Animation marker/fallback produces exactly one contact")
	Runtime.PlaySwing("Mine", tool, function() contacts += 1 end)
	Runtime.Cancel()
	task.wait(0.8)
	check(contacts == 1, "Cancel before contact prevents unsent hit")
	Runtime.PlaySwing("Mine", tool, function() contacts += 1 end)
	tool.Parent = nil
	task.wait(0.8)
	check(contacts == 1, "Unequipping during windup prevents unsent hit")
	tool.Parent = player.Character
end, debug.traceback)
Actions.StopHoldingMine()
Runtime.Cancel()
Hotbar.GetSelectedTool = originalGetTool
mineModule.Activate = originalActivate
Runtime.IsValid = originalIsValid
tool:Destroy()
assert(ok, failure)
return { suite = "ResponsiveActionsInput", checks = checks,
	fixtureNote = "Isolated selected tool/action callback; IsValid omits OS focus because MCP Studio runs in background." }
