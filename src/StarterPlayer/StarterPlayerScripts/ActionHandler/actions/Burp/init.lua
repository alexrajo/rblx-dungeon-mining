local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local TweenService = game:GetService("TweenService")

local effects = ReplicatedStorage.effects
local burpEffects = effects.burp
local animation = burpEffects.Animation

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)
local StatRetrieval = require(utils.StatRetrieval)
local CameraShake = require(utils.CameraShake)
local VisualizeBurp = require(utils.VisualizeBurp)

local HitDetection = require(script.HitDetection)

local getPlayerStat = StatRetrieval.GetPlayerStat

local globalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))
local DETECTION_RAY_DENSITY = globalConfig.BURP_DETECTION_RAY_DENSITY

local CLOUD_MULTI = 3
local BURP_DURATION = 2
local USE_CAMERA_DIRECTION = false

local burpAnimationTrack: AnimationTrack

local BurpAction = {}

--[[
	Function to be called to activate the action
]]
function BurpAction.Activate()
	local burpCharge = StatRetrieval.GetPlayerStat("BurpCharge", plr)
	if burpCharge == nil or burpCharge <= 0 then return 0.5 end
	
	local character = plr.Character
	if character == nil or character.Parent == nil then return 0.5 end
	local head: BasePart = character:FindFirstChild("Head")
	local humanoidRootPart: BasePart = character:FindFirstChild("HumanoidRootPart")
	local ownHumanoid = character:FindFirstChild("Humanoid")
	if head == nil or humanoidRootPart == nil or ownHumanoid == nil or ownHumanoid.Health <= 0 then return 0.5 end
	
	local level = getPlayerStat("Level", plr)
	local burpDistance = StatCalculation.GetBurpDistance(level, burpCharge)
	local burpForce = StatCalculation.GetBurpForce(level, burpCharge)
	local burpPower = StatCalculation.GetBurpPower(level, burpCharge)
	
	-- Effects
	if burpCharge >= 5 then
		CameraShake.Apply(ownHumanoid, math.min(0.2*burpForce/300, 1), 10, 1, 0, 0.5)
	end
	
	VisualizeBurp.Visualize(character, level, burpCharge)
	
	if burpAnimationTrack == nil and ownHumanoid then
		local humanoidAnimator = ownHumanoid:WaitForChild("Animator")
		if humanoidAnimator then
			burpAnimationTrack = humanoidAnimator:LoadAnimation(animation)
		end
	end
	
	if burpAnimationTrack then
		burpAnimationTrack:Play()
	end
	
	-- Hit detection
	local hitInformation = HitDetection.detectHitsWithRays(cam, character, burpDistance, burpPower)
	
	local func = APIService.GetFunction("Burp")
	return func:InvokeServer(hitInformation) -- Returns cooldown time
end

return BurpAction
