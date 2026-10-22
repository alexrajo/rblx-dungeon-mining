local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.configs.ActionConfig)
local Effects = {}
local shakes = {}
local breaks = {}
local activeSounds = {}
local initialized = false

local function emitter(position: Vector3): BasePart
	local part = Instance.new("Part")
	part.Name = "LocalActionEffect"
	part.Size = Vector3.one
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Position = position
	part.Parent = workspace
	Debris:AddItem(part, 10)
	return part
end

function Effects.PlaySound(ids: {number}, position: Vector3?): ()
	-- Play the actual instance: PlayLocalSound plays a copy whose Ended event
	-- cannot clean up the original. Both natural completion and failures expire.
	if #activeSounds >= 32 then
		local oldest = table.remove(activeSounds, 1)
		oldest:Destroy()
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. ids[math.random(1, #ids)]
	sound.RollOffMaxDistance = 80
	sound.Parent = if position then emitter(position) else SoundService
	table.insert(activeSounds, sound)
	local function cleanup(): ()
		local index = table.find(activeSounds, sound)
		if index then table.remove(activeSounds, index) end
		if sound.Parent then
			local parent = sound.Parent
			sound:Destroy()
			if parent ~= SoundService and parent.Parent then parent:Destroy() end
		end
	end
	sound.Ended:Once(cleanup)
	sound:Play()
	task.delay(10, cleanup)
end

function Effects.Shake(node: Instance): ()
	if not node:IsA("Model") and not node:IsA("BasePart") then return end
	local previous = shakes[node]
	local origin = if previous then previous.origin else if node:IsA("Model") then node:GetPivot() else node.CFrame
	local state = { origin = origin }
	shakes[node] = state
	task.spawn(function()
		for _ = 1, 3 do
			if shakes[node] ~= state then return end
			if not node:IsDescendantOf(workspace) then shakes[node] = nil return end
			local cf = origin * CFrame.new((math.random() * 2 - 1) * 0.15, 0, (math.random() * 2 - 1) * 0.15)
			if node:IsA("Model") then node:PivotTo(cf) else node.CFrame = cf end
			task.wait(0.045)
		end
		if shakes[node] == state then
			if node:IsDescendantOf(workspace) then
				if node:IsA("Model") then node:PivotTo(origin) else node.CFrame = origin end
			end
			shakes[node] = nil
		end
	end)
end

function Effects.Flash(target: Instance): ()
	local highlight = Instance.new("Highlight")
	highlight.Name = "LocalAttackImpact"
	highlight.Adornee = target
	highlight.FillColor = Color3.fromRGB(255, 240, 190)
	highlight.FillTransparency = 0.35
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = target
	TweenService:Create(highlight, TweenInfo.new(0.12), { FillTransparency = 1 }):Play()
	Debris:AddItem(highlight, 0.15)
end

function Effects.ForgetBreak(targetId: string): ()
	breaks[targetId] = nil
end

function Effects.Break(targetId: string, kind: string, position: Vector3): ()
	if breaks[targetId] then return end
	local stamp = os.clock()
	breaks[targetId] = stamp
	task.delay(30, function() if breaks[targetId] == stamp then breaks[targetId] = nil end end)
	Effects.PlaySound({Config.breakSounds[kind]}, position)
	local effects = ReplicatedStorage:FindFirstChild("effects")
	local breakFolder = effects and effects:FindFirstChild("break")
	local template = breakFolder and breakFolder:FindFirstChild("SmokeParticleEmitter")
	if template and template:IsA("ParticleEmitter") then
		local part = emitter(position)
		local attachment = Instance.new("Attachment")
		attachment.Parent = part
		local smoke = template:Clone()
		smoke.Enabled = false
		smoke.Parent = attachment
		smoke.Enabled = true
		smoke:Emit(12)
		task.delay(0.15, function() if smoke.Parent then smoke.Enabled = false end end)
		Debris:AddItem(part, 0.15 + smoke.Lifetime.Max + 0.25)
	end
end

function Effects.Reset(): ()
	for node, state in pairs(shakes) do
		if node:IsDescendantOf(workspace) then
			if node:IsA("Model") then node:PivotTo(state.origin) else node.CFrame = state.origin end
		end
	end
	table.clear(shakes)
end

function Effects.Initialize(): ()
	if initialized then return end
	initialized = true
	task.spawn(function()
		local assets = {}
		for _, ids in ipairs({Config.oreHitSounds, Config.swingSounds, Config.impactSounds,
			{Config.breakSounds.Ore, Config.breakSounds.Crate}}) do
			for _, id in ipairs(ids) do
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://" .. id
				table.insert(assets, sound)
			end
		end
		local effects = ReplicatedStorage:FindFirstChild("effects")
		local breakFolder = effects and effects:FindFirstChild("break")
		local smoke = breakFolder and breakFolder:FindFirstChild("SmokeParticleEmitter")
		if smoke then table.insert(assets, smoke:Clone()) end
		local ok, err = pcall(function() ContentProvider:PreloadAsync(assets) end)
		for _, asset in ipairs(assets) do asset:Destroy() end
		if not ok then warn("ActionEffects: preload failed", err) end
	end)
end

return Effects
