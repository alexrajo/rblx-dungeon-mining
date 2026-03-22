local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LOADING_TIME = 8

local ui = script.Parent.Parent
local container = script.Parent
local progressBar = container.ProgressBar
local fillBar = progressBar.Foreground.Bar
local fillPercentageTextFrame = container.ProgressBar.Text
local fillPercentageTextLabel = fillPercentageTextFrame.TextLabel
local fillPercentageTextLabelStroke = fillPercentageTextFrame.TextLabel_Stroke

fillBar.Size = UDim2.fromScale(0, 1)
fillPercentageTextLabel.Text = "0%"
fillPercentageTextLabelStroke.Text = "0%"

local t = 0
local connection

function update(dt)
	t += dt
	t = math.min(t, LOADING_TIME)

	local progress = t / LOADING_TIME
	local scaledProgress = math.clamp(math.sin(progress*math.pi/2), 0, 1)
	fillBar.Size = UDim2.fromScale(scaledProgress, 1)

	local percentageText = (math.floor(scaledProgress*100)).."%"
	fillPercentageTextLabel.Text = percentageText
	fillPercentageTextLabelStroke.Text = percentageText

	if scaledProgress >= 1 then
		connection:Disconnect()
		removeLoadingScreen()
	end
end

function removeLoadingScreen()
	task.wait(1)
	local tween = TweenService:Create(container, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0, -1)})
	tween:Play()
	task.wait(1.1)
	ui:Destroy()
end

connection = RunService.RenderStepped:Connect(update)

