local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local APIService = require(ReplicatedStorage.services.APIService)

local player = Players.LocalPlayer

local placeBombAnim = Instance.new("Animation")
placeBombAnim.AnimationId = "rbxassetid://135782976252428"

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

		cachedTrack = animator:LoadAnimation(placeBombAnim)
		cachedTrack.Looped = false
		cachedTrack.Priority = Enum.AnimationPriority.Action
	end

	return cachedTrack
end

local BombAction = {}

function BombAction.Activate()
	local character = player.Character
	if character == nil or character.Parent == nil then
		return 0.5
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return 0.5
	end

	local track = getTrack(humanoid)
	if track then
		track:Play()
	end

	local result = APIService.GetFunction("UseBomb"):InvokeServer()
	return (result and result.cooldown) or 0.5
end

return BombAction
