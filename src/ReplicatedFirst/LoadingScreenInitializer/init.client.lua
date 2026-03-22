local RunService = game:GetService("RunService")
local ReplicatedFirst = script.Parent
local LoadingScreen = script.LoadingScreen

if not RunService:IsStudio() then
	ReplicatedFirst:RemoveDefaultLoadingScreen()
	LoadingScreen.Parent = game.Players.LocalPlayer.PlayerGui
end