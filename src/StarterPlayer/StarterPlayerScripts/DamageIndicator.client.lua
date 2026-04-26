local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local APIService = require(ReplicatedStorage.services.APIService)

local RISE_START_Y = 1.5
local RISE_END_Y = 4.5
local X_SPREAD = 1.5
local NORMAL_DAMAGE_COLOR = Color3.fromRGB(255, 60, 60)
local CRITICAL_DAMAGE_COLOR = Color3.fromRGB(255, 215, 80)
local HIT_CONFIRM_SOUND_IDS = {
	140706011418118,
	128275263747292,
}

local function playHitConfirmSound()
	local soundId = HIT_CONFIRM_SOUND_IDS[math.random(1, #HIT_CONFIRM_SOUND_IDS)]
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	SoundService:PlayLocalSound(sound)

	task.spawn(function()
		sound.Ended:Wait()
		sound:Destroy()
	end)
end

local function spawnIndicator(enemyModel: Model, damage: number, isCritical: boolean)
	local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
	if hrp == nil then return end

	local startOffset = Vector3.new(math.random(-X_SPREAD * 10, X_SPREAD * 10) / 10, RISE_START_Y, 0)

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.AlwaysOnTop = true
	billboardGui.MaxDistance = 150
	billboardGui.Size = UDim2.new(0, 60, 0, 30)
	billboardGui.StudsOffset = startOffset
	billboardGui.LightInfluence = 0

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0.3
	uiScale.Parent = billboardGui

	local damageText = tostring(damage)

	local strokeLabel = Instance.new("TextLabel")
	strokeLabel.Text = damageText
	strokeLabel.Font = Enum.Font.LuckiestGuy
	strokeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	strokeLabel.TextScaled = true
	strokeLabel.BackgroundTransparency = 1
	strokeLabel.Size = UDim2.fromScale(1, 1)
	strokeLabel.AnchorPoint = Vector2.new(0.5, 0.45)
	strokeLabel.Position = UDim2.new(0.5, 0, 0.5, 3)
	strokeLabel.ZIndex = 1
	local strokeConstraint = Instance.new("UITextSizeConstraint")
	strokeConstraint.MinTextSize = 9
	strokeConstraint.MaxTextSize = 100
	strokeConstraint.Parent = strokeLabel
	strokeLabel.Parent = billboardGui

	local mainLabel = Instance.new("TextLabel")
	mainLabel.Text = damageText
	mainLabel.Font = Enum.Font.LuckiestGuy
	mainLabel.TextColor3 = isCritical and CRITICAL_DAMAGE_COLOR or NORMAL_DAMAGE_COLOR
	mainLabel.TextScaled = true
	mainLabel.BackgroundTransparency = 1
	mainLabel.Size = UDim2.fromScale(1, 1)
	mainLabel.AnchorPoint = Vector2.new(0.5, 0.45)
	mainLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainLabel.ZIndex = 2
	local mainConstraint = Instance.new("UITextSizeConstraint")
	mainConstraint.MinTextSize = 9
	mainConstraint.MaxTextSize = 100
	mainConstraint.Parent = mainLabel
	mainLabel.Parent = billboardGui

	billboardGui.Parent = hrp

	-- Pop in
	TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	-- Rise
	TweenService:Create(billboardGui, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(startOffset.X, RISE_END_Y, 0),
	}):Play()

	-- Fade out
	local fadeInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.4)
	local mainFade = TweenService:Create(mainLabel, fadeInfo, { TextTransparency = 1 })
	TweenService:Create(strokeLabel, fadeInfo, { TextTransparency = 1 }):Play()
	mainFade:Play()

	mainFade.Completed:Wait()
	if billboardGui.Parent ~= nil then
		billboardGui:Destroy()
	end
end

APIService.GetEvent("VisualizeAttackHit").OnClientEvent:Connect(function(hitData: {{enemy: Model, damage: number, isCritical: boolean?}})
	if #hitData > 0 then
		playHitConfirmSound()
	end

	for _, hit in ipairs(hitData) do
		task.spawn(spawnIndicator, hit.enemy, hit.damage, hit.isCritical == true)
	end
end)
