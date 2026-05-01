local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local APIService = require(ReplicatedStorage.services.APIService)
local ConsumablesConfig = require(ReplicatedStorage.configs.ConsumablesConfig)

local player = Players.LocalPlayer

local consumeAnim = Instance.new("Animation")
consumeAnim.AnimationId = "rbxassetid://108089721857463"

local cachedCharacter: Model? = nil
local cachedTrack: AnimationTrack? = nil

local function getTrack(humanoid: Humanoid): AnimationTrack?
	local character = humanoid.Parent
	if character ~= cachedCharacter then
		cachedCharacter = character
		cachedTrack = nil
	end

	if cachedTrack == nil then
		local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5)
		if animator == nil then
			return nil
		end

		cachedTrack = animator:LoadAnimation(consumeAnim)
		cachedTrack.Looped = false
		cachedTrack.Priority = Enum.AnimationPriority.Action
	end

	return cachedTrack
end

local UseConsumableAction = {}

function UseConsumableAction.Activate()
	local character = player.Character
	if character == nil or character.Parent == nil then
		return 0.5
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return 0.5
	end

	-- Return the cooldown immediately without waiting for the server response.
	local cooldown = ConsumablesConfig.USE_COOLDOWN

	local track = getTrack(humanoid)
	if track then
		track:Play()
	end

	-- Spawn the server call in the background; the client cooldown is already
	-- determined above and does not depend on the server response.
	task.spawn(function()
		APIService.GetFunction("UseConsumable"):InvokeServer()
	end)

	return cooldown
end

return UseConsumableAction
