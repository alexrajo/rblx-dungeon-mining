local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local SelectableItemTile = require(ModuleIndex.SelectableItemTile)
local ItemCounter = require(ModuleIndex.ItemCounter)

local GearGridView = Roact.Component:extend("GearGridView")

function GearGridView:init()
	self.scrollRef = Roact.createRef()
	self.cellRefs = {}
end

function GearGridView:_getCellRef(entryId: string)
	if self.cellRefs[entryId] == nil then
		self.cellRefs[entryId] = Roact.createRef()
	end

	return self.cellRefs[entryId]
end

function GearGridView:_reportSelectedCellLayout()
	local onSelectedCellLayoutChanged = self.props.onSelectedCellLayoutChanged
	if onSelectedCellLayoutChanged == nil then
		return
	end

	local selectedEntryId = self.props.selectedEntryId
	if type(selectedEntryId) ~= "string" or selectedEntryId == "" then
		onSelectedCellLayoutChanged(nil)
		return
	end

	local selectedCellRef = self.cellRefs[selectedEntryId]
	local selectedCell = selectedCellRef and selectedCellRef:getValue()
	if selectedCell == nil then
		return
	end

	onSelectedCellLayoutChanged({
		entryId = selectedEntryId,
		absolutePosition = selectedCell.AbsolutePosition,
		absoluteSize = selectedCell.AbsoluteSize,
	})
end

function GearGridView:didMount()
	self:_reportSelectedCellLayout()
end

function GearGridView:didUpdate()
	self:_reportSelectedCellLayout()
end

function GearGridView:render()
	local itemsPerRow = self.props.itemsPerRow or 6
	local paddingPixels = self.props.paddingPixels or 4
	local gearEntries = self.props.gearEntries or {}
	local interactive = self.props.interactive == true
	local selectedEntryId = self.props.selectedEntryId
	local itemElements = {}

	for _, gearEntry in ipairs(gearEntries) do
		local elementKey = gearEntry.id or gearEntry.name
		local cellRef = self:_getCellRef(elementKey)

		if interactive then
			itemElements[elementKey] = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Roact.Ref] = cellRef,
			}, {
				Cell = createElement(SelectableItemTile, {
					itemName = gearEntry.name,
					amount = gearEntry.amount,
					Size = UDim2.fromScale(1, 1),
					selected = selectedEntryId == elementKey,
					onSelect = function()
						if self.props.onItemSelected then
							self.props.onItemSelected(gearEntry)
						end
					end,
				}),
			})
		else
			itemElements[elementKey] = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Roact.Ref] = cellRef,
			}, {
				Content = createElement(ItemCounter, {
					name = gearEntry.name,
					amount = gearEntry.amount,
					Size = UDim2.fromScale(1, 1),
				}),
			})
		end
	end

	return createElement("ScrollingFrame", {
		Size = self.props.Size or UDim2.new(1, -20, 1, 0),
		AnchorPoint = self.props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = self.props.Position or UDim2.new(0.5, 0, 0.5, 0),
		LayoutOrder = self.props.LayoutOrder,
		BackgroundTransparency = 1,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = self.props.Visible,
		[Roact.Ref] = self.scrollRef,
		[Roact.Change.CanvasPosition] = function()
			if self.props.onScroll then
				self.props.onScroll()
			end
		end,
	}, {
		UIGridLayout = createElement("UIGridLayout", {
			CellSize = UDim2.new(1 / itemsPerRow, -math.ceil(paddingPixels * (itemsPerRow - 1) / itemsPerRow), 1, 0),
			CellPadding = UDim2.fromOffset(paddingPixels, paddingPixels),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, {
			UIAspectRatioConstraint = createElement("UIAspectRatioConstraint", {
				AspectRatio = 1,
				DominantAxis = Enum.DominantAxis.Width,
			}),
		}),
		Items = Roact.createFragment(itemElements),
	})
end

return GearGridView
