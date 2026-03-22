local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

local effects = ReplicatedStorage.effects
local burpEffects = effects.burp

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))
local BURP_DURATION = globalConfig.BURP_DURATION
local CLOUD_MULTI = globalConfig.BURP_CLOUD_MULTI

local cloudFolder = game.Workspace:FindFirstChild("BurpClouds")
if cloudFolder == nil then
	cloudFolder = Instance.new("Folder", game.Workspace)
	cloudFolder.Name = "BurpClouds"
end

local module = {}

function spawnClouds(head: Part, burpDistance: number)
	-- Spawn cloud meshes for effects and tween them
	local cloudMeshRef = burpEffects.Cloud
	local tweenDuration = 1
	local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local cloudDistance = burpDistance*0.9
	local numberOfClouds = math.clamp(math.floor(CLOUD_MULTI*cloudDistance)*0.5, 1, 500)
	local minWaitTime = 1/30
	local waitTime = (BURP_DURATION-tweenDuration)/numberOfClouds
	local cloudsPerWait = math.max(1, math.ceil(minWaitTime/waitTime))

	for i = 1, numberOfClouds do
		if i % cloudsPerWait == 0 then
			task.wait(waitTime)
		end
		local cloudMesh = cloudMeshRef:Clone()
		cloudMesh.Anchored = true
		cloudMesh.CanCollide = false
		cloudMesh.CFrame = head.CFrame*CFrame.new(0, 0, -0.2)*CFrame.Angles(math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)))
		cloudMesh.Size = Vector3.new(0.5, 0.5, 0.5)
		cloudMesh.Color = Color3.new(0.282948, 0.794919, 0.240711)
		cloudMesh.Transparency = 0.5
		cloudMesh.CastShadow = false

		local tween = TweenService:Create(cloudMesh, tweenInfo, {
			CFrame = head.CFrame*CFrame.Angles(math.rad(math.random(-20, 30)), math.rad(math.random(-45, 45)), math.rad(math.random(-45, 45)))*CFrame.new(0, 0, -cloudDistance),
			Size = Vector3.new(cloudDistance, cloudDistance, cloudDistance),
			Transparency = 1
		})
		cloudMesh.Parent = cloudFolder
		tween:Play()
		Debris:AddItem(cloudMesh, tweenDuration)
	end
end

function module.Visualize(character: Model, level: number, burpCharge: number)
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	local burpEmissionPart = Instance.new("Part")
	burpEmissionPart.Name = "BurpEmissionPart"
	burpEmissionPart.Massless = true
	burpEmissionPart.Transparency = 1
	burpEmissionPart.CanCollide = false
	burpEmissionPart.Size = Vector3.new(0.1, 0.1, 0.1)

	local weld = Instance.new("Weld")
	weld.Parent = burpEmissionPart
	weld.Part0 = burpEmissionPart
	weld.Part1 = head
	weld.C1 = CFrame.new(0, -head.Size.Y*3/14, -head.Size.Z/2)

	burpEmissionPart.Parent = character

	local burpParticle = burpEffects.MouthParticles:Clone()
	burpParticle.Parent = burpEmissionPart
	burpParticle.Enabled = true

	local burpSound = burpEffects.BurpSound:Clone()
	local pitchShift = Instance.new("PitchShiftSoundEffect")
	pitchShift.Octave = 10/level
	pitchShift.Parent = burpSound
	burpSound.Parent = burpEmissionPart
	burpSound:Play()

	task.spawn(function()
		local burpDistance = StatCalculation.GetBurpDistance(level, burpCharge)
		spawnClouds(head, burpDistance)
	end)

	task.delay(BURP_DURATION, function()
		burpEmissionPart:Destroy()
	end)
end

return module
