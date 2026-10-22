-- Temporary local server runner requires this after other server suites.
-- The matching client suite ends the fixture through ResponsiveTestsControl.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local APIService = require(ReplicatedStorage.services.APIService)
local modules = ServerScriptService.modules
local PlayerData = require(modules.PlayerDataHandler)
local OreService = require(modules.OreNodeService)
local State = require(modules.DestructibleStateService)
local player = assert(Players:GetPlayers()[1])
local client = assert(PlayerData.GetClient(player))
local character = assert(player.Character)
local root = assert(character:FindFirstChild("HumanoidRootPart")) :: BasePart
local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
local originalPivot, originalAnchored = character:GetPivot(), root.Anchored
local originalHealth, originalMaxHealth = humanoid.Health, humanoid.MaxHealth
local originalProtected = player:GetAttribute("TeleportProtected")
local function clone(value: any): any
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end
local saved = {}
for field in pairs(require(modules.PlayerDataHandler.ProfileTemplate)) do saved[field] = clone(client:GetDataValue(field)) end
local fixtures = Instance.new("Folder")
fixtures.Name = "ResponsiveNetworkFixtures"
fixtures.Parent = workspace
local restored = false
local function restore(): ()
	if restored then return end
	restored = true
	fixtures:Destroy()
	for field, value in pairs(saved) do client:SetDataValue(field, value) end
	player:SetAttribute("TeleportProtected", originalProtected)
	character:PivotTo(originalPivot)
	root.Anchored = originalAnchored
	humanoid.MaxHealth = originalMaxHealth
	humanoid.Health = originalHealth
	PlayerData.ApplyPlayerMoveSpeed(player)
end
root.Anchored = true
character:PivotTo(CFrame.new(0, 24000, 0))
player:SetAttribute("TeleportProtected", false)
client:SetDataValue("Level", 1)
client:SetDataValue("XP", 0)
client:SetDataValue("Inventory", {{id = "responsive-network-pickaxe", name = "Wood Pickaxe"}})
PlayerData.SetHotbarSlots(player, {"responsive-network-pickaxe"})
client:SetDataValue("SelectedHotbarSlot", 0)

local function ore(name: string, offset: Vector3, hp: number): Model
	local node = Instance.new("Model")
	node.Name = name
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Anchored = true
	rock.Size = Vector3.new(2, 2, 2)
	rock.Position = root.Position + offset
	rock.Parent = node
	node.PrimaryPart = rock
	node:SetAttribute("OreType", "Stone")
	node:SetAttribute("NodeHP", hp)
	node:SetAttribute("FloorNumber", PlayerData.GetCurrentFloor(player))
	node.Parent = fixtures
	CollectionService:AddTag(node, "OreNode")
	node:SetAttribute("CurrentHP", hp)
	node:SetAttribute("DropType", nil) -- Deterministic one Stone per break.
	State.Initialize(node)
	return node
end
local normal = ore("NormalOre", Vector3.new(0, 0, -6), 100)
local finishing = ore("FinishingOre", Vector3.new(4, 0, -6), 1)
finishing:SetAttribute("RevealsLadder", true)
local unsolicited = ore("UnsolicitedOre", Vector3.new(-4, 0, -6), 1)
local function inspect(): any
	local ladders = 0
	for _, child in ipairs(fixtures:GetChildren()) do if child.Name == "Ladder" then ladders += 1 end end
	return {xp = client:GetDataValue("XP"), stone = PlayerData.GetItemCount(player, "Stone"), ladders = ladders}
end
APIService:CreateFunctionEndpoint("ResponsiveTestsControl", function(caller: Player, command: string): any
	assert(caller == player)
	if command == "inspect" then return inspect() end
	if command == "unsolicited" then
		local first = OreService.BreakNode(player, unsolicited)
		local second = OreService.BreakNode(player, unsolicited)
		return { first = first, second = second, state = inspect() }
	end
	if command == "finish" then restore() return { restored = true } end
	error("Unknown test command")
end)
task.delay(60, restore) -- Restore even if the client suite aborts.
return { ready = true }
