local TagHandler = {}

function TagHandler.Apply(instance: Instance)
	local animationId = instance:GetAttribute("AnimationId")
	if animationId == nil then
		warn("No animation id provided in animated instance:", instance)
		return
	end
	
	local animator = nil
	local humanoid = instance:FindFirstChildOfClass("Humanoid")
	if humanoid then
		animator = humanoid:FindFirstChildOfClass("Animator")
	else
		local animationController = instance:FindFirstChildOfClass("AnimationController")
		if animationController then
			animator = animationController:FindFirstChildOfClass("Animator")
		end
	end
	if animator == nil then
		warn("No animator in animated instance:", instance)
		return
	end
	
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://"..animationId
	
	local animationTrack = animator:LoadAnimation(animation)
	task.wait(3)
	animationTrack.Looped = true
	animationTrack:Play()
end

return TagHandler
