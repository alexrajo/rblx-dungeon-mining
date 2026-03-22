local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local APIService = require(Services.APIService)
local CraftingRecipeService = require(Services.CraftingRecipeService)

local RF_Craft = APIService.GetFunction("Craft")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local PageWrapper = require(ModuleIndex.PageWrapper)
local Window = require(ModuleIndex.Window)
local Button = require(ModuleIndex.Button)
local TextButton = require(ModuleIndex.TextButton)
local TextLabel = require(ModuleIndex.TextLabel)
local Panel = require(ModuleIndex.Panel)
local ItemCounter = require(ModuleIndex.ItemCounter)

local StatsContext = require(ModuleIndex.StatsContext)

local CraftingPage = Roact.Component:extend("CraftingPage")

local allRecipes = CraftingRecipeService.GetAllRecipes()

function CraftingPage:init()
	self:setState({
		selectedRecipeIndex = nil
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

	local selectedRecipeIndex = self.state.selectedRecipeIndex
	local selectedRecipe = allRecipes[selectedRecipeIndex]
	local requiredIngredientComponents = {}

	local canCraft = true
	local inventory = statsData.Inventory or {}

	-- Helper to get owned amount
	local function getOwned(itemName)
		for _, entry in ipairs(inventory) do
			if entry.name == itemName then
				return entry.value
			end
		end
		return 0
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

	local recipeComponents = {}
	for i, recipe in ipairs(allRecipes) do
		local component = createElement(Button, {
			color = (i == selectedRecipeIndex and "yellow" or "gray"),
			onClick = function()
				self:setState({
					selectedRecipeIndex = i
				})
			end,
		}, {
			TextLabel = createElement(TextLabel, {
				Text = recipe.name,
				Size = UDim2.fromScale(0.9, 0.3),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5)
			}),
			Category = createElement(TextLabel, {
				Text = recipe.category or "",
				Size = UDim2.fromScale(0.9, 0.2),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.95)
			})
		})
		table.insert(recipeComponents, component)
	end

	return createElement(PageWrapper, {isOpen = (currentPage == "CraftingPage")}, {
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
				Ingredients = createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.9, 0, 0.55, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.12)
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
