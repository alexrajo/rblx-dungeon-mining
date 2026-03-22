local plr = game.Players.LocalPlayer

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local localServices = ReplicatedStorage.local_services
local ActionFireService = require(localServices.ActionFireService)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Button = require(ModuleIndex.Button)
local TextLabel = require(ModuleIndex.TextLabel)
local ActionButton = require(ModuleIndex.ActionButton)

local ScreenContext = require(ModuleIndex.ScreenContext)

local ControlsOverlay = Roact.Component:extend("ControlsOverlay")

local inputConnection = nil

local mineAction = nil
local attackAction = nil

function ControlsOverlay:activateMine()
	if self.state.mineReady == false then return end
	if mineAction == nil then
		mineAction = ActionFireService.GetAction("Mine")
	end
	if mineAction == nil then return end

	self:setState({ mineReady = false })
	local cooldownTime = mineAction:Invoke()
	if cooldownTime == nil then cooldownTime = 0 end
	task.delay(cooldownTime, function()
		self:setState({ mineReady = true })
	end)
end

function ControlsOverlay:activateAttack()
	if self.state.attackReady == false then return end
	if attackAction == nil then
		attackAction = ActionFireService.GetAction("Attack")
	end
	if attackAction == nil then return end

	self:setState({ attackReady = false })
	local cooldownTime = attackAction:Invoke()
	if cooldownTime == nil then cooldownTime = 0 end
	task.delay(cooldownTime, function()
		self:setState({ attackReady = true })
	end)
end

function ControlsOverlay:init()
	self:setState({
		mineReady = true,
		attackReady = true,
	})
end

function ControlsOverlay:didMount()
	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
			self:activateMine()
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonY then
			self:activateAttack()
		end
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
	local buttonSize = "xl"
	if isAtleast("md") then
		buttonSize = "2xl"
	end

	return createElement("Frame", {Position = self.props.Position, Size = self.props.Size, BackgroundTransparency = 1}, {
		Mine = createElement(ActionButton, {
			color = self.state.mineReady and "green" or "gray",
			size = buttonSize,
			AnchorPoint = Vector2.new(0.5, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Position = isAtleast("md") and UDim2.new(0.8, 0, 0.6, 0) or UDim2.new(0.775, 0, 0.625, 0),
			onClick = function()
				self:activateMine()
			end,
			imageId = "ASSET_ID_HERE",
			text = (device == "computer" and "Mine (E)") or (device == "console" and "Mine (X)") or "Mine",
			textSize = 20
		}),
		Attack = createElement(ActionButton, {
			color = self.state.attackReady and "red" or "gray",
			size = "md",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = isAtleast("md") and UDim2.new(0.9, 0, 0.6, 0) or UDim2.new(0.9, 0, 0.5, 0),
			imageId = "ASSET_ID_HERE",
			text = (device == "computer" and "Attack (Q)") or (device == "console" and "Attack (Y)") or "Attack",
			onClick = function()
				self:activateAttack()
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
