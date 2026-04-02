local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local StatsContext = require(ModuleIndex.StatsContext)
local GearGridView = require(script.Parent.GearGridView)
local GearDetailPopup = require(script.Parent.GearDetailPopup)
local GearDetailUtils = require(script.Parent.GearDetailUtils)
local GearUtils = require(script.Parent.GearUtils)

local GearView = Roact.Component:extend("GearView")

local POPUP_SIZE = Vector2.new(260, 200)
local POPUP_MARGIN = 8

function GearView:init()
	self.rootRef = Roact.createRef()

	self:setState({
		selectedItemName = nil,
		popupAnchor = nil,
	})
end

function GearView:closePopup()
	if self.state.selectedItemName == nil and self.state.popupAnchor == nil then
		return
	end

	self:setState({
		selectedItemName = Roact.None,
		popupAnchor = Roact.None,
	})
end

function GearView:updatePopupPosition(cellLayout)
	if cellLayout == nil then
		if self.state.popupAnchor ~= nil then
			self:setState({
				popupAnchor = Roact.None,
			})
		end

		return
	end

	local root = self.rootRef:getValue()
	if root == nil then
		return
	end

	local localCenterX = cellLayout.absolutePosition.X - root.AbsolutePosition.X + cellLayout.absoluteSize.X / 2
	local localY = cellLayout.absolutePosition.Y - root.AbsolutePosition.Y + cellLayout.absoluteSize.Y + POPUP_MARGIN
	local minX = POPUP_SIZE.X / 2
	local maxX = math.max(minX, root.AbsoluteSize.X - POPUP_SIZE.X / 2)
	local maxY = math.max(POPUP_MARGIN, root.AbsoluteSize.Y - POPUP_SIZE.Y)
	local nextAnchor = {
		x = math.clamp(localCenterX, minX, maxX),
		y = math.clamp(localY, POPUP_MARGIN, maxY),
	}
	local currentAnchor = self.state.popupAnchor

	if currentAnchor ~= nil and currentAnchor.x == nextAnchor.x and currentAnchor.y == nextAnchor.y then
		return
	end

	self:setState({
		popupAnchor = nextAnchor,
	})
end

function GearView:didUpdate(prevProps)
	if prevProps.Visible and not self.props.Visible then
		self:closePopup()
	end
end

function GearView:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local gearEntries = GearUtils.GetOwnedGearEntries(data)
			local popupDetails = nil
			if self.state.selectedItemName ~= nil then
				popupDetails = GearDetailUtils.GetPopupDetails(self.state.selectedItemName, data)
			end

			return createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Visible = self.props.Visible,
				[Roact.Ref] = self.rootRef,
			}, {
				GearGrid = createElement(GearGridView, {
					Visible = self.props.Visible,
					gearEntries = gearEntries,
					itemsPerRow = 8,
					interactive = true,
					selectedItemName = self.state.selectedItemName,
					onItemSelected = function(itemName)
						self:setState({
							selectedItemName = itemName,
							popupAnchor = Roact.None,
						})
					end,
					onSelectedCellLayoutChanged = function(cellLayout)
						self:updatePopupPosition(cellLayout)
					end,
					onScroll = function()
						self:closePopup()
					end,
				}),
				Popup = popupDetails ~= nil and self.state.popupAnchor ~= nil and createElement(GearDetailPopup, {
					Position = UDim2.fromOffset(self.state.popupAnchor.x, self.state.popupAnchor.y),
					Size = UDim2.fromOffset(POPUP_SIZE.X, POPUP_SIZE.Y),
					details = popupDetails,
					ZIndex = 20,
					onClose = function()
						self:closePopup()
					end,
				}) or nil,
			})
		end,
	})
end

return GearView
