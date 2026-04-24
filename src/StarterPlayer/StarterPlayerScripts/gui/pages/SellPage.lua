local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local APIService = require(Services.APIService)
local ItemLookupService = require(Services.ItemLookupService)

local configs = ReplicatedStorage.configs
local SellPriceConfig = require(configs.SellPriceConfig)
local HotbarConfig = require(configs.HotbarConfig)
local GearConfig = require(configs.GearConfig)
local ItemConfig = require(configs.ItemConfig)

local RF_SellItems = APIService.GetFunction("SellItems")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local PageWrapper = require(ModuleIndex.PageWrapper)
local Window = require(ModuleIndex.Window)
local Button = require(ModuleIndex.Button)
local TextButton = require(ModuleIndex.TextButton)
local TextLabel = require(ModuleIndex.TextLabel)
local Panel = require(ModuleIndex.Panel)
local SelectablePanel = require(ModuleIndex.SelectablePanel)
local SellConfirmationDialog = require(ModuleIndex.SellConfirmationDialog)

local StatsContext = require(ModuleIndex.StatsContext)

local COIN_ICON_ID = "11953783945"
local EQUIPPED_ARMOR_FIELDS = {
	"EquippedHelmet",
	"EquippedChestplate",
	"EquippedLeggings",
	"EquippedBoots",
}

local SellPage = Roact.Component:extend("SellPage")

local function buildEquippedEntryLookup(statsData): {[string]: boolean}
	local equippedEntries = {}

	for _, fieldName in ipairs(EQUIPPED_ARMOR_FIELDS) do
		local entryId = statsData[fieldName]
		if type(entryId) == "string" and entryId ~= "" then
			equippedEntries[entryId] = true
		end
	end

	for _, entryId in ipairs(HotbarConfig.NormalizeStoredSlots(statsData.HotbarSlots or {})) do
		local itemName = HotbarConfig.ResolveEntryItemName(entryId, statsData)
		local slotName = GearConfig.GetSlotForItem(itemName)
		if slotName == "Pickaxe" or slotName == "Weapon" then
			equippedEntries[entryId] = true
		end
	end

	return equippedEntries
end

function SellPage:init()
	self:setState({
		selectedEntryId = nil,
		sellQuantity = 1,
		showConfirmDialog = false,
	})
end

function SellPage:_renderItemCell(cellData, isSelected: boolean, isEquipped: boolean)
	local itemName = cellData.name
	local ownedAmount = cellData.owned
	local itemConfig = ItemLookupService.GetItemDefinitionFromName(itemName) or {}
	local imageId = itemConfig.imageId or ItemConfig.DEFAULT_IMAGE_ID
	local price = SellPriceConfig[itemName]

	return createElement(SelectablePanel, {
		selected = isSelected,
		aspectRatio = 1,
		dominantAxis = Enum.DominantAxis.Width,
		onSelect = function()
			self:setState({
				selectedEntryId = cellData.id,
				sellQuantity = 1,
			})
		end,
	}, {
		Icon = createElement("ImageLabel", {
			Image = "rbxassetid://" .. imageId,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.02),
			Size = UDim2.fromScale(0.6, 0.6),
			BackgroundTransparency = 1,
			ImageColor3 = isEquipped and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
		}),
		QuantityLabel = ownedAmount ~= nil and createElement(TextLabel, {
			Text = tostring(ownedAmount),
			Size = UDim2.fromScale(0.9, 0.2),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.72),
			ZIndex = 3,
		}) or nil,
		PriceRow = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.9, 0.2),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.95),
			ZIndex = 3,
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 2),
			}),
			CoinIcon = createElement("ImageLabel", {
				Image = "rbxassetid://" .. COIN_ICON_ID,
				Size = UDim2.fromOffset(12, 12),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
			}),
			PriceLabel = createElement(TextLabel, {
				Text = tostring(price),
				Size = UDim2.fromOffset(30, 14),
				LayoutOrder = 2,
			}),
		}),
		EquippedOverlay = isEquipped and createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.45,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
		}, {
			UICorner = createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			EquippedLabel = createElement(TextLabel, {
				Text = "EQUIPPED",
				Size = UDim2.new(0.92, 0, 0.22, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				textSize = 13,
				ZIndex = 6,
			}),
		}),
	})
end

