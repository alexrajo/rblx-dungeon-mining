local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(ReplicatedStorage.services.Roact)
local ItemLookupService = require(Services.ItemLookupService)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local SelectableItemTile = require(ModuleIndex.SelectableItemTile)
local StatsContext = require(ModuleIndex.StatsContext)
local GearDetailPopup = require(script.Parent.GearDetailPopup)

local ResourcesView = Roact.Component:extend("ResourcesView")

local POPUP_SIZE = Vector2.new(260, 236)
local POPUP_MARGIN = 8

function ResourcesView:init()
	self.rootRef = Roact.createRef()
	self.cellRefs = {}

	self:setState({
		selectedItemName = nil,
		popupAnchor = nil,
	})
end

function ResourcesView:closePopup()
	if self.state.selectedItemName == nil and self.state.popupAnchor == nil then
		return
	end

	self:setState({
		selectedItemName = Roact.None,
		popupAnchor = Roact.None,
	})
end

function ResourcesView:_getCellRef(itemName: string)
	if self.cellRefs[itemName] == nil then
		self.cellRefs[itemName] = Roact.createRef()
	end

	return self.cellRefs[itemName]
end

function ResourcesView:_reportSelectedCellLayout()
	local selectedItemName = self.state.selectedItemName
	if type(selectedItemName) ~= "string" or selectedItemName == "" then
		return
	end

	local selectedCellRef = self.cellRefs[selectedItemName]
	local selectedCell = selectedCellRef and selectedCellRef:getValue()
	if selectedCell == nil then
		return
	end

	self:updatePopupPosition({
		absolutePosition = selectedCell.AbsolutePosition,
		absoluteSize = selectedCell.AbsoluteSize,
	})
end

function ResourcesView:updatePopupPosition(cellLayout)
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

function ResourcesView:didMount()
	self:_reportSelectedCellLayout()
end

function ResourcesView:didUpdate(prevProps)
	if prevProps.Visible and not self.props.Visible then
		self:closePopup()
	else
		self:_reportSelectedCellLayout()
	end
end

function ResourcesView:_isResourceVisible(resourceEntries, itemName: string?): boolean
	if type(itemName) ~= "string" or itemName == "" then
		return false
	end

	for _, resourceEntry in ipairs(resourceEntries) do
		if resourceEntry.name == itemName then
			return true
		end
	end

	return false
end

function ResourcesView:_getResourceDetails(itemName: string, amount: number)
	local itemDefinition = ItemLookupService.GetItemDefinitionFromName(itemName) or {}
	local detailLines = {}

	return {
		name = itemName,
		imageId = itemDefinition.imageId or ItemConfig.DEFAULT_IMAGE_ID,
		equippedText = "Owned: " .. tostring(amount),
		description = itemDefinition.description,
		detailLines = detailLines,
	}
end

function ResourcesView:render()
	local itemsPerRow = 8
	local paddingPixels = 4

	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local inventory = data.Inventory
			local resourceEntries = {}
			local itemElements = {}

			for _, item in ipairs(inventory) do
				local name = item.name
				local amount = item.value
				if type(amount) ~= "number" then continue end
				if amount <= 0 then continue end
				if GearConfig.GetItemData(name) ~= nil then continue end

				table.insert(resourceEntries, {
					name = name,
					amount = amount,
				})
			end

			if self.state.selectedItemName ~= nil and not self:_isResourceVisible(resourceEntries, self.state.selectedItemName) then
				task.defer(function()
					if self.state.selectedItemName ~= nil and not self:_isResourceVisible(resourceEntries, self.state.selectedItemName) then
						self:closePopup()
					end
				end)
			end

			local selectedAmount = nil
			for _, resourceEntry in ipairs(resourceEntries) do
				local name = resourceEntry.name
				local amount = resourceEntry.amount
				local cellRef = self:_getCellRef(name)

				if name == self.state.selectedItemName then
					selectedAmount = amount
				end

				itemElements[name] = createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					[Roact.Ref] = cellRef,
				}, {
					Cell = createElement(SelectableItemTile, {
						itemName = name,
						imageId = (ItemLookupService.GetItemDefinitionFromName(name) or {}).imageId,
						amount = amount,
						showName = false,
						Size = UDim2.fromScale(1, 1),
						selected = self.state.selectedItemName == name,
						onSelect = function()
							self:setState({
								selectedItemName = name,
								popupAnchor = Roact.None,
							})
						end,
					}),
				})
			end

			local popupDetails = nil
			if self.state.selectedItemName ~= nil and selectedAmount ~= nil then
				popupDetails = self:_getResourceDetails(self.state.selectedItemName, selectedAmount)
			end

			return createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Visible = self.props.Visible,
				[Roact.Ref] = self.rootRef,
			}, {
				Grid = createElement("ScrollingFrame", {
					Size = UDim2.new(1, -20, 1, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					BackgroundTransparency = 1,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 0,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					[Roact.Change.CanvasPosition] = function()
						self:closePopup()
					end,
				}, {
					UIGridLayout = createElement("UIGridLayout", {
						CellSize = UDim2.new(1/itemsPerRow, -math.ceil(paddingPixels*(itemsPerRow-1)/itemsPerRow), 1, 0),
						CellPadding = UDim2.fromOffset(paddingPixels, paddingPixels),
					}, {
						UIAspectRatioConstraint = createElement("UIAspectRatioConstraint", {
							AspectRatio = 1,
							DominantAxis = Enum.DominantAxis.Width
						})
					}),
					Items = Roact.createFragment(itemElements)
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
		end
	})
end

return ResourcesView
