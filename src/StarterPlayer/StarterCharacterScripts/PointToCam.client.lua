local plr = game.Players.LocalPlayer
local cam = game.Workspace.CurrentCamera
--local pointEvent = game.ReplicatedStorage.Remotes:WaitForChild("PointCharacter")
local UpdateSpeed = 0.5
local BodyVertFactor = 0.8
local BodyHorFactor = 1.7

local Ang = CFrame.Angles
local aSin = math.asin
local aTan = math.atan

local Trso = plr.Character:WaitForChild("UpperTorso")
local Head = plr.Character:WaitForChild("Head")
local waist = Trso:WaitForChild("Waist")
local WaistOrgnC0 = waist.C0

local count = 0
local debounce = 1.3

local oldC0Target = 0

local tweenService = game:GetService("TweenService")

--[[
pointEvent.OnClientEvent:Connect(function(waistToUpdate, waistC0)
	if waistToUpdate == waist then return end
	local goal = {}
	goal.C0 = waistC0
	
	local info = TweenInfo.new(UpdateSpeed/2, Enum.EasingStyle.Linear)
	local tween = tweenService:Create(waistToUpdate, info, goal)
	tween:Play()
end)
]]

game:GetService("RunService").Heartbeat:Connect(function(dt)
	local TrsoLV = Trso.CFrame.lookVector
	local HdPos = Head.CFrame.p
	local CamCF = cam.CoordinateFrame
	local Dist = (Head.CFrame.p-CamCF.p).magnitude
	local Diff = Head.CFrame.Y-CamCF.Y
	if math.abs(Diff) < 1 then
		waist.C0 = WaistOrgnC0
		return
	end
	local currentC0Target = WaistOrgnC0*Ang((aSin(Diff/Dist)*BodyVertFactor), -(((HdPos-CamCF.p).Unit):Cross(TrsoLV)).Y*BodyHorFactor, 0)
	waist.C0 = waist.C0:lerp(currentC0Target, UpdateSpeed/2)
	
	if count < debounce then
		count = count + dt
	else
		count = 0
		if oldC0Target ~= currentC0Target then
			--pointEvent:FireServer(currentC0Target)
			oldC0Target = currentC0Target
		end
	end	
end)