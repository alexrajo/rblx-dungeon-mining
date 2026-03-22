local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local effects = ReplicatedStorage.effects
local burpEffects = effects.burp

local utils = ReplicatedStorage.utils
local LinAlg = require(utils.LinAlg)
local TableUtils = require(utils.TableUtils)
local StatCalculation = require(utils.StatCalculation)
local StatRetrieval = require(utils.StatRetrieval)
local CameraShake = require(utils.CameraShake)

local getPlayerStat = StatRetrieval.GetPlayerStat

local NUMBER_OF_CLOUDS = 30
local BURP_DURATION = 2
local MAX_BURP_DISTANCE = 20000

local BurpAction = {}

--[[
	Function to be called to activate the action
]]
function BurpAction.Activate()
	local burpCharge = StatRetrieval.GetPlayerStat("BurpCharge", plr)
	if burpCharge == nil or burpCharge <= 0 then return 0.5 end


	local character = plr.Character
	if character == nil or character.Parent == nil then return 0.5 end
	local head: BasePart = character:FindFirstChild("Head")
	local humanoidRootPart: BasePart = character:FindFirstChild("HumanoidRootPart")
	local ownHumanoid = character:FindFirstChild("Humanoid")
	if head == nil or humanoidRootPart == nil or ownHumanoid == nil or ownHumanoid.Health <= 0 then return 0.5 end

	local burpPoints = getPlayerStat("BurpPoints", plr)
	local burpDistance = StatCalculation.GetBurpDistance(burpPoints, burpCharge)
	local burpForce = StatCalculation.GetBurpForce(burpPoints, burpCharge)

	-- Effects
	CameraShake.Apply(ownHumanoid, math.min(0.3*burpForce/300, 1), 10, 1, 0, 0.5)

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
	pitchShift.Octave = 10000/burpPoints
	pitchShift.Parent = burpSound
	burpSound.Parent = burpEmissionPart
	burpSound:Play()

	task.spawn(function()
		-- Spawn cloud meshes for effects and tween them
		local cloudMeshRef = burpEffects.Cloud
		local tweenDuration = 1
		local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local cloudDistance = burpDistance*0.5

		for i = 1, NUMBER_OF_CLOUDS do
			task.wait((BURP_DURATION-tweenDuration)/NUMBER_OF_CLOUDS)
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
			cloudMesh.Parent = workspace
			tween:Play()
			Debris:AddItem(cloudMesh, tweenDuration)
		end
	end)

	task.delay(BURP_DURATION, function()
		burpEmissionPart:Destroy()
	end)
	--

	local cameraDirection = cam.CFrame.LookVector

	local spheres = {}

	local reach = 0
	local i = 0
	while reach < burpDistance and reach < MAX_BURP_DISTANCE do
		i += 1

		local newSphere = {
			center = head.Position + cameraDirection*(head.Size.X/2+reach),
			radius = i/2
		}

		table.insert(spheres, newSphere)

		reach += i
	end

	local hitCharacters = {}
	local hitPartsForCharacters = {} -- The hit parts hit on character

	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {character}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	for _, sphere in pairs(spheres) do

		local sphereHitParts = workspace:GetPartBoundsInRadius(sphere.center, sphere.radius, overlapParams)

		for _, hitPart in pairs(sphereHitParts) do
			local char = hitPart.Parent
			if TableUtils.TableContains(hitCharacters, char) then continue end

			if char ~= workspace and char:FindFirstChildOfClass("Humanoid") then
				table.insert(hitCharacters, char)
				table.insert(hitPartsForCharacters, hitPart)
				continue
			end

			char = hitPart.Parent.Parent
			if TableUtils.TableContains(hitCharacters, char) then continue end

			if char ~= workspace and char:FindFirstChildOfClass("Humanoid") then
				table.insert(hitCharacters, char)
				table.insert(hitPartsForCharacters, hitPart)
			end
		end
	end

	local hitHumanoids = {}
	for _, hitCharacter in pairs(hitCharacters) do
		local humanoid = hitCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			table.insert(hitHumanoids, humanoid)
		end
	end

	-- Visualization of hit detecting raycasts
	--[[
	for _, direction in pairs(rayDirections) do
		local ray = Instance.new("Part")
		ray.Anchored = true
		ray.CanCollide = false
		ray.BrickColor = BrickColor.Red()
		ray.Size = Vector3.new(0.1, 0.1, burpDistance)
		ray.CFrame = CFrame.lookAt(rayOrigin, rayOrigin+direction)*CFrame.new(0, 0, -burpDistance/2)
		ray.Parent = workspace
		game:GetService("Debris"):AddItem(ray, 1)
	end
	]]

	-- Visualization of hit detecting spheres
	for _, s in pairs(spheres) do
		local sphere = Instance.new("Part")
		sphere.Shape = Enum.PartType.Ball
		sphere.Anchored = true
		sphere.CanCollide = false
		sphere.BrickColor = BrickColor.Red()
		sphere.Size = Vector3.new(s.radius, s.radius, s.radius)
		sphere.Position = s.center
		sphere.Parent = workspace
		game:GetService("Debris"):AddItem(sphere, 1)
	end

	print(spheres)

	local func = APIService.GetFunction("Burp")
	return func:InvokeServer({humanoids = hitHumanoids, parts = hitPartsForCharacters}) -- Returns cooldown time
end

return BurpAction
