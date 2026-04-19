local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local localPlayer = Players.LocalPlayer
local ambienceFolders = ReplicatedStorage:WaitForChild("area_ambiance")

local DEFAULT_THEME = "default"

local warnedMissingFallbacks = {}
local songPool = {}
local nextSongPool = {}
local songEndedConnection: RBXScriptConnection? = nil
local currentlyPlayingSong: Sound? = nil
local activeTheme = ""

local function warnMissingFallback(categoryName: string)
	if warnedMissingFallbacks[categoryName] then
		return
	end

	warnedMissingFallbacks[categoryName] = true
	warn("Ambience: Missing default ambience " .. categoryName .. "; skipping fallback.")
end

local function getThemeFolder(themeName: string): Instance?
	local folder = ambienceFolders:FindFirstChild(themeName)
	if folder ~= nil then
		return folder
	end

	if themeName ~= DEFAULT_THEME then
		return ambienceFolders:FindFirstChild(DEFAULT_THEME)
	end

	return nil
end

local function getAmbienceChild(themeName: string, childName: string): Instance?
	local themeFolder = ambienceFolders:FindFirstChild(themeName)
	local child = if themeFolder ~= nil then themeFolder:FindFirstChild(childName) else nil
	if child ~= nil then
		return child
	end

	local defaultFolder = ambienceFolders:FindFirstChild(DEFAULT_THEME)
	local defaultChild = if defaultFolder ~= nil then defaultFolder:FindFirstChild(childName) else nil
	if defaultChild == nil then
		warnMissingFallback(childName)
	end

	return defaultChild
end

local function getLightingProperties(themeName: string)
	local moduleScript = getAmbienceChild(themeName, "LightingProperties")
	if moduleScript == nil or not moduleScript:IsA("ModuleScript") then
		return nil
	end

	local success, properties = pcall(require, moduleScript)
	if success and type(properties) == "table" then
		return properties
	end

	if themeName ~= DEFAULT_THEME then
		local defaultModuleScript = getAmbienceChild(DEFAULT_THEME, "LightingProperties")
		if defaultModuleScript ~= nil and defaultModuleScript:IsA("ModuleScript") and defaultModuleScript ~= moduleScript then
			local defaultSuccess, defaultProperties = pcall(require, defaultModuleScript)
			if defaultSuccess and type(defaultProperties) == "table" then
				return defaultProperties
			end
		end
	end

	warn("Ambience: Could not load LightingProperties for theme " .. themeName .. ".")
	return nil
end

local function applyLightingInstances(themeName: string)
	local lightingFolder = getAmbienceChild(themeName, "lighting")

	for _, child in pairs(Lighting:GetChildren()) do
		if child:IsA("BlurEffect") then
			continue
		end

		child:Destroy()
	end

	if lightingFolder == nil then
		return
	end

	for _, child in pairs(lightingFolder:GetChildren()) do
		if child:IsA("BlurEffect") then
			continue
		end

		child:Clone().Parent = Lighting
	end
end

local function applyLightingProperties(themeName: string)
	local properties = getLightingProperties(themeName)
	if properties == nil then
		return
	end

	for property, value in pairs(properties) do
		local success = pcall(function()
			Lighting[property] = value
		end)

		if not success then
			warn("Ambience: Could not apply Lighting." .. tostring(property) .. ".")
		end
	end
end

local function getPlayableSounds(folder: Instance?): { Sound }
	local sounds = {}
	if folder == nil then
		return sounds
	end

	for _, child in pairs(folder:GetChildren()) do
		if child:IsA("Sound") then
			table.insert(sounds, child)
		end
	end

	return sounds
end

local function getMusicFolder(themeName: string): Instance?
	local musicFolder = getAmbienceChild(themeName, "music")
	if #getPlayableSounds(musicFolder) > 0 then
		return musicFolder
	end

	if themeName ~= DEFAULT_THEME then
		local defaultMusicFolder = getAmbienceChild(DEFAULT_THEME, "music")
		if #getPlayableSounds(defaultMusicFolder) > 0 then
			return defaultMusicFolder
		end
	end

	warnMissingFallback("music")
	return nil
end

local function stopMusic()
	if songEndedConnection ~= nil then
		songEndedConnection:Disconnect()
		songEndedConnection = nil
	end

	if currentlyPlayingSong ~= nil then
		currentlyPlayingSong:Stop()
		currentlyPlayingSong = nil
	end
end

local function playNextSong()
	if songEndedConnection ~= nil then
		songEndedConnection:Disconnect()
		songEndedConnection = nil
	end

	if #nextSongPool == 0 then
		nextSongPool = table.clone(songPool)
	end

	if #nextSongPool == 0 then
		return
	end

	local songIndex = math.random(1, #nextSongPool)
	local song = nextSongPool[songIndex]
	table.remove(nextSongPool, songIndex)

	song.Volume = math.min(0.35, song.Volume)
	song:Play()

	songEndedConnection = song.Ended:Connect(function()
		playNextSong()
	end)

	currentlyPlayingSong = song
end

local function applyMusic(themeName: string)
	stopMusic()

	local musicFolder = getMusicFolder(themeName)
	songPool = getPlayableSounds(musicFolder)
	nextSongPool = table.clone(songPool)

	playNextSong()
end

local function applyTheme(themeName: string)
	if themeName == nil or themeName == "" then
		themeName = DEFAULT_THEME
	end

	local resolvedThemeFolder = getThemeFolder(themeName)
	if resolvedThemeFolder == nil then
		themeName = DEFAULT_THEME
	end

	activeTheme = themeName
	applyMusic(themeName)
	applyLightingInstances(themeName)
	applyLightingProperties(themeName)
end

local playerDataFolder = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(localPlayer.Name)
local activeThemeValue = playerDataFolder:WaitForChild("ActiveTheme")

if activeThemeValue:IsA("StringValue") then
	activeThemeValue.Changed:Connect(function(themeName: string)
		if themeName ~= activeTheme then
			applyTheme(themeName)
		end
	end)

	applyTheme(activeThemeValue.Value)
else
	warn("Ambience: ActiveTheme must be a StringValue.")
	applyTheme(DEFAULT_THEME)
end
