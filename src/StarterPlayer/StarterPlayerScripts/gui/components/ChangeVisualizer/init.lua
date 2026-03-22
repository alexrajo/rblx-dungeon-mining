local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local TextButton = require(ModuleIndex.TextButton)
local ProgressBar = require(ModuleIndex.ProgressBar)
local ChangeIndicator = require(script.ChangeIndicator)

local StatRetrieval = require(ReplicatedStorage:WaitForChild("utils"):WaitForChild("StatRetrieval"))

local ChangeVisualizer = Roact.Component:extend("ChangeVisualizer")

local NOTIFICATION_DURATION = 3

function ChangeVisualizer:init()
	self.containerRef = Roact.createRef()
	self.state = {
		Coins = 0
	}
end

function ChangeVisualizer:manageCoinsUpdate(newVal)
	local prevCoins = self.state.Coins
	if newVal == prevCoins then return end

	local notification = {
		id = tick(),
		change = {
			Coins = newVal - prevCoins
		},
		xPosition = math.random(1, 100)/100
	}
	
	local container = self.containerRef:getValue()
	if container == nil then return end
	
	local handle = Roact.mount(createElement(ChangeIndicator, notification), container, tostring(notification.id))

	-- Schedule notification removal
	task.delay(NOTIFICATION_DURATION, function()
		Roact.unmount(handle)
	end)
	
	self:setState(function(state)
		return {
			Coins = newVal,
		}
	end)
end

function ChangeVisualizer:didMount()
	local coinStat = StatRetrieval.GetPlayerStatInstance("Coins", game.Players.LocalPlayer)
	self.connection = coinStat.Changed:Connect(function(newVal)
		self:manageCoinsUpdate(newVal)
	end)
	self:setState({
		Coins = coinStat.Value
	})
end

--[[
	@param Coins number
]]
function ChangeVisualizer:render()
	return createElement("Frame", {
		Size = UDim2.new(0.8, -32, 1, -32), 
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		BackgroundTransparency = 1,
		ZIndex = 10,
		[Roact.Ref] = self.containerRef
	})
end

function ChangeVisualizer:willUnmount()
	if self.connection then
		self.connection:disconnect()
	end
end

return ChangeVisualizer