function SellPage:_renderContent(statsData)
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()

	local function onExit()
		closeAllPages()
	end

	local inventory = statsData.Inventory or {}
	local selectedEntryId = self.state.selectedEntryId
	local sellQuantity = self.state.sellQuantity
	local equippedEntries = buildEquippedEntryLookup(statsData)

	local sellableItems = {}
	for _, entry in ipairs(inventory) do
		local itemName = entry.name
		if SellPriceConfig[itemName] == nil then
			continue
		end

		local itemData = GearConfig.GetItemData(itemName)
		local isInstanceItem = itemData ~= nil and not GearConfig.IsStackable(itemName)
		if isInstanceItem then
			if type(entry.id) == "string" and entry.id ~= "" then
				table.insert(sellableItems, {
					id = entry.id,
					name = itemName,
					owned = nil,
					isInstanceItem = true,
				})
			end
		elseif type(entry.value) == "number" and entry.value > 0 then
			table.insert(sellableItems, {
				id = "stack:" .. itemName,
				name = itemName,
				owned = entry.value,
				isInstanceItem = false,
			})
		end
	end

	table.sort(sellableItems, function(a, b)
		if a.name == b.name then
			return a.id < b.id
		end
		return a.name < b.name
	end)

	-- Clamp sell quantity
	local selectedCell = nil
	for _, itemData in ipairs(sellableItems) do
		if itemData.id == selectedEntryId then
			selectedCell = itemData
			break
		end
	end

	local selectedItem = selectedCell and selectedCell.name or nil
	local selectedIsInstanceItem = selectedCell ~= nil and selectedCell.isInstanceItem == true
	local selectedOwned = 0
	local selectedPrice = 0
	local selectedIsEquipped = false
	if selectedCell ~= nil then
		selectedOwned = selectedIsInstanceItem and 1 or (selectedCell.owned or 0)
		selectedPrice = SellPriceConfig[selectedItem] or 0
		selectedIsEquipped = equippedEntries[selectedCell.id] == true
		if selectedOwned <= 0 then
			selectedItem = nil
			selectedCell = nil
			selectedIsEquipped = false
		elseif selectedIsInstanceItem then
			sellQuantity = 1
		elseif sellQuantity > selectedOwned then
			sellQuantity = selectedOwned
		end
	end

	local totalValue = selectedPrice * sellQuantity

	-- Build grid cells
	local itemsPerRow = 6
	local paddingPixels = 4
	local gridChildren = {}
	for _, itemData in ipairs(sellableItems) do
		gridChildren[itemData.id] = self:_renderItemCell(
			itemData,
			selectedEntryId == itemData.id,
			equippedEntries[itemData.id] == true
		)
	end

	-- Build detail panel content
	local detailChildren = {}
	if selectedItem and selectedOwned > 0 then
		local itemConfig = ItemLookupService.GetItemDefinitionFromName(selectedItem) or {}
		local imageId = itemConfig.imageId or ItemConfig.DEFAULT_IMAGE_ID

		detailChildren.ItemName = createElement(TextLabel, {
			Text = selectedItem,
			Size = UDim2.new(0.9, 0, 0, 22),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.02),
			textSize = 18,
		})

		detailChildren.ItemIcon = createElement("ImageLabel", {
			Image = "rbxassetid://" .. imageId,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.12),
			Size = UDim2.fromScale(0.4, 0.25),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
		})

		detailChildren.PricePerUnit = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.9, 0, 0, 20),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.40),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
			Label = createElement(TextLabel, {
				Text = "Price: ",
				Size = UDim2.fromOffset(50, 20),
				LayoutOrder = 1,
			}),
			CoinIcon = createElement("ImageLabel", {
				Image = "rbxassetid://" .. COIN_ICON_ID,
				Size = UDim2.fromOffset(16, 16),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 2,
			}),
			PriceValue = createElement(TextLabel, {
				Text = tostring(selectedPrice),
				Size = UDim2.fromOffset(40, 20),
				LayoutOrder = 3,
			}),
		})

		-- Quantity selector
		detailChildren.QuantitySelector = not selectedIsInstanceItem and createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.9, 0, 0, 30),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.50),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
			}),
			MinusButton = createElement(Button, {
				color = "red",
				customSize = UDim2.fromOffset(30, 30),
				disableHoverScaleTween = true,
				disabled = selectedIsEquipped,
				onClick = function()
					local newQty = math.max(1, sellQuantity - 1)
					self:setState({ sellQuantity = newQty })
				end,
				LayoutOrder = 1,
			}, {
				Label = createElement(TextLabel, {
					Text = "-",
					Size = UDim2.fromScale(1, 1),
					textSize = 20,
					ZIndex = 2,
				}),
			}),
			QuantityDisplay = createElement(TextLabel, {
				Text = tostring(sellQuantity) .. " / " .. tostring(selectedOwned),
				Size = UDim2.fromOffset(80, 30),
				LayoutOrder = 2,
			}),
			PlusButton = createElement(Button, {
				color = "green",
				customSize = UDim2.fromOffset(30, 30),
				disableHoverScaleTween = true,
				disabled = selectedIsEquipped,
				onClick = function()
					local newQty = math.min(selectedOwned, sellQuantity + 1)
					self:setState({ sellQuantity = newQty })
				end,
				LayoutOrder = 3,
			}, {
				Label = createElement(TextLabel, {
					Text = "+",
					Size = UDim2.fromScale(1, 1),
					textSize = 20,
					ZIndex = 2,
				}),
			}),
		})

		-- Total value display
		detailChildren.TotalValue = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.9, 0, 0, 20),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.62),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
			Label = createElement(TextLabel, {
				Text = "Total: ",
				Size = UDim2.fromOffset(50, 20),
				LayoutOrder = 1,
			}),
			CoinIcon = createElement("ImageLabel", {
				Image = "rbxassetid://" .. COIN_ICON_ID,
				Size = UDim2.fromOffset(16, 16),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 2,
			}),
			TotalText = createElement(TextLabel, {
				Text = tostring(totalValue),
				Size = UDim2.fromOffset(60, 20),
				LayoutOrder = 3,
			}),
		})

		if selectedIsEquipped then
			detailChildren.EquippedNotice = createElement(TextLabel, {
				Text = "Currently equipped. Unequip this item before selling.",
				Size = UDim2.new(0.88, 0, 0, 42),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.72),
				textSize = 13,
				textProps = {
					TextWrapped = true,
				},
			})
		end

		-- Sell buttons
		detailChildren.ButtonRow = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.9, 0, 0, 40),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
			}),
			SellButton = createElement(TextButton, {
				text = "SELL",
				size = "xs",
				color = "yellow",
				LayoutOrder = 1,
				disabled = selectedIsEquipped or sellQuantity <= 0 or selectedOwned <= 0,
				onClick = function()
					if selectedCell and selectedItem and not selectedIsEquipped and sellQuantity > 0 then
						if selectedIsInstanceItem then
							RF_SellItems:InvokeServer({
								{ id = selectedCell.id },
							})
						else
							RF_SellItems:InvokeServer({
								{ name = selectedItem, quantity = sellQuantity },
							})
						end
						self:setState({ sellQuantity = 1 })
					end
				end,
			}),
			SellAllButton = not selectedIsInstanceItem and createElement(TextButton, {
				text = "SELL ALL",
				size = "xs",
				color = "green",
				LayoutOrder = 2,
				disabled = selectedIsEquipped or selectedOwned <= 0,
				onClick = function()
					if selectedItem and not selectedIsEquipped and selectedOwned > 0 then
						self:setState({ showConfirmDialog = true })
					end
				end,
			}) or nil,
		})
	end

	local showConfirmDialog = self.state.showConfirmDialog

	return createElement(PageWrapper, { isOpen = (currentPage == "Sell") }, {
		Window = createElement(Window, {
			title = "SELL",
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			onExit = onExit,
		}, {
			ConfirmDialog = createElement(SellConfirmationDialog, {
				visible = showConfirmDialog and not selectedIsInstanceItem and selectedItem ~= nil and not selectedIsEquipped and selectedOwned > 0,
				itemName = selectedItem or "",
				quantity = selectedOwned,
				totalValue = selectedPrice * selectedOwned,
				onConfirm = function()
					if selectedItem and not selectedIsInstanceItem and not selectedIsEquipped and selectedOwned > 0 then
						RF_SellItems:InvokeServer({
							{ name = selectedItem, quantity = selectedOwned },
						})
					end
					self:setState({ showConfirmDialog = false, sellQuantity = 1 })
				end,
				onCancel = function()
					self:setState({ showConfirmDialog = false })
				end,
			}),
			ItemsView = createElement("Frame", {
				Size = UDim2.new(0.6, -12, 1, -16),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				BackgroundTransparency = 1,
			}, {
				TitleLabel = createElement(TextLabel, {
					Text = "Your Items",
					Size = UDim2.new(1, 0, 0, 20),
					textSize = 20,
				}),
				Content = createElement("ScrollingFrame", {
					Size = UDim2.new(1, 0, 1, -20),
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 1,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 0,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
				}, {
					UIGridLayout = createElement("UIGridLayout", {
						CellSize = UDim2.new(1 / itemsPerRow, -math.ceil(paddingPixels * (itemsPerRow - 1) / itemsPerRow), 1, 0),
						CellPadding = UDim2.fromOffset(paddingPixels, paddingPixels),
					}, {
						UIAspectRatioConstraint = createElement("UIAspectRatioConstraint", {
							AspectRatio = 1,
							DominantAxis = Enum.DominantAxis.Width,
						}),
					}),
					Items = Roact.createFragment(gridChildren),
				}),
			}),
			DetailView = createElement("Frame", {
				Size = UDim2.new(0.4, -12, 1, -16),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
			}, {
				UICorner = createElement("UICorner"),
				EmptyLabel = (not selectedItem or selectedOwned <= 0) and createElement(TextLabel, {
					Text = "Select an item to sell",
					Size = UDim2.fromScale(0.8, 0.2),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				}),
				Details = Roact.createFragment(detailChildren),
			}),
		}),
	})
end

function SellPage:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			return self:_renderContent(data)
		end,
	})
end

return SellPage
