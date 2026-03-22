local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local Roact = require(Services.Roact)

local equipGearEvent = APIService.GetEvent("EquipGear")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local SelectablePanel = require(ModuleIndex.SelectablePanel)
local TextLabel = require(ModuleIndex.TextLabel)
local StatsContext = require(ModuleIndex.StatsContext)

local GearView = Roact.Component:extend("GearView")

-- Gear items the player can own/equip (check inventory for crafted ones)
local GEAR_SLOTS = { "Pickaxe", "Weapon", "Helmet", "Chestplate", "Boots" }

function GearView:render()
	local itemsPerRow = 5
	local paddingPixels = 4

	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local gearElements = {}

			for _, slot in ipairs(GEAR_SLOTS) do
				local equippedName = data["Equipped" .. slot] or ""
				local isEquipped = equippedName ~= ""

				local element = createElement(SelectablePanel, {
					selected = isEquipped,
				}, {
					TextLabel = createElement(TextLabel, {
						Text = isEquipped and equippedName or ("No " .. slot),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.9, 0.9)
					})
				})
				table.insert(gearElements, element)
			end

			-- Also show craftable gear from inventory
			local inventory = data.Inventory or {}
			for _, item in ipairs(inventory) do
				local name = item.name
				local amount = item.value
				if amount <= 0 then continue end

				-- Check if this item is a gear piece (contains Pickaxe, Sword, Helmet, etc.)
				local isGear = string.find(name, "Pickaxe") or string.find(name, "Sword")
					or string.find(name, "Helmet") or string.find(name, "Chestplate")
					or string.find(name, "Boots")

				if not isGear then continue end

				local isCurrentlyEquipped = false
				for _, slot in ipairs(GEAR_SLOTS) do
					if data["Equipped" .. slot] == name then
						isCurrentlyEquipped = true
						break
					end
				end

				local element = createElement(SelectablePanel, {
					onSelect = function()
						equipGearEvent:FireServer(name)
					end,
					selected = isCurrentlyEquipped
				}, {
					TextLabel = createElement(TextLabel, {
						Text = name,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.9, 0.9)
					})
				})
				table.insert(gearElements, element)
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
				Items = Roact.createFragment(gearElements)
			})
		end
	})
end

return GearView
