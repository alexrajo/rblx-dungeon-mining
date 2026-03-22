local TagHandler = {}

local runAnimId = "913376220"
local runAnim = Instance.new("Animation")
runAnim.AnimationId = "http://www.roblox.com/asset/?id="..runAnimId

local screamAnimId = "115416203963240"
local screamAnim = Instance.new("Animation")
screamAnim.AnimationId = "http://www.roblox.com/asset/?id="..screamAnimId

function _activate(instance: Model, humanoid: Humanoid)
	if instance.PrimaryPart then
		instance.PrimaryPart:SetNetworkOwner(nil) -- nil = server
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator ~= nil then
		local runTrack = animator:LoadAnimation(runAnim)
		runTrack.Looped = true
		runTrack:Play()

		local screamTrack = animator:LoadAnimation(screamAnim)
		screamTrack.Looped = true
		screamTrack:Play()
	else
		animator = Instance.new("Animator")
		animator.Parent = humanoid
		local runTrack = animator:LoadAnimation(runAnim)
		runTrack.Looped = true
		runTrack:Play()

		local screamTrack = animator:LoadAnimation(screamAnim)
		screamTrack.Looped = true
		screamTrack:Play()
	end
	
	local shortScream = script.ShortScream:Clone()
	shortScream.Parent = instance.PrimaryPart
	shortScream:Play()
	
	local longScream = script.LongScream:Clone()
	longScream.Parent = instance.PrimaryPart
	delay(shortScream.TimeLength, function()
		longScream:Play()
	end)

	local origin = instance:GetPivot().Position
	
	for i = 1, 10 do
		local direction = math.rad(math.random(0, 360))

		local walkVector = Vector3.new(math.cos(direction), 0, math.sin(direction))
		humanoid:Move(walkVector)

		task.wait(1)
	end
	
	-- Run back to origin and despawn
	humanoid:MoveTo(origin)
	humanoid.MoveToFinished:Once(function()
		instance:Destroy()
	end)
end

function TagHandler.Apply(instance: Model)
	if instance.ClassName ~= "Model" then
		warn(instance, "is not a Model!")
		return
	end
	local humanoid: Humanoid = instance:FindFirstChild("Humanoid")
	if humanoid == nil then
		warn("No humanoid in RunningNPC", instance)
		return
	end
	
	local function conditionallyActivate()
		local parent = instance.Parent
		local canActivate = false
		while parent ~= game and parent ~= nil do
			if parent == game.Workspace then
				canActivate = true
				break
			end
			parent = parent.Parent
		end
		if not canActivate then return end
		_activate(instance, humanoid)
	end
	
	instance:GetPropertyChangedSignal("Parent"):Once(conditionallyActivate)
	--conditionallyActivate()
end

return TagHandler
