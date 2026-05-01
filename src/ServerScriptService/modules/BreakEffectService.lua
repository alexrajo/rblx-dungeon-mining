local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BreakEffectService = {}

local SMOKE_EMIT_COUNT = 12
local SMOKE_ENABLE_TIME = 0.15
local SMOKE_CLEANUP_PADDING = 0.25

local warnedMissingSmokeEmitter = false

local function getSmokeParticleEmitter(): ParticleEmitter?
	local effectsFolder = ReplicatedStorage:FindFirstChild("effects")
	local breakEffectsFolder = if effectsFolder ~= nil then effectsFolder:FindFirstChild("break") else nil
	local smokeParticleEmitter = if breakEffectsFolder ~= nil then breakEffectsFolder:FindFirstChild("SmokeParticleEmitter") else nil

	if smokeParticleEmitter == nil then
		if not warnedMissingSmokeEmitter then
			warn("BreakEffectService: Missing ReplicatedStorage.effects.break.SmokeParticleEmitter")
			warnedMissingSmokeEmitter = true
		end
		return nil
	end

	if not smokeParticleEmitter:IsA("ParticleEmitter") then
		if not warnedMissingSmokeEmitter then
			warn("BreakEffectService: ReplicatedStorage.effects.break.SmokeParticleEmitter must be a ParticleEmitter")
			warnedMissingSmokeEmitter = true
		end
		return nil
	end

	return smokeParticleEmitter
end

function BreakEffectService.PlaySmokePuff(position: Vector3): ()
	local smokeParticleEmitter = getSmokeParticleEmitter()
	if smokeParticleEmitter == nil then
		return
	end

	local emitterPart = Instance.new("Part")
	emitterPart.Name = "BreakSmokeEmitter"
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	emitterPart.CanTouch = false
	emitterPart.Size = Vector3.new(1, 1, 1)
	emitterPart.Transparency = 1
	emitterPart.Position = position

	local attachment = Instance.new("Attachment")
	attachment.Name = "SmokeAttachment"
	attachment.Parent = emitterPart

	local smoke = smokeParticleEmitter:Clone()
	smoke.Enabled = false
	smoke.Parent = attachment

	emitterPart.Parent = Workspace
	smoke.Enabled = true
	smoke:Emit(SMOKE_EMIT_COUNT)

	task.delay(SMOKE_ENABLE_TIME, function()
		if smoke.Parent ~= nil then
			smoke.Enabled = false
		end
	end)

	local cleanupTime = SMOKE_ENABLE_TIME + smoke.Lifetime.Max + SMOKE_CLEANUP_PADDING
	Debris:AddItem(emitterPart, cleanupTime)
end

return BreakEffectService
