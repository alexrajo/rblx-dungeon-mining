local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local APIService = require(Services.APIService)
local CraftingRecipeService = require(Services.CraftingRecipeService)
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)

local RF_Craft = APIService.GetFunction("Craft")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local PageWrapper = require(ModuleIndex.PageWrapper)
local Window = require(ModuleIndex.Window)
local TextButton = require(ModuleIndex.TextButton)
local TextLabel = require(ModuleIndex.TextLabel)
local ItemCounter = require(ModuleIndex.ItemCounter)
local InventoryUtils = require(ModuleIndex.InventoryUtils)
local SelectableItemTile = require(ModuleIndex.SelectableItemTile)
local Tab = require(ModuleIndex.Tab)

local StatsContext = require(ModuleIndex.StatsContext)
local GearDetailUtils = require(script.Parent.Parent.components.InventoryPage.GearDetailUtils)

local CraftingPage = Roact.Component:extend("CraftingPage")

local allRecipes = CraftingRecipeService.GetAllRecipes()
local SECTION_PICKAXES = "Pickaxes"
local SECTION_WEAPONS = "Weapons"
local SECTION_ARMOR = "Armor"
local SECTION_OTHER = "Other"
local SECTION_NAMES = {SECTION_PICKAXES, SECTION_WEAPONS, SECTION_ARMOR, SECTION_OTHER}

local function isArmorSlot(slotName: string?): boolean
	return slotName == "Helmet"
		or slotName == "Chestplate"
		or slotName == "Leggings"
		or slotName == "Boots"
end

local function recipeBelongsToSection(recipe, sectionName: string): boolean
	local itemData = ItemConfig.GetItemData(recipe.name)
	if itemData == nil then
		return false
	end

	if sectionName == SECTION_PICKAXES then
		return itemData.slot == "Pickaxe"
	elseif sectionName == SECTION_WEAPONS then
		return itemData.slot == "Weapon"
	elseif sectionName == SECTION_ARMOR then
		return isArmorSlot(itemData.slot)
	elseif sectionName == SECTION_OTHER then
		return itemData.category == ItemConfig.CATEGORY_BOMB
			or itemData.category == ItemConfig.CATEGORY_CONSUMABLE
	end

	return false
end

local function getRecipesForSection(sectionName: string)
	local recipes = {}
	for _, recipe in ipairs(allRecipes) do
		if recipeBelongsToSection(recipe, sectionName) then
			table.insert(recipes, recipe)
		end
	end
	return recipes
end

local function findRecipeByName(recipes, recipeName: string?)
	if recipeName == nil then
		return nil
	end

	for _, recipe in ipairs(recipes) do
		if recipe.name == recipeName then
			return recipe
		end
	end

	return nil
end

function CraftingPage:init()
	self:setState({
		currentSection = SECTION_PICKAXES,
		selectedRecipeName = nil,
	})
end

