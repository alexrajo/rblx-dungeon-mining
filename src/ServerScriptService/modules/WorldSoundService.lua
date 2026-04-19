local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local WorldSoundService = {}

local SOUND_CLEANUP_TIME = 10
local DEFAULT_VOLUME = 1
local DEFAULT_ROLL_OFF_MAX_DISTANCE = 80

function WorldSoundService.PlayOneShotAtPosition(soundId: string, position: Vector3): ()
	local emitter = Instance.new("Part")
	emitter.Name = "OneShotWorldSound"
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false
	emitter.Size = Vector3.new(1, 1, 1)
	emitter.Transparency = 1
	emitter.Position = position

	local sound = Instance.new("Sound")
	sound.Name = "OneShotSound"
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Volume = DEFAULT_VOLUME
	sound.RollOffMaxDistance = DEFAULT_ROLL_OFF_MAX_DISTANCE
	sound.Parent = emitter

	emitter.Parent = Workspace
	sound:Play()

	Debris:AddItem(emitter, SOUND_CLEANUP_TIME)
end

return WorldSoundService
