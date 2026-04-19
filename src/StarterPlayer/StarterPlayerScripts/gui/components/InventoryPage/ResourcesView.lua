local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local ItemCounter = require(ModuleIndex.ItemCounter)
local StatsContext = require(ModuleIndex.StatsContext)

local ResourcesView = Roact.Component:extend("ResourcesView")

function ResourcesView:render()
	local itemsPerRow = 8
	local paddingPixels = 4

	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local inventory = data.Inventory
			local itemElements = {}
			for _, item in ipairs(inventory) do
				local name = item.name
				local amount = item.value
				if type(amount) ~= "number" then continue end
				if amount <= 0 then continue end
				if GearConfig.GetItemData(name) ~= nil then continue end

				local element = createElement(ItemCounter, {
					name = name,
					amount = amount
				})
				table.insert(itemElements, element)
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
				Items = Roact.createFragment(itemElements)
			})
		end
	})
end

return ResourcesView
