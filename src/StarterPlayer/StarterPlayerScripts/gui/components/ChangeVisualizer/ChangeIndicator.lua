local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local gui = script.Parent.Parent.Parent
local ModuleIndex = require(gui.ModuleIndex)
local TextLabel = require(ModuleIndex.TextLabel)

local StatsContext = require(ModuleIndex.StatsContext)

local uiUtils = gui.utils
local Tweener = require(uiUtils.Tweener)

local ChangeIndicator = Roact.Component:extend("ChangeIndicator")

function ChangeIndicator:init()
	self.frameRef = Roact.createRef()
end

function ChangeIndicator:didMount()
	local frame = self.frameRef:getValue()
	if frame == nil then return end
	
	local movementTween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(self.props.xPosition, 0.5)
	})
	movementTween:Play()
	
	task.delay(2.3, function()
		local tweener = Tweener.New(frame, true)
		tweener:FadeOut(0.5)
	end)
end

function ChangeIndicator:render()
	local change = self.props.change
	local coinsChange = change.Coins
	
	return createElement("Frame", {
		Size = UDim2.new(0.05, 64, 0.05, 32), 
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(self.props.xPosition, 1),
		BackgroundTransparency = 1,
		[Roact.Ref] = self.frameRef
	}, {
		UIListLayout = createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 5)
		}),
		CoinsChange = createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1
		}, {
			AmountLabel = createElement(TextLabel, {
				Text = coinsChange > 0 and "+"..coinsChange or coinsChange,
				Size = UDim2.new(0.6, -5, 1, 0),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				textSize = 16,
				textProps = {
					TextXAlignment = Enum.TextXAlignment.Left
				}
			}),
			Icon = createElement("ImageLabel", {
				Image = "http://roblox.com/asset?id=11953783945",
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.new(0.4, 0, 1, 0)
			})
		})
	})
end

return ChangeIndicator