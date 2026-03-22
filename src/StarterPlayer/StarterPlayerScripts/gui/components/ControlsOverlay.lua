local plr = game.Players.LocalPlayer

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local localServices = ReplicatedStorage.local_services
local ActionFireService = require(localServices.ActionFireService)
local burpAction = ActionFireService.GetAction("Burp")
local toggleAutoDrinkAction = ActionFireService.GetAction("ToggleAutoDrink")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Button = require(ModuleIndex.Button)
local TextLabel = require(ModuleIndex.TextLabel)
local ActionButton = require(ModuleIndex.ActionButton)

local ScreenContext = require(ModuleIndex.ScreenContext)

local localValues = plr:WaitForChild("LocalValues")
local isAutoDrinkingValue = localValues:WaitForChild("AutoDrink")

local ControlsOverlay = Roact.Component:extend("ControlsOverlay")

local inputConnection = nil

function ControlsOverlay:activateBurp(rbx)
	if self.state.burpReady == false then return end
	self:setState({
		burpReady = false
	})
	local cooldownTime = burpAction:Invoke()
	if cooldownTime == nil then cooldownTime = 0 end
	task.delay(cooldownTime, function()
		self:setState({
			burpReady = true
		})
	end)
end

function ControlsOverlay:toggleAutoDrink(rbx)
	toggleAutoDrinkAction:Invoke()
end

function ControlsOverlay:init()
	self:setState({
		burpReady = true,
		autoDrinkEnabled = false
	})
end

function ControlsOverlay:didMount()
	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonX then
			self:activateBurp()
		end
	end)
	isAutoDrinkingValue.Changed:Connect(function(enabled)
		self:setState({
			autoDrinkEnabled = enabled
		})
	end)
end

function ControlsOverlay:willUnmount()
	if inputConnection ~= nil then
		inputConnection:Disconnect()
		inputConnection = nil
	end
end

function ControlsOverlay:renderControls(screenData)
	local device = screenData.Device
	local isAtleast: (string) -> boolean = screenData.IsAtleast
	local burpButtonSize = "xl"
	if isAtleast("md") then
		burpButtonSize = "2xl"
	end
	
	return createElement("Frame", {Position = self.props.Position, Size = self.props.Size, BackgroundTransparency = 1}, {
		--[[Burp = createElement(Button, {
			color = self.state.burpReady and "green" or "gray",
			size = buttonSize,
			AnchorPoint = Vector2.new(0.5, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Position = isAtleast("lg") and UDim2.new(0.85, 0, 0.6, 0) or UDim2.new(0.8, 0, 0.6, 0),
			onClick = function(rbx)
				self:activateBurp(rbx)
			end,
		}, {
			InnerContainer = createElement("Frame", {Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1}, {
				ImageLabel = createElement("ImageLabel", {
					Position = UDim2.fromScale(0.5, 0), 
					AnchorPoint = Vector2.new(0.5, 0), 
					Size = UDim2.new(1, 0, 1, -50), 
					BackgroundTransparency = 1, 
					Image = "rbxassetid://5348474648", 
					ScaleType = Enum.ScaleType.Fit
				}),
				TextLabel = createElement(TextLabel, {
					Position = UDim2.fromScale(0.5, 1), 
					AnchorPoint = Vector2.new(0.5, 1), 
					Size = UDim2.new(1, 0, 0, 30), 
					Text = device == "computer" and "Burp (Q/E)" or "Burp", 
					textSize = 18
				})
			})
		}),]]
		Burp = createElement(ActionButton, {
			color = self.state.burpReady and "green" or "gray",
			size = burpButtonSize,
			AnchorPoint = Vector2.new(0.5, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Position = isAtleast("md") and UDim2.new(0.8, 0, 0.6, 0) or UDim2.new(0.775, 0, 0.625, 0),
			onClick = function(rbx)
				self:activateBurp(rbx)
			end,
			imageId = "5348474648",
			text = (device == "computer" and "Burp (Q/E)") or (device == "console" and "Burp (X)") or "Burp",
			textSize = 20
		}),
		AutoDrink = createElement(ActionButton, {
			color = self.state.autoDrinkEnabled and "green" or "red",
			size = "md",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = isAtleast("md") and UDim2.new(0.9, 0, 0.6, 0) or UDim2.new(0.9, 0, 0.5, 0),
			imageId = "111981235734121",
			text = "AUTO DRINK",
			onClick = function(rbx)
				self:toggleAutoDrink(rbx)
			end,
		})
	})
end

function ControlsOverlay:render()
	return createElement(ScreenContext.context.Consumer, {
		render = function (data)
			return self:renderControls(data)
		end
	})
end

return ControlsOverlay
