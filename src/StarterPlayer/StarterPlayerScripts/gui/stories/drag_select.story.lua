local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local StoryUtils = require(script.Parent.StoryUtils)
local DragSelect = require(ModuleIndex.DragSelect)
local SelectableItemTile = require(ModuleIndex.SelectableItemTile)
local TextLabel = require(ModuleIndex.TextLabel)

local createElement = Roact.createElement

local DragSelectStory = Roact.Component:extend("DragSelectStory")

local SAMPLE_ITEMS = {
	{ entryId = "pickaxe-1", itemName = "Copper Pickaxe", slot = "Pickaxe" },
	{ entryId = "sword-1", itemName = "Iron Sword", slot = "Weapon" },
	{ entryId = "helmet-1", itemName = "Gold Helmet", slot = "Helmet" },
	{ entryId = "chestplate-1", itemName = "Diamond Chestplate", slot = "Chestplate" },
	{ entryId = "boots-1", itemName = "Obsidian Boots", slot = "Boots" },
}

local ARMOR_SLOTS = {
	"Helmet",
	"Chestplate",
	"Leggings",
	"Boots",
}

function DragSelectStory:init()
	self:setState({
		Hotbar1 = "",
		Hotbar2 = "",
		Helmet = "",
		Chestplate = "",
		Leggings = "",
		Boots = "",
	})
end

function DragSelectStory:renderPreview(payload)
	return createElement(SelectableItemTile, {
		itemName = payload.itemName,
		showName = false,
		Size = UDim2.fromScale(1, 1),
	})
end

function DragSelectStory:renderSource(entry, layoutOrder: number)
	return createElement(DragSelect.Source, {
		LayoutOrder = layoutOrder,
		Size = UDim2.fromOffset(92, 92),
		payload = {
			entryId = entry.entryId,
			itemName = entry.itemName,
			slot = entry.slot,
		},
		renderPreview = function(payload)
			return self:renderPreview(payload)
		end,
	}, {
		Tile = createElement(SelectableItemTile, {
			itemName = entry.itemName,
			showName = false,
			Size = UDim2.fromScale(1, 1),
		}),
	})
end

function DragSelectStory:renderSlot(title: string, itemName: string, layoutOrder: number, canDrop, onDrop)
	return createElement(DragSelect.Target, {
		LayoutOrder = layoutOrder,
		Size = UDim2.fromOffset(104, 104),
		targetId = title,
		canDrop = canDrop,
		onDrop = onDrop,
	}, {
		Card = createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 125, 190),
			Size = UDim2.fromScale(1, 1),
		}, {
			Corner = createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			Stroke = createElement("UIStroke", {
				Color = Color3.fromRGB(0, 43, 106),
				Thickness = 2,
			}),
			Label = itemName == "" and createElement(TextLabel, {
				Text = title,
				textSize = 16,
				Size = UDim2.new(1, -12, 1, -12),
				Position = UDim2.fromOffset(6, 6),
				textProps = {
					TextScaled = true,
					TextWrapped = true,
				},
			}) or nil,
			Item = itemName ~= "" and createElement(SelectableItemTile, {
				itemName = itemName,
				showName = false,
				Size = UDim2.new(1, -10, 1, -10),
				Position = UDim2.fromOffset(5, 5),
			}) or nil,
		}),
	})
end

function DragSelectStory:render()
	local sources = {}
	for index, entry in ipairs(SAMPLE_ITEMS) do
		sources["Source" .. tostring(index)] = self:renderSource(entry, index)
	end

	local armorTargets = {}
	for index, slotName in ipairs(ARMOR_SLOTS) do
		armorTargets[slotName] = self:renderSlot(slotName, self.state[slotName], index, function(payload)
			return payload ~= nil and GearConfig.GetSlotForItem(payload.itemName) == slotName
		end, function(payload)
			self:setState({
				[slotName] = payload.itemName,
			})
		end)
	end

	return StoryUtils.makeCanvas({
		Title = StoryUtils.makeLabel("Drag Select", 1),
		Manager = createElement(DragSelect.Manager, {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 360),
		}, {
			Layout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 18),
			}),
			Sources = StoryUtils.makeRow(sources, {
				layoutOrder = 1,
				size = UDim2.new(1, 0, 0, 100),
			}),
			HotbarTargets = StoryUtils.makeRow({
				Hotbar1 = self:renderSlot("Hotbar 1", self.state.Hotbar1, 1, function(payload)
					return payload ~= nil and HotbarConfig.IsEntryHotbarEligible(payload.itemName)
				end, function(payload)
					self:setState({
						Hotbar1 = payload.itemName,
					})
				end),
				Hotbar2 = self:renderSlot("Hotbar 2", self.state.Hotbar2, 2, function(payload)
					return payload ~= nil and HotbarConfig.IsEntryHotbarEligible(payload.itemName)
				end, function(payload)
					self:setState({
						Hotbar2 = payload.itemName,
					})
				end),
			}, {
				layoutOrder = 2,
				size = UDim2.new(1, 0, 0, 110),
			}),
			ArmorTargets = StoryUtils.makeRow(armorTargets, {
				layoutOrder = 3,
				size = UDim2.new(1, 0, 0, 110),
			}),
		}),
	})
end

function story(target: Frame)
	return StoryUtils.mount(target, createElement(DragSelectStory))
end

return story
