local plr = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local Maid = require(Services.Maid)
local APIService = require(Services.APIService)
local DrinkRecipeService = require(Services.DrinkRecipeService)

local RF_MixDrink = APIService.GetFunction("MixDrink")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local PageWrapper = require(ModuleIndex.PageWrapper)
local Window = require(ModuleIndex.Window)
local Button = require(ModuleIndex.Button)
local TextButton = require(ModuleIndex.TextButton)
local ProgressBar = require(ModuleIndex.ProgressBar)
local TextLabel = require(ModuleIndex.TextLabel)
local Panel = require(ModuleIndex.Panel)
local IngredientCounter = require(ModuleIndex.IngredientCounter)

local StatsContext = require(ModuleIndex.StatsContext)

local DrinkMixingPage = Roact.Component:extend("DrinkMixingPage")

local dataUpdateMaid = Maid.new()

local allRecipes = DrinkRecipeService.GetAllRecipes()

function DrinkMixingPage:init()
	self:setState({
		selectedRecipeIndex = nil
	})
end

function DrinkMixingPage:willUnmount()
	dataUpdateMaid:Destroy()
end

function DrinkMixingPage:_renderContent(statsData)
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
	
	local canCombine = true

	if selectedRecipe ~= nil then
		local ownedIngredients = statsData.Ingredients
		local requiredIngredients = selectedRecipe.ingredients
		for name, amount in pairs(requiredIngredients) do
			local amountOwned = 0
			for _, ingredient in ipairs(ownedIngredients) do
				if ingredient.name == name then
					amountOwned = ingredient.value
					break
				end
			end
			
			if amountOwned < amount then
				canCombine = false
			end
			
			local component = createElement(IngredientCounter, {name = name, amount = amount, amountOwned = amountOwned})
			table.insert(requiredIngredientComponents, component)
		end
	else
		canCombine = false
	end
	
	local ownedDrinks = statsData.OwnedDrinks
	local function ownsDrink(drinkName)
		for _, drink in ipairs(ownedDrinks) do
			if drink.name == drinkName then return true end
		end
		return false
	end
	
	local recipeComponents = {}
	for i, recipe in ipairs(allRecipes) do
		if ownsDrink(recipe.drinkName) then continue end
		
		local component = createElement(Button, {
			color = (i == selectedRecipeIndex and "yellow" or "gray"),
			onClick = function()
				self:setState({
					selectedRecipeIndex = i
				})
			end,
		}, {
			ImageLabel = createElement("ImageLabel", {
				Image = "rbxassetid://77587268434820",
				Size = UDim2.fromScale(0.75, 0.75),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1
			}),
			TextLabel = createElement(TextLabel, {
				Text = recipe.drinkName,
				Size = UDim2.new(0.8, 0, 0.2, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 1)
			})
		})
		table.insert(recipeComponents, component)
	end

	return createElement(PageWrapper, {isOpen = (currentPage == "DrinkMixingPage")}, {
		Window = createElement(Window, {title = "MIX DRINKS", Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), onExit = onExit}, {
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
			CombinationView = createElement("Frame", {
				Size = UDim2.new(0.4, -12, 1, -16),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0
			}, {
				UICorner = createElement("UICorner"),
				Ingredients = createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.9, 0, 0.55, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.05)
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
				CombineButton = createElement(TextButton, {
					text = "COMBINE", 
					AnchorPoint = Vector2.new(0.5, 0.5), 
					size = "sm", Position = UDim2.new(0.5, 0, 1, -28), 
					color = "green", 
					disabled = not canCombine,
					onClick = function()
						RF_MixDrink:InvokeServer(selectedRecipe.drinkName)
					end,
				})	
			})
		})
	})
end

function DrinkMixingPage:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			return self:_renderContent(data)
		end,
	})
end

return DrinkMixingPage
