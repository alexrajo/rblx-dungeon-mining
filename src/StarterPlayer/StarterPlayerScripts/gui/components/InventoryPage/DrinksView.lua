local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local Roact = require(Services.Roact)

local equipDrinkEvent = APIService.GetEvent("EquipDrink")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local SelectablePanel = require(ModuleIndex.SelectablePanel)
local TextLabel = require(ModuleIndex.TextLabel)
local Clickable = require(ModuleIndex.Clickable)
local StatsContext = require(ModuleIndex.StatsContext)

local DrinksView = Roact.Component:extend("DrinksView")

function DrinksView:render()
	local itemsPerRow = 8
	local paddingPixels = 4

	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local ownedDrinks = data.OwnedDrinks
			local equippedDrink = data.EquippedDrink
			local drinkElements = {}
			for _, drink in ipairs(ownedDrinks) do
				local name = drink.name
				local isEquipped = equippedDrink == name

				local element = createElement(SelectablePanel, {
					onSelect = function()
						equipDrinkEvent:FireServer(name)
					end,
					selected = isEquipped
				}, {
					ImageLabel = createElement("ImageLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(0.8, 0, 0.8, 0),
						Image = "rbxassetid://3361929763",
						ScaleType = Enum.ScaleType.Fit,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5)
					}),
					TextLabel = createElement(TextLabel, {
						Text = name,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 1),
						Size = UDim2.fromScale(0.8, 0.8)
					})
				})
				table.insert(drinkElements, element)
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
				Items = Roact.createFragment(drinkElements)
			})
		end
	})
end

return DrinksView