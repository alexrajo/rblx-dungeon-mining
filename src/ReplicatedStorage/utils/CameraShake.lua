local RunService = game:GetService("RunService")

local module = {}

function module.Apply(humanoid: Humanoid, magnitude: number, frequency: number, duration: number, fadeIn: number, fadeOut: number)
	local t = 0
	local updateConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
		if t >= duration then
			return
		end
		
		local scale = 1
		if t <= fadeIn then
			scale = t / fadeIn
		elseif t >= duration-fadeOut then
			local t0 = duration-fadeOut
			scale = 1 - (t-t0)/t0
		end
		
		local offsetX = scale * magnitude * math.sin(t*2*math.pi*frequency)
		local offsetY = scale * magnitude * math.sin((t+0.5)*2*math.pi*(frequency+0.5))
		
		-- Apply offset to camera
		humanoid.CameraOffset = Vector3.new(offsetX, offsetY, 0)
		
		t += deltaTime
	end)
	delay(duration, function()
		updateConnection:Disconnect()
		updateConnection = nil
		humanoid.CameraOffset = Vector3.zero
	end)
end

return module
