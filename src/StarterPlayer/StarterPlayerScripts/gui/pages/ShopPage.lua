local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local APIService = require(Services.APIService)
local ItemLookupService = require(Services.ItemLookupService)

local configs = ReplicatedStorage.configs
local ItemConfig = require(configs.ItemConfig)
local ShopConfig = require(configs.ShopConfig)

local RF_BuyItems = APIService.GetFunction("BuyItems")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Button = require(ModuleIndex.Button)
local PageWrapper = require(ModuleIndex.PageWrapper)
local SelectablePanel = require(ModuleIndex.SelectablePanel)
local TextButton = require(ModuleIndex.TextButton)
local TextLabel = require(ModuleIndex.TextLabel)
local ItemLevelRequirement = require(ModuleIndex.ItemLevelRequirement)
local Window = require(ModuleIndex.Window)

local StatsContext = require(ModuleIndex.StatsContext)
local ScreenContext = require(ModuleIndex.ScreenContext)
local GearDetailUtils = require(script.Parent.Parent.components.InventoryPage.GearDetailUtils)

local COIN_ICON_ID = "11953783945"
local DEFAULT_IMAGE_ID = ItemConfig.DEFAULT_IMAGE_ID

local ShopPage = Roact.Component:extend("ShopPage")

local function getItemImageId(itemName: string): string
	local itemDefinition = ItemLookupService.GetItemDefinitionFromName(itemName) or {}
	return itemDefinition.imageId or DEFAULT_IMAGE_ID
end

local function getShopItems(shopDef): {{name: string, price: number}}
	local shopItems = {}
	for itemName, price in pairs(shopDef.items) do
		table.insert(shopItems, {
			name = itemName,
			price = price,
		})
	end

	table.sort(shopItems, function(a, b)
		return a.name < b.name
	end)

	return shopItems
end

local function getEffectiveBuyQuantity(selectedPrice: number, requestedQuantity: number, coins: number): (number, number)
	if selectedPrice <= 0 then
		return 0, 0
	end

	local maxAffordable = math.floor(coins / selectedPrice)
	if maxAffordable <= 0 then
		return 0, 0
	end

	return math.clamp(requestedQuantity, 1, maxAffordable), maxAffordable
end

local function getGearStatComparison(itemName: string, statsData)
	return GearDetailUtils.GetPrimaryComparison(itemName, statsData)
end

function ShopPage:init()
	self:setState({
		selectedItem = nil,
		buyQuantity = 1,
	})
end

function ShopPage:didUpdate(previousProps)
	if previousProps.currentShopId ~= self.props.currentShopId then
		self:setState({
			selectedItem = nil,
			buyQuantity = 1,
		})
	end
end

function ShopPage:_renderItemCell(itemName: string, price: number, isSelected: boolean, playerLevel: number)
	return createElement(SelectablePanel, {
		selected = isSelected,
		aspectRatio = 1,
		dominantAxis = Enum.DominantAxis.Width,
		onSelect = function()
			self:setState({
				selectedItem = itemName,
				buyQuantity = 1,
			})
		end,
	}, {
		Requirement = createElement(ItemLevelRequirement, {
			itemName = itemName,
			playerLevel = playerLevel,
			badge = true,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -5, 0, 5),
		}),
		Icon = createElement("ImageLabel", {
			Image = "rbxassetid://" .. getItemImageId(itemName),
			ImageTransparency = ItemConfig.MeetsLevelRequirement(itemName, playerLevel) and 0 or 0.55,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.02),
			Size = UDim2.fromScale(0.6, 0.6),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
		}),
		NameLabel = createElement(TextLabel, {
			Text = itemName,
			Size = UDim2.fromScale(0.92, 0.22),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.74),
			ZIndex = 3,
			textSize = 12,
			textProps = {
				TextWrapped = true,
			},
		}),
		PriceRow = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.9, 0.18),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.96),
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
				Size = UDim2.fromOffset(36, 14),
				LayoutOrder = 2,
				textSize = 12,
			}),
		}),
	})
end

