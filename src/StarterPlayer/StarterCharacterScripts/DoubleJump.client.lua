local UIS = game:GetService("UserInputService")
local soundService = game:GetService("SoundService")

local inAir = false
local maxJumps = 2
local jumpsLeft = maxJumps

local plr = game.Players.LocalPlayer
local char = plr.Character
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local doubleJumpAnim = Instance.new("Animation")
doubleJumpAnim.AnimationId = "http://roblox.com/asset/?id=05176714768"

local doubleJumpAnimTrack = humanoid:LoadAnimation(doubleJumpAnim)

local jumpCooldownActive = false
local isFalling = false
local deb = false
local minimumFallHeightParticleActivation = 30

local function WindGust(doGravity)
	local p = script.AirGust:Clone()
	p.Parent = root
	p.Acceleration = Vector3.new(0, doGravity and -3 or 0, 0)
	p.Enabled = true
	delay(0.2, function()
		p.Enabled = false
	end)
	game:GetService("Debris"):AddItem(p, 4)
end

local function DoubleJump()
	root.Velocity = Vector3.new(root.Velocity.X, humanoid.JumpPower*2, root.Velocity.Z)
	doubleJumpAnimTrack:Play()
	soundService:PlayLocalSound(script.Woosh)
	WindGust(false)
end

humanoid.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
		inAir = false
		jumpsLeft = maxJumps
	else
		inAir = true
	end
end)

humanoid.FreeFalling:connect(function(falling)
	isFalling = falling
	if isFalling and not deb then
		deb = true
		local maxHeight = 0
		while isFalling do
			local height = math.abs(root.Position.y)
			if height > maxHeight then
				maxHeight = height
			end
			wait()
		end
		local fallHeight = maxHeight - root.Position.y -- studs fallen
		--		print(character.Name.. " fell " .. math.floor(fallHeight + 0.5) .. " studs")
		if fallHeight > minimumFallHeightParticleActivation then
			WindGust(true)
		end
		deb = false
	end
end)

UIS.JumpRequest:Connect(function()
	if jumpCooldownActive then return end
	jumpCooldownActive = true
	if jumpsLeft > 0 then
		if jumpsLeft < maxJumps then
			DoubleJump()
		end
		jumpsLeft = jumpsLeft - 1
	end
	delay(0.2, function()
		jumpCooldownActive = false
	end)
end)