local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)
local BombService = require(modules.BombService)

local configs = ReplicatedStorage.configs
local BombConfig = require(configs.BombConfig)

local debounce = {}

local endpoint = {}

local function getSelectedBombItemName(player: Player): string?
	local selectedSlot = PlayerDataHandler.GetSelectedHotbarSlot(player)
	if selectedSlot <= 0 then
		return nil
	end

	local hotbarSlots = PlayerDataHandler.GetHotbarSlots(player)
	local itemName = hotbarSlots[selectedSlot]
	if not BombConfig.IsBombItem(itemName) then
		return nil
	end

	return itemName
end

local function getToolHandleTemplate(itemName: string): Instance?
	local toolsFolder = ServerStorage:FindFirstChild("Tools")
	local bombFolder = toolsFolder and toolsFolder:FindFirstChild("Bombs")
	local toolTemplate = bombFolder and bombFolder:FindFirstChild(itemName)
	if toolTemplate == nil or not toolTemplate:IsA("Tool") then
		return nil
	end

	return toolTemplate:FindFirstChild("Handle")
end

function endpoint.Call(player: Player)
	if debounce[player] then
		return { success = false, cooldown = 0.1 }
	end

	local bombItemName = getSelectedBombItemName(player)
	if bombItemName == nil then
		return { success = false, cooldown = 0.1, reason = "invalid_bomb" }
	end

	local bombData = BombConfig.GetBombData(bombItemName)
	if bombData == nil then
		return { success = false, cooldown = 0.1, reason = "invalid_bomb" }
	end

	if PlayerDataHandler.GetItemCount(player, bombItemName) <= 0 then
		return { success = false, cooldown = 0.1, reason = "missing_bomb" }
	end

	local floorNumber = PlayerDataHandler.GetCurrentFloor(player)
	if floorNumber <= 0 then
		return { success = false, cooldown = 0.1, reason = "not_in_mine" }
	end

	local character = player.Character
	if character == nil then
		return { success = false, cooldown = 0.1 }
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or humanoidRootPart == nil then
		return { success = false, cooldown = 0.1 }
	end

	debounce[player] = true
	task.delay(0.35, function()
		debounce[player] = nil
	end)

	PlayerDataHandler.TakeItems(player, { [bombItemName] = 1 })

	local bombPosition = humanoidRootPart.Position - Vector3.new(0, humanoid.HipHeight, 0)
	local visual = BombService.CreatePlacedBombVisual(getToolHandleTemplate(bombItemName), bombPosition)
	if visual ~= nil then
		visual:SetAttribute("FloorNumber", floorNumber)
	end

	task.delay(bombData.fuseTime, function()
		local explosion = Instance.new("Explosion")
		explosion.BlastPressure = 0
		explosion.BlastRadius = bombData.radius
		explosion.DestroyJointRadiusPercent = 0
		explosion.Position = bombPosition
		explosion.Parent = workspace

		BombService.ResolveExplosion(player, bombItemName, bombPosition, floorNumber)

		if visual ~= nil and visual.Parent ~= nil then
			visual:Destroy()
		end
	end)

	return { success = true, cooldown = bombData.fuseTime }
end

return endpoint
