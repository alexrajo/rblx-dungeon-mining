local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileService = require(ReplicatedStorage.services.ProfileService)

local DatabaseClient = {}
DatabaseClient.__index = DatabaseClient

local DATASTORE_PREFIX = "PlayerData1_"

function updatePlayerDataFolder(playerDataFolder: Folder, dbProfile)
	if playerDataFolder == nil then warn("updatePlayerDataFolder: player data folder was not provided / was nil!") return end
	if dbProfile == nil then warn("updatePlayerDataFolder: dbProfile was not provided / was nil!") return end
	local data = dbProfile.Data
	for key, value in pairs(data) do
		local valueType = typeof(value)
		local valueRef = playerDataFolder:FindFirstChild(key)
		if valueRef == nil then
			if valueType == "number" then
				valueRef = Instance.new("NumberValue")
			elseif valueType == "string" then
				valueRef = Instance.new("StringValue")
			elseif valueType == "boolean" then
				valueRef = Instance.new("BoolValue")
			elseif valueType == "table" then
				valueRef = Instance.new("Folder")
			else
				warn("updatePlayerDataFolder: Type "..valueType.." not recognized.")
				continue
			end
			valueRef.Name = key
			valueRef.Parent = playerDataFolder
		end
		if valueRef:IsA("ValueBase") then
			valueRef.Value = value
		elseif valueRef:IsA("Folder") then
			local expectedEntries = {}
			for _, entry in pairs(value) do
				if typeof(entry) == "table" and type(entry.name) == "string" then
					expectedEntries[entry.name] = true
				end
			end

			for _, child in ipairs(valueRef:GetChildren()) do
				if not expectedEntries[child.Name] then
					child:Destroy()
				end
			end

			for i, entry in pairs(value) do
				local success, err = pcall(function()
					local entryValue = entry.value
					local entryName = entry.name
					local entryType = typeof(entryValue)

					local entryValueRef = valueRef:FindFirstChild(entryName)
					if entryValueRef == nil then
						if entryType == "number" then
							entryValueRef = Instance.new("NumberValue")
						elseif entryType == "string" then
							entryValueRef = Instance.new("StringValue")
						elseif entryType == "boolean" then
							entryValueRef = Instance.new("BoolValue")
						else
							error("Type "..entryType.." not recognized. From value: "..entryValue..", key: "..key)
						end

						entryValueRef.Name = entryName
						entryValueRef.Parent = valueRef
					end
					entryValueRef.Value = entryValue
				end)
				if not success then
					warn("updatePlayerDataFolder - entry:", err)
				end
			end
		end
	end
end

function DatabaseClient.new(profileStore, dataFolder: Folder, player: Player, onRelease)
	if profileStore == nil or player == nil then return end
	local self = {}
	setmetatable(self, DatabaseClient)
	
	local profile = profileStore:LoadProfileAsync(DATASTORE_PREFIX..player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			self:_onRelease()
		end)
		if player:IsDescendantOf(game.Players) == false then
			-- Player left before the profile loaded:
			profile:Release()
			return nil
		end
	else
		return nil
	end
	
	-- Private fields
	self._connections = {}
	self._profile = profile
	self._onReleaseExternal = onRelease
	self._player = player
	----------------
	
	-- Set up player data folder
	local playerDataFolder = Instance.new("Folder")
	playerDataFolder.Name = player.Name
	updatePlayerDataFolder(playerDataFolder, profile)
	playerDataFolder.Parent = dataFolder
	self._playerDataFolder = playerDataFolder
	
	return self
end

function DatabaseClient:_addConnection(connection: RBXScriptConnection)
	table.insert(self._connections, connection)
end

function DatabaseClient:_disconnectConnections()
	for i, connection in pairs(self._connections) do
		if connection == nil then continue end
		connection:Disconnect()
	end
	self._connections = {}
end

function DatabaseClient:_onRelease()
	self:_disconnectConnections()
	
	print("Profile released")
	if self._onReleaseExternal == nil then
		warn("An external profile release handler was not provided to the database client. Client for player:", self._player)
		return
	end
	self._onReleaseExternal(self)
end

--[[
@ param key: string - the key used for locating the data
@ param defaultValue: any - the default value returned if nil is found
]]
function DatabaseClient:GetDataValue(key: string, defaultValue: any)
	local dataValue = self._profile.Data[key]
	if dataValue == nil then 
		return defaultValue ~= nil and defaultValue or nil
	end
	return dataValue
end

--[[
@ param key: string - the key used for locating the data field
@ param value: any - the value assign to the data field
]]
function DatabaseClient:SetDataValue(key: string, value: any)
	if value == nil then error("A value is required when setting a data value") end
	self._profile.Data[key] = value
	updatePlayerDataFolder(self._playerDataFolder, self._profile)
end

--[[
@ param key: string - the key used for locating the data field
@ param callback: (value: any) -> () - the function to call when the value updates
]]
function DatabaseClient:ListenToDataValue(key: string, callback: (value: any) -> ())
	local function onChange()
		local data = self:GetDataValue(key)
		callback(data)
	end
	
	local playerDataFolder = self._playerDataFolder
	local dataValue: ValueBase | Folder = playerDataFolder and playerDataFolder:FindFirstChild(key)
	if dataValue == nil then
		warn("Cannot listen to data value. Data value for key:", key, "does not exist for player:", self._player)
		return
	end
	if dataValue:IsA("ValueBase") then
		local connection = dataValue.Changed:Connect(onChange)
		self:_addConnection(connection)
	elseif dataValue:IsA("Folder") then
		self:_addConnection(dataValue.ChildAdded:Connect(function(newVal)
			if newVal:IsA("ValueBase") then
				self:_addConnection(newVal.Changed:Connect(onChange))
			end
			onChange()
		end))
		self:_addConnection(dataValue.ChildRemoved:Connect(onChange))
		
		for _, child in ipairs(dataValue:GetChildren()) do
			if child:IsA("ValueBase") then
				self:_addConnection(child.Changed:Connect(onChange))
			end
		end
	end
end

return DatabaseClient