function CraftingPage:_renderContent(statsData)
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()

	local function onExit()
		closeAllPages()
	end

	local itemsPerRow = 6
	local paddingPixels = 4

	local currentSection = self.state.currentSection
	local visibleRecipes = getRecipesForSection(currentSection)
	local selectedRecipeName = self.state.selectedRecipeName
	local selectedRecipe = findRecipeByName(visibleRecipes, selectedRecipeName)
	local selectedItemDetails = selectedRecipe and GearDetailUtils.GetPopupDetails(selectedRecipe.name, statsData) or nil
	local requiredIngredientComponents = {}

	local canCraft = true

	-- Helper to get owned amount
	local function getOwned(itemName)
		return InventoryUtils.GetInventoryCount(statsData, itemName)
	end

	if selectedRecipe ~= nil then
		for name, amount in pairs(selectedRecipe.ingredients) do
			local amountOwned = getOwned(name)

			if amountOwned < amount then
				canCraft = false
			end

			local component = createElement(ItemCounter, {name = name, amount = amount, amountOwned = amountOwned})
			table.insert(requiredIngredientComponents, component)
		end
	else
		canCraft = false
	end

	local tabComponents = {}
	for i, sectionName in ipairs(SECTION_NAMES) do
		tabComponents[sectionName] = createElement(Tab, {
			text = sectionName,
			selected = currentSection == sectionName,
			LayoutOrder = i,
			xSize = UDim.new(0.23, 0),
			onClick = function()
				self:setState({
					currentSection = sectionName,
					selectedRecipeName = nil,
				})
			end,
		})
	end

	local recipeComponents = {}
	for i, recipe in ipairs(visibleRecipes) do
		local imageId = ItemConfig.GetImageIdForItem(recipe.name)
		recipeComponents[recipe.name] = createElement(SelectableItemTile, {
			itemName = recipe.name,
			imageId = imageId,
			selected = recipe.name == selectedRecipeName,
			LayoutOrder = i,
			onSelect = function()
				self:setState({
					selectedRecipeName = recipe.name,
				})
			end,
		})
	end

	local itemStatComponents = {}
	if selectedItemDetails ~= nil then
		for index, lineText in ipairs(selectedItemDetails.detailLines or {}) do
			itemStatComponents["Stat" .. tostring(index)] = createElement(TextLabel, {
				Text = lineText,
				textSize = 13,
				Size = UDim2.new(1, 0, 0, 17),
				LayoutOrder = index,
				textProps = {
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
				},
			})
		end
	end

	return createElement(PageWrapper, {isOpen = (currentPage == "CraftingPage")}, {
		Tabs = createElement("Frame", {
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Size = UDim2.fromScale(0.6, 0.1),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0.15, 0),
		}, {
			UIListLayout = createElement("UIListLayout", {
				Padding = UDim.new(0, 5),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			TabComponents = Roact.createFragment(tabComponents),
		}),
		Window = createElement(Window, {title = "CRAFTING", Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), onExit = onExit}, {
			RecipesView = createElement("Frame", {
				Size = UDim2.new(0.6, -12, 1, -16),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				BackgroundTransparency = 1,
			}, {
				TitleLabel = createElement(TextLabel, {
					Text = "Recipes",
					Size = UDim2.new(1, 0, 0, 20),
					textSize = 20
				}),
				Content = createElement("ScrollingFrame", {
					Size = UDim2.new(1, 0, 1, -20),
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 1,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 0,
					AutomaticCanvasSize = Enum.AutomaticSize.Y
				}, {
					UIGridLayout = createElement("UIGridLayout", {
						CellSize = UDim2.new(1/itemsPerRow, -math.ceil(paddingPixels*(itemsPerRow-1)/itemsPerRow), 1, 0),
						CellPadding = UDim2.fromOffset(paddingPixels, paddingPixels),
					}, {
						UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
							AspectRatio = 1,
							DominantAxis = Enum.DominantAxis.Width
						})
					}),
					Items = Roact.createFragment(recipeComponents)
				})
			}),
			CraftView = createElement("Frame", {
				Size = UDim2.new(0.4, -12, 1, -16),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0
			}, {
				UICorner = createElement("UICorner"),
				ResultLabel = selectedRecipe and createElement(TextLabel, {
					Text = selectedRecipe.name,
					Size = UDim2.new(0.9, 0, 0, 25),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.02),
					textSize = 18
				}),
				EmptyLabel = (selectedRecipe == nil) and createElement(TextLabel, {
					Text = "Select a recipe",
					Size = UDim2.fromScale(0.8, 0.2),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.45),
					textSize = 18,
				}) or nil,
				Stats = selectedRecipe and createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.9, 0, 0.26, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.12),
				}, {
					Lines = createElement("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
					}, {
						UIListLayout = createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Vertical,
							HorizontalAlignment = Enum.HorizontalAlignment.Left,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 1),
						}),
						StatsFragment = Roact.createFragment(itemStatComponents),
					}),
				}) or nil,
				Ingredients = createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.9, 0, 0.34, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.43)
				}, {
					UIGridLayout = createElement("UIGridLayout", {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						CellSize = UDim2.fromScale(1, 0.5),
						CellPadding = UDim2.fromOffset(paddingPixels, paddingPixels),
					}, {
						UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
							AspectRatio = 1,
							DominantAxis = Enum.DominantAxis.Height
						})
					}),
					IngredientsFragment = Roact.createFragment(requiredIngredientComponents)
				}),
				CraftButton = createElement(TextButton, {
					text = "CRAFT",
					AnchorPoint = Vector2.new(0.5, 0.5),
					size = "sm",
					Position = UDim2.new(0.5, 0, 1, -28),
					color = "green",
					disabled = not canCraft,
					onClick = function()
						if selectedRecipe then
							RF_Craft:InvokeServer(selectedRecipe.name)
						end
					end,
				})
			})
		})
	})
end

function CraftingPage:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			return self:_renderContent(data)
		end,
	})
end

return CraftingPage
