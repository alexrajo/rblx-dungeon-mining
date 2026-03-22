local SoundService = game:GetService("SoundService")
local SoundPlayer = {}

function SoundPlayer.PlaySound(soundId: number)
	local sound = Instance.new("Sound")
	sound.SoundId = "http://roblox.com/asset/?id="..soundId
	SoundService:PlayLocalSound(sound)
	sound.Ended:Wait()
	sound:Destroy()
end

return SoundPlayer