function ShopPage:_renderContent(statsData, screenData)
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()
	local shopId = self.props.currentShopId

	local function onExit()
		closeAllPages()
	end

	local shopDef = shopId and ShopConfig[shopId]
	if shopDef == nil then
		return createElement(PageWrapper, { isOpen = (currentPage == "Shop") }, {
			Window = createElement(Window, {
				title = "SHOP",
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				onExit = onExit,
			}, {
				EmptyLabel = createElement(TextLabel, {
					Text = "This shop is unavailable",
					Size = UDim2.fromScale(0.7, 0.15),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					textSize = 22,
				}),
			}),
		})
	end

	local coins = statsData.Coins or 0
	local shopItems = getShopItems(shopDef)

	local selectedItem = self.state.selectedItem
	local selectedPrice = selectedItem and shopDef.items[selectedItem] or nil
	if type(selectedPrice) ~= "number" then
		selectedItem = nil
		selectedPrice = 0
	end

	local effectiveBuyQuantity, maxAffordable = getEffectiveBuyQuantity(selectedPrice, self.state.buyQuantity, coins)
	local totalCost = selectedPrice * effectiveBuyQuantity
	local canAfford = effectiveBuyQuantity > 0 and totalCost <= coins

	local itemsPerRow = screenData.IsAtleast("md") and 6 or (screenData.IsAtleast("sm") and 4 or 3)
	local paddingPixels = 4

	local gridChildren = {}
	for _, itemData in ipairs(shopItems) do
		gridChildren[itemData.name] = self:_renderItemCell(itemData.name, itemData.price, selectedItem == itemData.name, statsData.Level or 1)
	end

	local detailChildren = {}
	local buyButton = nil
	if selectedItem ~= nil then
		local imageId = getItemImageId(selectedItem)
		local gearComparison = shopDef.type == "gear" and getGearStatComparison(selectedItem, statsData) or nil
		detailChildren.Requirement = createElement(ItemLevelRequirement, {
			itemName = selectedItem,
			playerLevel = statsData.Level or 1,
			showAcquisitionHint = true,
			Size = UDim2.new(1, -4, 0, 76),
			LayoutOrder = 3,
		})

		detailChildren.ItemName = createElement(TextLabel, {
			Text = selectedItem,
			Size = UDim2.new(1, -4, 0, 40),
			LayoutOrder = 1,
			textSize = 18,
			textProps = {
				TextWrapped = true,
				TextScaled = true,
			},
		})

		detailChildren.ItemIcon = createElement("ImageLabel", {
			Image = "rbxassetid://" .. imageId,
			Size = UDim2.new(1, -4, 0, 72),
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
		})

		if gearComparison ~= nil then
			detailChildren.StatComparison = createElement(TextLabel, {
				Text = gearComparison.statText,
				Size = UDim2.new(1, -4, 0, 20),
				LayoutOrder = 4,
				textSize = 16,
			})

			detailChildren.EquippedItem = createElement(TextLabel, {
				Text = gearComparison.equippedText,
				Size = UDim2.new(1, -4, 0, 32),
				LayoutOrder = 5,
				textSize = 13,
				textProps = {
					TextTransparency = 0.15,
					TextScaled = true,
					TextWrapped = true,
				},
			})
		end

		detailChildren.PricePerUnit = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 20),
			LayoutOrder = 6,
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
			Label = createElement(TextLabel, {
				Text = "Price:",
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
				Size = UDim2.fromOffset(44, 20),
				LayoutOrder = 3,
			}),
		})

		detailChildren.QuantitySelector = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 34),
			LayoutOrder = 7,
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
				disabled = effectiveBuyQuantity <= 1,
				onClick = function()
					self:setState({
						buyQuantity = math.max(1, effectiveBuyQuantity - 1),
					})
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
				Text = string.format("%d / %d", effectiveBuyQuantity, maxAffordable),
				Size = UDim2.fromOffset(88, 30),
				LayoutOrder = 2,
			}),
			PlusButton = createElement(Button, {
				color = "green",
				customSize = UDim2.fromOffset(30, 30),
				disableHoverScaleTween = true,
				disabled = effectiveBuyQuantity <= 0 or effectiveBuyQuantity >= maxAffordable,
				onClick = function()
					self:setState({
						buyQuantity = math.max(1, effectiveBuyQuantity + 1),
					})
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

		detailChildren.TotalCost = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 20),
			LayoutOrder = 8,
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
			Label = createElement(TextLabel, {
				Text = "Total:",
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
				Text = tostring(totalCost),
				Size = UDim2.fromOffset(60, 20),
				LayoutOrder = 3,
			}),
		})

		detailChildren.CoinStatus = createElement(TextLabel, {
			Text = string.format("Coins: %d", coins),
			Size = UDim2.new(1, -4, 0, 18),
			LayoutOrder = 9,
			textSize = 13,
			textProps = {
				TextTransparency = 0.15,
			},
		})

		buyButton = createElement(TextButton, {
			text = "BUY",
			AnchorPoint = Vector2.new(0.5, 0.5),
			size = "sm",
			Position = UDim2.new(0.5, 0, 1, -28),
			color = "green",
			disabled = not canAfford,
			onClick = function()
				if not canAfford then
					return
				end

				RF_BuyItems:InvokeServer(shopId, {
					{
						name = selectedItem,
						quantity = effectiveBuyQuantity,
					},
				})

				self:setState({
					buyQuantity = 1,
				})
			end,
		})
	end

	return createElement(PageWrapper, { isOpen = (currentPage == "Shop") }, {
		Window = createElement(Window, {
			title = shopDef.displayName,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			onExit = onExit,
		}, {
			ItemsView = createElement("Frame", {
				Size = UDim2.new(0.6, -12, 1, -16),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				BackgroundTransparency = 1,
			}, {
				TitleLabel = createElement(TextLabel, {
					Text = "Items",
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
				EmptyLabel = (selectedItem == nil) and createElement(TextLabel, {
					Text = "Select an item to purchase",
					Size = UDim2.fromScale(0.8, 0.2),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				}),
				BuyButton = buyButton,
				Details = createElement("ScrollingFrame", {
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(8, 8),
					Size = UDim2.new(1, -16, 1, -72),
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 3,
				}, {
					Layout = createElement("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 8),
					}),
					Content = Roact.createFragment(detailChildren),
				}),
			}),
		}),
	})
end

function ShopPage:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			return createElement(ScreenContext.context.Consumer, {
				render = function(screenData)
					return self:_renderContent(data, screenData)
				end,
			})
		end,
	})
end

return ShopPage
