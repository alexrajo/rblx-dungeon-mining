local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)

local localServices = ReplicatedStorage:WaitForChild("local_services")
local HotbarActionService = require(localServices.HotbarActionService)
local HotbarService = require(localServices.HotbarService)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local ActionButton = require(ModuleIndex.ActionButton)
local ScreenContext = require(ModuleIndex.ScreenContext)
local StatsContext = require(ModuleIndex.StatsContext)

local ControlsOverlay = Roact.Component:extend("ControlsOverlay")

function ControlsOverlay:init()
	self:setState({
		actionReady = HotbarActionService.IsActionReady(),
		hotbar = HotbarService.GetState(),
	})
end

function ControlsOverlay:didMount()
	self.hotbarDisconnect = HotbarService.OnChanged(function(hotbarState)
		self:setState({ hotbar = hotbarState })
	end)

	self.actionReadyDisconnect = HotbarActionService.OnActionReadyChanged(function(isReady: boolean)
		self:setState({ actionReady = isReady })
	end)
end

function ControlsOverlay:willUnmount()
	HotbarActionService.StopHoldingMine()

	if self.hotbarDisconnect then
		self.hotbarDisconnect()
	end
	if self.actionReadyDisconnect then
		self.actionReadyDisconnect()
	end
end

function ControlsOverlay:renderMobile(screenData, statsData)
	local selectedSlot = self.state.hotbar.selectedSlot or 0
	if selectedSlot == 0 then
		return createElement("Frame", {
			Position = self.props.Position,
			Size = self.props.Size,
			BackgroundTransparency = 1,
		})
	end

	local slots = self.state.hotbar.slots or {}
	local entryId = slots[selectedSlot] or ""
	local itemName = HotbarConfig.ResolveEntryItemName(entryId, statsData)
	if itemName == "" then
		return createElement("Frame", {
			Position = self.props.Position,
			Size = self.props.Size,
			BackgroundTransparency = 1,
		})
	end

	local isAtleast: (string) -> boolean = screenData.IsAtleast
	local buttonSize = isAtleast("md") and "2xl" or "xl"
	local actionName = HotbarConfig.GetActionName(itemName)

	return createElement("Frame", {
		Position = self.props.Position,
		Size = self.props.Size,
		BackgroundTransparency = 1,
	}, {
		Action = createElement(ActionButton, {
			color = self.state.actionReady and HotbarConfig.ResolveActiveColor(itemName) or "gray",
			size = buttonSize,
			AnchorPoint = Vector2.new(0.5, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Position = isAtleast("md") and UDim2.new(0.86, 0, 0.58, 0) or UDim2.new(0.84, 0, 0.58, 0),
			imageId = HotbarConfig.GetImageId(itemName),
			text = itemName,
			textSize = 18,
			onClick = actionName ~= "Mine" and function()
				HotbarActionService.ActivateSelected()
			end or nil,
			onPressDown = actionName == "Mine" and function()
				HotbarActionService.StartHoldingMine()
			end or nil,
			onPressUp = actionName == "Mine" and function()
				HotbarActionService.StopHoldingMine()
			end or nil,
		}),
	})
end

function ControlsOverlay:render()
	return createElement(ScreenContext.context.Consumer, {
		render = function(screenData)
			if screenData.Device ~= "mobile" then
				return createElement("Frame", {
					Position = self.props.Position,
					Size = self.props.Size,
					BackgroundTransparency = 1,
				})
			end

			return createElement(StatsContext.context.Consumer, {
				render = function(statsData)
					return self:renderMobile(screenData, statsData)
				end,
			})
		end,
	})
end

return ControlsOverlay
