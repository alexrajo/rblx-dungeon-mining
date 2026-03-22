local RunService = game:GetService("RunService")
local Camera = game.Workspace.CurrentCamera
local Speedlines = game.ReplicatedStorage:WaitForChild("Speedlines")

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local Speed = 20
local Rate = 1500
local Offset = 10

RunService.RenderStepped:Connect(function()
	local ViewportSize = Camera.ViewportSize
	local AspectRatio = ViewportSize.X / ViewportSize.Y

	if AspectRatio > 1.5 then
		Offset = 10
	else
		Offset = 13
	end

	Speedlines.CFrame = Camera.CFrame + Camera.CFrame.LookVector * (Offset / (Camera.FieldOfView / 70))
	Speedlines.Attachment.ParticleEmitter.Rate = (humanoid.WalkSpeed / Speed) * Rate
	Speedlines.Parent = Camera
end)
