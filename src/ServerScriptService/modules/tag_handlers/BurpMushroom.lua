local ReplicatedStorage = game:GetService("ReplicatedStorage")
local utils = ReplicatedStorage.utils
local VisualizeBurp = require(utils.VisualizeBurp)

local TagHandler = {}

local IDLE_ANIMATION_ID = "128966266615975"
local ATTACK_ANIMATION_ID = "98066694946359"
local ATTACK_DISTANCE_THRESHOLD = 10

local idleAnimation = Instance.new("Animation")
idleAnimation.AnimationId = "http://roblox.com/asset?id="..IDLE_ANIMATION_ID

local attackAnimation = Instance.new("Animation")
attackAnimation.AnimationId = "http://roblox.com/asset?id="..ATTACK_ANIMATION_ID

function TagHandler.Apply(instance: Instance)
	local level = instance:GetAttribute("Level") or 1
	local attackDistanceThreshold = instance:GetAttribute("AttackDistance") or ATTACK_DISTANCE_THRESHOLD
	local animationController = instance:FindFirstChildOfClass("AnimationController")
	local animator = animationController:FindFirstChildOfClass("Animator")
	
	if animator == nil then
		animator = Instance.new("Animator")
		animator.Parent = animationController
	end
	
	local idleAnimTrack = animator:LoadAnimation(idleAnimation)
	local attackAnimTrack = animator:LoadAnimation(attackAnimation)
	attackAnimTrack.Looped = false
		
	idleAnimTrack:Play()
	
	spawn(function()
		while instance.Parent ~= nil do
			local closestPlayer = nil
			local closestDistance = math.huge

			local players = game:GetService("Players")
			for _, plr in pairs(players:GetPlayers()) do
				local char = plr.Character
				if char then
					local root = char:FindFirstChild("HumanoidRootPart")
					if root and instance and instance.PrimaryPart then
						local pivot = instance:GetPivot()
						local heading = pivot.LookVector
						local centerDistance = (pivot.Position - root.Position).Magnitude
						local frontDistance = ((pivot.Position + heading) - root.Position).Magnitude
						if centerDistance < closestDistance and frontDistance < centerDistance then
							closestDistance = centerDistance
							closestPlayer = plr
						end
					end
				end
			end
			if closestDistance < attackDistanceThreshold then
				attackAnimTrack:Play()
				task.wait(1.5)
				VisualizeBurp.Visualize(instance, level, 1)
				task.wait(3.5)
			else
				local waitTime = math.clamp(math.floor(closestDistance / attackDistanceThreshold / 2), 0.3, 10)
				task.wait(waitTime)
			end
		end
	end)
end

return TagHandler
