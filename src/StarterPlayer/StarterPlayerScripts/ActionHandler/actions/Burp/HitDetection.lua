local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local utils = ReplicatedStorage.utils
local TableUtils = require(utils.TableUtils)
local LinAlg = require(utils.LinAlg)

local burpCloudsFolder = game.Workspace:WaitForChild("BurpClouds")

local refs = ReplicatedStorage.refs
local powerRequirementBillboard = refs.PowerRequirementBillboard

local DETECTION_RAY_DENSITY = 10
local BURP_RAY_ANGLE = 60
local USE_CAMERA_DIRECTION = false

local hitDetection = {}

function _addDestructibleInstance(hitDestructibleInstancesIndex, hitDestructibleInstances, burpPower, instance: Instance, hitPart: BasePart, hitPosition: Vector3)
	if hitDestructibleInstancesIndex[instance] == true then return end
	hitDestructibleInstancesIndex[instance] = true

	local powerRequirement = instance:GetAttribute("PowerRequirement")
	if powerRequirement == nil then
		powerRequirement = 0
	end

	if burpPower < powerRequirement then
		local success, err = pcall(function()
			local reqIndicator = powerRequirementBillboard:Clone()
			reqIndicator.Anchored = true
			reqIndicator.CanCollide = false
			reqIndicator.Transparency = 1
			reqIndicator.Position = hitPart.Position

			reqIndicator.BillboardGui.Amount.TextLabel.Text = powerRequirement
			reqIndicator.BillboardGui.Amount.TextLabel_Stroke.Text = powerRequirement

			Debris:AddItem(reqIndicator, 3)
			reqIndicator.Parent = game.Workspace
		end)
		if not success then
			warn("Error while indicating power requirement:", err)
		end
		return -- Don't destroy instance
	end

	table.insert(hitDestructibleInstances, {["instance"] = instance, ["hitPosition"] = hitPosition})
end

function hitDetection.detectHitsWithRays(cam, character, burpDistance, burpPower)
	local humanoidRootPart = character.HumanoidRootPart
	local head = character.Head
	
	local baseDirection = humanoidRootPart.CFrame.LookVector
	if USE_CAMERA_DIRECTION then
		baseDirection = cam.CFrame.LookVector
	end

	-- Raycast and register any characters in front of the player's look direction
	local rayOrigin = head.Position
	local rayDirections = {
		baseDirection,
	}

	for i = 1, DETECTION_RAY_DENSITY do
		local offset = i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.RightVector))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(-i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(-i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.RightVector))

		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE),  cam.CFrame.UpVector + cam.CFrame.RightVector))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector - cam.CFrame.RightVector))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(-i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector + cam.CFrame.RightVector))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(-i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector - cam.CFrame.RightVector))

		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE),  cam.CFrame.UpVector + cam.CFrame.RightVector/2))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector - cam.CFrame.RightVector/2))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(-i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector + cam.CFrame.RightVector/2))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(-i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector - cam.CFrame.RightVector/2))

		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE),  cam.CFrame.UpVector/2 + cam.CFrame.RightVector))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector/2 - cam.CFrame.RightVector))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(-i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector/2 + cam.CFrame.RightVector))
		table.insert(rayDirections, LinAlg.RotateVectorAround(baseDirection, math.rad(-i/DETECTION_RAY_DENSITY*BURP_RAY_ANGLE), cam.CFrame.UpVector/2 - cam.CFrame.RightVector))
	end
	
	local raycastParams = RaycastParams.new()
	raycastParams.IgnoreWater = true
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character, burpCloudsFolder}
	
	local hitCharacters = {}
	local hitPartsForCharacters = {} -- The hit parts hit on character
	local hitDestructibleInstances = {}
	local hitDestructibleInstancesIndex = {}

	for _, direction in pairs(rayDirections) do
		local raycastResult = game.Workspace:Raycast(rayOrigin, direction*burpDistance, raycastParams)		
		if raycastResult == nil then continue end

		local hitPart: BasePart = raycastResult.Instance
		local hitPosition = raycastResult.Position

		if hitPart:HasTag("DestructibleByBurp") then
			_addDestructibleInstance(hitDestructibleInstancesIndex, hitDestructibleInstances, burpPower, hitPart, hitPart, hitPosition)
			continue
		elseif hitPart.Parent:HasTag("DestructibleByBurp") then
			_addDestructibleInstance(hitDestructibleInstancesIndex, hitDestructibleInstances, burpPower, hitPart.Parent, hitPart, hitPosition)
			continue
		elseif hitPart.Parent.Parent:HasTag("DestructibleByBurp") then
			_addDestructibleInstance(hitDestructibleInstancesIndex, hitDestructibleInstances, burpPower, hitPart.Parent.Parent, hitPart, hitPosition)
			continue
		end

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
	--]]
	
	return {humanoids = hitHumanoids, characterParts = hitPartsForCharacters, destructibleInstances = hitDestructibleInstances}
end

return hitDetection
