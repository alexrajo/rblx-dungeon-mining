local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local IngredientCounter = require(ModuleIndex.IngredientCounter)
local StatsContext = require(ModuleIndex.StatsContext)

local IngredientsView = Roact.Component:extend("IngredientsView")

function IngredientsView:render()
	local itemsPerRow = 8
	local paddingPixels = 4
	
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local ingredients = data.Ingredients
			local ingredientElements = {}
			for _, ingredient in ipairs(ingredients) do
				local name = ingredient.name
				local amount = ingredient.value
				if amount <= 0 then continue end

				local element = createElement(IngredientCounter, {
					name = name,
					amount = amount
				})
				table.insert(ingredientElements, element)
			end
		
			return createElement("ScrollingFrame", {
				Size = UDim2.new(1, -20, 1, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Visible = self.props.Visible
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
				Items = Roact.createFragment(ingredientElements)
			})
		end
	})
end

return IngredientsView