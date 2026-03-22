local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local ambienceFolders = ReplicatedStorage:WaitForChild("area_ambiance")
local lightingProperties = {}

local defaultLightingProperties = require(ambienceFolders:WaitForChild("default"):WaitForChild("LightingProperties"))

for _, ambience in pairs(ambienceFolders:GetChildren()) do
	local lightingPropertiesModuleScript = ambience:FindFirstChild("LightingProperties")
	if lightingPropertiesModuleScript ~= nil and lightingPropertiesModuleScript:IsA("ModuleScript") then
		lightingProperties[ambience.Name] = require(lightingPropertiesModuleScript)
	else
		lightingProperties[ambience.Name] = defaultLightingProperties
	end
end

local lastCheck = tick()
local lastPosition = Vector3.new()
local currentAreaType = "default"

function check(hrp: BasePart)
	local areaBounds = CollectionService:GetTagged("AreaBoundingBox")
	local closestBrick = nil
	local closestDistance = math.huge

	for _, brick: BasePart in pairs(areaBounds) do
		if not brick:IsA("BasePart") then continue end

		-- Convert to the brick's local space
		local relativePos = brick.CFrame:PointToObjectSpace(hrp.Position)
		local halfSize = brick.Size / 2

		local inside = math.abs(relativePos.X) <= halfSize.X and
			math.abs(relativePos.Y) <= halfSize.Y and
			math.abs(relativePos.Z) <= halfSize.Z

		if inside then
			local distance = (brick.Position - hrp.Position).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closestBrick = brick
			end
		end
	end
	
	local areaType = "default"
	if closestBrick then
		areaType = closestBrick:GetAttribute("AreaType") or "default"
	end
	
	if currentAreaType ~= areaType then
		currentAreaType = areaType
		
		changeMusicCategory(areaType)
		
		local ambience = ambienceFolders:FindFirstChild(areaType)
		if ambience == nil then return end
		
		for _, v in pairs(game.Lighting:GetChildren()) do
			if v:IsA("BlurEffect") then continue end
			v:Destroy()
		end
		
		for _, v in pairs(ambience.lighting:GetChildren()) do
			if v:IsA("BlurEffect") then continue end
			v:Clone().Parent = game.Lighting
		end
		
		local areaLightingProperties = lightingProperties[areaType]
		if areaLightingProperties then
			for property, value in pairs(areaLightingProperties) do
				game.Lighting[property] = value
			end
		end
	end
end

function update(deltaTime)
	local character = game.Players.LocalPlayer.Character
	if not character then
		lastPosition = Vector3.new()
		return 
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local currentPosition = hrp.Position

	if (currentPosition - lastPosition).Magnitude > 3 or (tick() - lastCheck) > 3 then
		lastCheck = tick()
		lastPosition = currentPosition
		
		--local startTime = os.clock()
		check(hrp)
		--local endTime = os.clock()
		--print("Benchmark: ", (endTime-startTime)*1000, "ms")
	end
end

local songPool = {}
local nextSongPool = {}

local songEndedConnection
local currentlyPlayingSong

function changeMusicCategory(categoryName: string)
	if songEndedConnection then
		songEndedConnection:Disconnect()
		songEndedConnection = nil
	end
	
	if currentlyPlayingSong then
		currentlyPlayingSong:Stop()
	end
	
	selectMusic(categoryName)
end

function selectMusic(categoryName: string)
	local folder = ambienceFolders:FindFirstChild(categoryName):FindFirstChild("music")
	if folder then
		songPool = folder:GetChildren()
		nextSongPool = table.clone(songPool)
		playNextSong()
	else
		selectMusic("default")
		return
	end
end

function playNextSong()
	if songEndedConnection ~= nil then
		songEndedConnection:Disconnect()
		songEndedConnection = nil
	end

	local song: Sound = nextSongPool[math.random(1, #nextSongPool)]
	if song then
		song.Volume = math.min(0.35, song.Volume)
		song:Play()
		songEndedConnection = song.Ended:Connect(function()
			local newNextSongPool = {}
			for _, v in pairs(songPool) do
				if v ~= song and #songPool > 1 then
					table.insert(newNextSongPool, v)
				end
			end
			nextSongPool = newNextSongPool

			playNextSong()
		end)
			
		currentlyPlayingSong = song
	else
		playNextSong()
	end
end

RunService.Heartbeat:Connect(update)
selectMusic(currentAreaType)

