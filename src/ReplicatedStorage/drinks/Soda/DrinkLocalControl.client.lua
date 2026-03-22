local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local utils = ReplicatedStorage.utils
local StatRetrieval = require(utils.StatRetrieval)
local GlobalConfig = require(ReplicatedStorage.GlobalConfig)

local DRINK_INTERVAL = GlobalConfig.DRINK_INTERVAL

local player = game.Players.LocalPlayer
local burpStat = StatRetrieval.GetPlayerStatInstance("BurpPoints", player)
local localValues = player:WaitForChild("LocalValues")
local autoDrink = localValues:WaitForChild("AutoDrink")

local audio = script.Parent:WaitForChild("audio")
local openSound = audio:WaitForChild("OpenCan")
local drinkSound = audio:WaitForChild("Drink")

local animationController = script.Parent:WaitForChild("AnimationController")
local animator = animationController:WaitForChild("Animator")

local openAnimation = Instance.new("Animation")
openAnimation.AnimationId = "http://roblox.com/asset/?id=17317405807"
openAnimation.Name = "OpenAnim"
openAnimation.Parent = script

local drinkAnimation = Instance.new("Animation")
drinkAnimation.AnimationId = "http://roblox.com/asset/?id=108089721857463"
drinkAnimation.Name = "OpenAnim"
drinkAnimation.Parent = script

local openAnimationTrack = animator:LoadAnimation(openAnimation)

local character = player.Character
local humanoid: Humanoid, humanoidAnimator: Animator, drinkAnimationTrack: AnimationTrack
if character then
	humanoid = character:WaitForChild("Humanoid")
	if humanoid then
		humanoidAnimator = humanoid:WaitForChild("Animator")
		if humanoidAnimator then
			drinkAnimationTrack = humanoidAnimator:LoadAnimation(drinkAnimation)
		end
	end
end

local canDrink = true

function open()
	openSound:Play()
	openAnimationTrack:Play()
end

function drink()
	if not canDrink then return end
	
	canDrink = false
	
	if drinkAnimationTrack then
		if drinkAnimationTrack.IsPlaying then
			drinkAnimationTrack:Stop()
		end
		drinkAnimationTrack:Play()
	end
	burpStat.Value = burpStat.Value + 1
	local event = APIService.GetEvent("Drink")
	event:FireServer()
	
	if drinkSound then
		task.delay(0.2, function()
			drinkSound:Play()
		end)
	end
	
	task.delay(DRINK_INTERVAL, function()
		canDrink = true
	end)
end

script.Parent.Equipped:Connect(open)
script.Parent.Activated:Connect(drink)

while true do
	if not autoDrink then break end
	if autoDrink.Value then
		script.Parent.Parent = character
		drink()
	end
	task.wait(DRINK_INTERVAL)
end