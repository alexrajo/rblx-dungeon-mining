-- Execute from a local server runner after character/data initialization.
-- Fixtures never break or die, so this suite grants no rewards.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
assert(RunService:IsStudio() and RunService:IsServer(), "Run in a Studio server playtest")
local player = assert(Players:GetPlayers()[1], "Wait for a player")
local modules = ServerScriptService.modules
local PlayerData = require(modules.PlayerDataHandler)
local client = assert(PlayerData.GetClient(player), "Wait for player data")
local Mine = require(modules.api_endpoints.Mine)
local Attack = require(modules.api_endpoints.Attack)
local State = require(modules.DestructibleStateService)
local GlobalConfig = require(ReplicatedStorage.GlobalConfig)
local character = assert(player.Character)
local root = assert(character:FindFirstChild("HumanoidRootPart")) :: BasePart
local originalPivot, originalAnchored = character:GetPivot(), root.Anchored
local originalProtected = player:GetAttribute("TeleportProtected")
local originalInventory = client:GetDataValue("Inventory")
local originalSlots = client:GetDataValue("HotbarSlots")
local originalSelected = client:GetDataValue("SelectedHotbarSlot")
local originalLevel = client:GetDataValue("Level")
local fixtures = Instance.new("Folder")
fixtures.Name = "ResponsiveServerFixtures"
fixtures.Parent = workspace
local tools = {}
local checks = 0

local function check(condition: boolean, context: string): ()
	assert(condition, context)
	checks += 1
end

local function makeTool(name: string, slot: number, action: string): Tool
	local tool = Instance.new("Tool")
	tool.RequiresHandle = false
	tool:SetAttribute("HotbarSlot", slot)
	tool:SetAttribute("HotbarEntryId", "responsive-" .. slot)
	tool:SetAttribute("HotbarItemName", name)
	tool:SetAttribute("HotbarActionName", action)
	tool.Parent = character
	table.insert(tools, tool)
	return tool
end

local function makeTarget(name: string, offset: Vector3): (Model, Part)
	local target = Instance.new("Model")
	target.Name = name
	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(2, 2, 2)
	body.Position = root.Position + offset
	body.Anchored = true
	body.Parent = target
	target.PrimaryPart = body
	target.Parent = fixtures
	return target, body
end

local ok, failure = xpcall(function()
	root.Anchored = true
	character:PivotTo(CFrame.new(0, 22000, 0))
	player:SetAttribute("TeleportProtected", false)
	client:SetDataValue("Level", 1)
	client:SetDataValue("Inventory", {
		{ id = "responsive-1", name = "Wood Pickaxe" },
		{ id = "responsive-2", name = "Wood Sword" },
	})
	PlayerData.SetHotbarSlots(player, { "responsive-1", "responsive-2" })
	local pickaxe = makeTool("Wood Pickaxe", 1, "Mine")
	local sword = makeTool("Wood Sword", 2, "Attack")
	local ore, rock = makeTarget("TestOre", Vector3.new(0, 0, -6))
	ore:SetAttribute("OreType", "Stone")
	ore:SetAttribute("NodeHP", 100)
	ore:SetAttribute("FloorNumber", PlayerData.GetCurrentFloor(player))
	CollectionService:AddTag(ore, "OreNode")
	task.wait()
	ore:SetAttribute("CurrentHP", 100)
	State.Initialize(ore)
	local originalId = ore:GetAttribute("DestructibleId")
	task.wait(GlobalConfig.MINE_SWING_COOLDOWN)
	local result = Mine.Call(player, pickaxe, rock, rock.Position, "responsive-mine-1")
	check(result.state.targetId == originalId, "Server identity survives a scheduler interval")
	check(result.success and result.remainingHP == 99, "Mining damage unchanged")
	check(result.state.appliedActions["responsive-mine-1"] and result.state.revision > 0,
		"Mining confirmation contains receipt/revision")
	local replay = Mine.Call(player, pickaxe, rock, rock.Position, "responsive-mine-1")
	check(replay.success and ore:GetAttribute("CurrentHP") == 99, "Replayed action does not apply damage twice")
	check(not Mine.Call(player, pickaxe, rock, rock.Position, "responsive-mine-2").success,
		"Distinct immediate action still obeys server cooldown")
	ore:SetAttribute("FloorNumber", PlayerData.GetCurrentFloor(player) + 1)
	check(Mine.Call(player, pickaxe, rock, rock.Position, "wrong-floor").reason == "wrong_floor",
		"Ore floor is server validated")
	ore:SetAttribute("FloorNumber", PlayerData.GetCurrentFloor(player))
	ore:PivotTo(CFrame.new(root.Position + Vector3.new(0, 0, -13)))
	check(Mine.Call(player, pickaxe, rock, rock.Position, "outside-reach").reason == "out_of_range",
		"Server retains mining pivot reach")
	local enemy, enemyRoot = makeTarget("TestEnemy", Vector3.new(0, 0, -6))
	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.MaxHealth = 1000
	humanoid.Health = 1000
	humanoid.Parent = enemy
	enemy:SetAttribute("EnemyType", "Cave Slime")
	enemy:SetAttribute("FloorNumber", PlayerData.GetCurrentFloor(player))
	CollectionService:AddTag(enemy, "Enemy")
	local enemyHealthBefore = humanoid.Health
	local attackResult = Attack.Call(player, sword, { enemy, enemyRoot, enemy, enemyRoot }, "responsive-attack")
	check(attackResult.success and attackResult.hitCount == 1, "Multipart/duplicate attack targets hit once")
	check(math.abs((enemyHealthBefore - humanoid.Health) - attackResult.damage) < 0.001,
		"Confirmed attack damage matches one health deduction: health=" .. humanoid.Health .. ", damage=" .. attackResult.damage)
	check(attackResult.actionId == "responsive-attack", "Attack confirmation preserves action identifier")
	check(not Attack.Call(player, sword, { enemy }, "too-soon").success, "Server attack cooldown preserved")
	player:SetAttribute("TeleportProtected", true)
	check(Mine.Call(player, pickaxe, rock, rock.Position, "protected").reason == "invalid_character",
		"Transition protection rejects mining")
	check(not Attack.Call(player, sword, { enemy }, "protected").success,
		"Transition protection rejects combat")
end, debug.traceback)

fixtures:Destroy()
for _, tool in ipairs(tools) do tool:Destroy() end
client:SetDataValue("Inventory", originalInventory)
client:SetDataValue("HotbarSlots", originalSlots)
client:SetDataValue("SelectedHotbarSlot", originalSelected)
client:SetDataValue("Level", originalLevel)
player:SetAttribute("TeleportProtected", originalProtected)
character:PivotTo(originalPivot)
root.Anchored = originalAnchored
assert(ok, failure)
return { suite = "ResponsiveActionsServer", checks = checks, playerDataRestored = true }
