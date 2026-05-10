local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local StoryUtils = require(script.Parent.StoryUtils)
local Clickable = require(ModuleIndex.Clickable)
local SelectableItemTile = require(ModuleIndex.SelectableItemTile)
local SelectablePanel = require(ModuleIndex.SelectablePanel)
local Tab = require(ModuleIndex.Tab)
local TextLabel = require(ModuleIndex.TextLabel)

local createElement = Roact.createElement

local function makeSelectablePanel(text: string, selected: boolean, layoutOrder: number)
	return StoryUtils.makeCell(createElement(SelectablePanel, {
		selected = selected,
		Size = UDim2.fromScale(1, 1),
		onSelect = StoryUtils.noop,
	}, {
		Text = createElement(TextLabel, {
			Text = text,
			textSize = 18,
			Size = UDim2.fromScale(1, 1),
			textProps = {
				TextScaled = true,
			},
		}),
	}), {
		layoutOrder = layoutOrder,
		size = UDim2.fromOffset(150, 90),
		backgroundTransparency = 1,
	})
end

function story(target: Frame)
	local component = StoryUtils.makeCanvas({
		Title = StoryUtils.makeLabel("Selection", 1),
		Tabs = StoryUtils.makeRow({
			Active = createElement(Tab, {
				text = "ACTIVE",
				selected = true,
				xSize = UDim.new(0, 150),
				LayoutOrder = 1,
				onClick = StoryUtils.noop,
			}),
			Inactive = createElement(Tab, {
				text = "COMPLETE",
				selected = false,
				xSize = UDim.new(0, 170),
				LayoutOrder = 2,
				onClick = StoryUtils.noop,
			}),
		}, {
			layoutOrder = 2,
			size = UDim2.new(1, 0, 0, 54),
			verticalAlignment = Enum.VerticalAlignment.Top,
		}),
		Panels = StoryUtils.makeRow({
			Default = makeSelectablePanel("Unselected", false, 1),
			Selected = makeSelectablePanel("Selected", true, 2),
			Clickable = StoryUtils.makeCell(createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, {
				Label = createElement(TextLabel, {
					Text = "Clickable",
					textSize = 18,
					Size = UDim2.fromScale(1, 1),
					textProps = {
						TextScaled = true,
					},
				}),
				ClickTarget = createElement(Clickable, {
					onClick = StoryUtils.noop,
				}),
			}), {
				layoutOrder = 3,
				size = UDim2.fromOffset(150, 90),
			}),
		}, {
			layoutOrder = 3,
			size = UDim2.new(1, 0, 0, 90),
		}),
		Items = StoryUtils.makeRow({
			Pickaxe = StoryUtils.makeCell(createElement(SelectableItemTile, {
				itemName = "Wood Pickaxe",
				amount = 1,
				slotNumber = 1,
				selected = true,
				Size = UDim2.fromScale(1, 1),
				showSelectionTint = true,
				onSelect = StoryUtils.noop,
			}), {
				layoutOrder = 1,
				size = UDim2.fromOffset(110, 110),
				backgroundTransparency = 1,
			}),
			Bomb = StoryUtils.makeCell(createElement(SelectableItemTile, {
				itemName = "Mini Bomb",
				amount = 12,
				slotNumber = 2,
				Size = UDim2.fromScale(1, 1),
				onSelect = StoryUtils.noop,
			}), {
				layoutOrder = 2,
				size = UDim2.fromOffset(110, 110),
				backgroundTransparency = 1,
			}),
			Compact = StoryUtils.makeCell(createElement(SelectableItemTile, {
				itemName = "Health Potion",
				amount = 4,
				showName = false,
				selected = true,
				Size = UDim2.fromScale(1, 1),
				onSelect = StoryUtils.noop,
			}), {
				layoutOrder = 3,
				size = UDim2.fromOffset(86, 86),
				backgroundTransparency = 1,
			}),
		}, {
			layoutOrder = 4,
			size = UDim2.new(1, 0, 0, 110),
		}),
	})

	return StoryUtils.mount(target, component)
end

return story
