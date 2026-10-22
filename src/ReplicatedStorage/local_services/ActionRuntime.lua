local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.configs.ActionConfig)
local Effects = require(ReplicatedStorage.local_services.ActionEffects)
local HotbarService = require(ReplicatedStorage.local_services.HotbarService)

local player = Players.LocalPlayer
local Runtime = {}
local tracks = {}
local animations = {}
local markerTimes = {}
local active = {}
local callbacks = {}
local focused = true
local initialized = false
local generation = 0
local characterGeneration = 0

function Runtime.GetFloor(): number
	local data = ReplicatedStorage:FindFirstChild("PlayerData")
	local mine = data and data:FindFirstChild(player.Name)
	local floor = mine and mine:FindFirstChild("CurrentFloor")
	return floor and floor.Value or 0
end

function Runtime.IsValid(tool: Tool?, character: Model?): boolean
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return focused and character ~= nil and character == player.Character and character.Parent ~= nil
		and humanoid ~= nil and humanoid.Health > 0 and tool ~= nil and tool.Parent == character
		and not player:GetAttribute("TeleportProtected") and HotbarService.GetSelectedTool() == tool
end

function Runtime.OnCancelled(callback: () -> ()): () -> ()
	table.insert(callbacks, callback)
	return function()
		local index = table.find(callbacks, callback)
		if index then table.remove(callbacks, index) end
	end
end

function Runtime.Cancel(): ()
	generation += 1
	for state in pairs(active) do
		if state.connection then state.connection:Disconnect() end
	end
	for _, track in pairs(tracks) do track:Stop(0.05) end
	table.clear(active)
	Effects.Reset()
	for _, callback in ipairs(callbacks) do
		local ok, err = pcall(callback)
		if not ok then warn("ActionRuntime: cancellation callback failed", err) end
	end
end

local function loadTrack(humanoid: Humanoid, id: number): AnimationTrack?
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return nil end
	local animation = animations[id]
	if not animation then
		animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. id
		animations[id] = animation
	end
	local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
	if not ok then warn("ActionRuntime: animation unavailable", id, track) return nil end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	tracks[id] = track
	return track
end

local function prepareCharacter(character: Model): ()
	Runtime.Cancel()
	characterGeneration += 1
	local version = characterGeneration
	for _, track in pairs(tracks) do track:Destroy() end
	table.clear(tracks)
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid or not humanoid:IsA("Humanoid") then return end
		humanoid.Died:Once(function() if player.Character == character then Runtime.Cancel() end end)
		if not humanoid:WaitForChild("Animator", 5) then return end
		if version ~= characterGeneration or player.Character ~= character then return end
		local assets = {}
		for _, action in ipairs({Config.Mine, Config.Attack}) do
			for _, id in ipairs(action.animations) do
				if not tracks[id] then loadTrack(humanoid, id) end
				if animations[id] then table.insert(assets, animations[id]) end
			end
		end
		local ok, err = pcall(function() ContentProvider:PreloadAsync(assets) end)
		if not ok then warn("ActionRuntime: animation preload failed", err) end
	end)
end

function Runtime.PlaySwing(actionName: string, tool: Tool, onContact: (string, Model, BasePart, number) -> ()): boolean
	local character = player.Character
	if not Runtime.IsValid(tool, character) then return false end
	local config = Config[actionName]
	local id = config.animations[math.random(1, #config.animations)]
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local track = tracks[id] or loadTrack(humanoid, id)
	local version, floor = generation, Runtime.GetFloor()
	local actionId = HttpService:GenerateGUID(false)
	local state = { track = track }
	active[state] = true
	local function contact(): ()
		if not active[state] then return end
		active[state] = nil
		if state.connection then state.connection:Disconnect() end
		local root = character:FindFirstChild("HumanoidRootPart")
		if version ~= generation or floor ~= Runtime.GetFloor() or not Runtime.IsValid(tool, character)
			or not root or not root:IsA("BasePart") then return end
		local ok, err = xpcall(function() onContact(actionId, character, root, floor) end, debug.traceback)
		if not ok then warn("ActionRuntime: contact failed", err) end
	end
	if actionName == "Attack" then Effects.PlaySound(Config.swingSounds) end
	if track then
		state.connection = track:GetMarkerReachedSignal("Impact"):Connect(contact)
		track:Play()
	end
	-- Metadata is fetched off the input path. Known markers own contact timing;
	-- a later watchdog still releases the action if playback fails to reach one.
	local markerTime = track and track.Length > 0 and markerTimes[id] or nil
	task.delay(if markerTime then math.max(markerTime + 0.15, config.contactDelay) else config.contactDelay, contact)
	return true
end

function Runtime.Initialize(): ()
	if initialized then return end
	initialized = true
	Effects.Initialize()
	player.CharacterAdded:Connect(prepareCharacter)
	player.CharacterRemoving:Connect(function() characterGeneration += 1 Runtime.Cancel() end)
	if player.Character then prepareCharacter(player.Character) end
	player:GetAttributeChangedSignal("TeleportProtected"):Connect(function()
		if player:GetAttribute("TeleportProtected") then Runtime.Cancel() end
	end)
	UserInputService.WindowFocusReleased:Connect(function() focused = false Runtime.Cancel() end)
	UserInputService.WindowFocused:Connect(function() focused = true end)
	task.spawn(function()
		local state = HotbarService.GetState()
		local selection = tostring(state.selectedSlot) .. ":" .. (state.slots[state.selectedSlot] or "")
		HotbarService.OnChanged(function(nextState: any)
			local nextSelection = tostring(nextState.selectedSlot) .. ":" .. (nextState.slots[nextState.selectedSlot] or "")
			if selection ~= nextSelection then selection = nextSelection Runtime.Cancel() end
		end)
		local data = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(player.Name)
		data:WaitForChild("CurrentFloor").Changed:Connect(Runtime.Cancel)
	end)
	for _, action in ipairs({Config.Mine, Config.Attack}) do
		for _, id in ipairs(action.animations) do
			task.spawn(function()
				local ok, sequence = pcall(function()
					return KeyframeSequenceProvider:GetKeyframeSequenceAsync("rbxassetid://" .. id)
				end)
				if not ok then return end -- Restricted assets use the configured contact delay.
				for _, keyframe in ipairs(sequence:GetKeyframes()) do
					for _, marker in ipairs(keyframe:GetMarkers()) do
						if marker.Name == "Impact" then
							markerTimes[id] = math.min(markerTimes[id] or math.huge, keyframe.Time)
						end
					end
				end
				sequence:Destroy()
			end)
		end
	end
end

return Runtime
