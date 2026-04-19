local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local Roact = require(Services.Roact)

local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local equipGearEvent = APIService.GetEvent("EquipGear")
local assignHotbarSlotEvent = APIService.GetEvent("AssignHotbarSlot")
local clearHotbarSlotEvent = APIService.GetEvent("ClearHotbarSlot")
local clearEquippedGearEvent = APIService.GetEvent("ClearEquippedGear")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local StatsContext = require(ModuleIndex.StatsContext)
local GearGridView = require(script.Parent.GearGridView)
local GearDetailPopup = require(script.Parent.GearDetailPopup)
local GearDetailUtils = require(script.Parent.GearDetailUtils)
local GearUtils = require(script.Parent.GearUtils)
local LoadoutView = require(script.Parent.LoadoutView)

local GearView = Roact.Component:extend("GearView")

local POPUP_SIZE = Vector2.new(260, 236)
local POPUP_MARGIN = 8

function GearView:init()
	self.rootRef = Roact.createRef()

	self:setState({
		selectedEntryId = nil,
		selectedItemName = nil,
		popupAnchor = nil,
	})
end

function GearView:closePopup()
	if self.state.selectedEntryId == nil and self.state.selectedItemName == nil and self.state.popupAnchor == nil then
		return
	end

	self:setState({
		selectedEntryId = Roact.None,
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

function GearView:_isEntryVisibleInEntries(entryId: string?, gearEntries): boolean
	if type(entryId) ~= "string" or entryId == "" then
		return false
	end

	for _, gearEntry in ipairs(gearEntries) do
		if gearEntry.id == entryId then
			return true
		end
	end

	return false
end

function GearView:getFirstAvailableHotbarSlot(data): number?
	local hotbarSlots = HotbarConfig.NormalizeStoredSlots(data.HotbarSlots or {})
	for index = 1, HotbarConfig.MAX_SLOTS do
		if hotbarSlots[index] == "" then
			return index
		end
	end

	return nil
end

function GearView:getEquipActionState(itemName: string?, data)
	if type(itemName) ~= "string" or itemName == "" then
		return nil
	end

	local itemData = GearConfig.GetItemData(itemName)
	if itemData == nil then
		return nil
	end

	if HotbarConfig.IsEntryHotbarEligible(itemName) then
		local nextSlot = self:getFirstAvailableHotbarSlot(data)
		if nextSlot == nil then
			return {
				buttonText = "Equip",
				disabled = true,
				hintText = "All hotbar slots are full.",
			}
		end

		return {
			buttonText = "Equip",
			disabled = false,
			hintText = "Equips to hotbar slot " .. tostring(nextSlot) .. ".",
			slotIndex = nextSlot,
			mode = "hotbar",
		}
	end

	return {
		buttonText = "Equip",
		disabled = false,
		hintText = "Equips to your " .. string.lower(itemData.slot) .. " slot.",
		mode = "gear",
	}
end

function GearView:equipSelectedItem(data)
	local selectedEntryId = self.state.selectedEntryId
	local selectedItemName = self.state.selectedItemName
	local actionState = self:getEquipActionState(selectedItemName, data)
	if actionState == nil or actionState.disabled or type(selectedEntryId) ~= "string" then
		return
	end

	if actionState.mode == "hotbar" and actionState.slotIndex ~= nil then
		assignHotbarSlotEvent:FireServer(actionState.slotIndex, selectedEntryId)
	else
		equipGearEvent:FireServer(selectedEntryId)
	end

	self:closePopup()
end

function GearView:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local gearEntries = GearUtils.GetOwnedGearEntries(data)
			if self.state.selectedEntryId ~= nil and not self:_isEntryVisibleInEntries(self.state.selectedEntryId, gearEntries) then
				task.defer(function()
					if self.state.selectedEntryId ~= nil and not self:_isEntryVisibleInEntries(self.state.selectedEntryId, gearEntries) then
						self:closePopup()
					end
				end)
			end
			local popupDetails = nil
			local equipActionState = nil
			if self.state.selectedItemName ~= nil then
				popupDetails = GearDetailUtils.GetPopupDetails(self.state.selectedItemName, data)
				equipActionState = self:getEquipActionState(self.state.selectedItemName, data)
			end

			return createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Visible = self.props.Visible,
				[Roact.Ref] = self.rootRef,
			}, {
				Content = createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
				}, {
					GearGrid = createElement(GearGridView, {
						Visible = self.props.Visible,
						gearEntries = gearEntries,
						itemsPerRow = 5,
						interactive = true,
						selectedEntryId = self.state.selectedEntryId,
						Size = UDim2.new(0.66, -8, 1, 0),
						Position = UDim2.fromScale(0, 0),
						AnchorPoint = Vector2.zero,
						onItemSelected = function(gearEntry)
							self:setState({
								selectedEntryId = gearEntry.id,
								selectedItemName = gearEntry.name,
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
					Loadout = createElement(LoadoutView, {
						Visible = self.props.Visible,
						data = data,
						Size = UDim2.new(0.34, 0, 1, 0),
						Position = UDim2.fromScale(1, 0),
						AnchorPoint = Vector2.new(1, 0),
						onClearHotbarSlot = function(slotIndex)
							clearHotbarSlotEvent:FireServer(slotIndex)
						end,
						onClearArmorSlot = function(slotName)
							clearEquippedGearEvent:FireServer(slotName)
						end,
					}),
				}),
				Popup = popupDetails ~= nil and self.state.popupAnchor ~= nil and createElement(GearDetailPopup, {
					Position = UDim2.fromOffset(self.state.popupAnchor.x, self.state.popupAnchor.y),
					Size = UDim2.fromOffset(POPUP_SIZE.X, POPUP_SIZE.Y),
					details = popupDetails,
					ZIndex = 20,
					primaryButtonText = equipActionState and equipActionState.buttonText or nil,
					primaryButtonDisabled = equipActionState and equipActionState.disabled or false,
					actionHintText = equipActionState and equipActionState.hintText or nil,
					onPrimaryAction = equipActionState and function()
						self:equipSelectedItem(data)
					end or nil,
					onClose = function()
						self:closePopup()
					end,
				}) or nil,
			})
		end,
	})
end

return GearView
