local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local Roact = require(Services.Roact)

local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local assignHotbarSlotEvent = APIService.GetEvent("AssignHotbarSlot")
local clearHotbarSlotEvent = APIService.GetEvent("ClearHotbarSlot")
local clearEquippedGearEvent = APIService.GetEvent("ClearEquippedGear")
local equipGearEvent = APIService.GetEvent("EquipGear")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local Button = require(ModuleIndex.Button)
local SelectablePanel = require(ModuleIndex.SelectablePanel)
local TextLabel = require(ModuleIndex.TextLabel)
local StatsContext = require(ModuleIndex.StatsContext)
local GearGridView = require(script.Parent.GearGridView)
local GearUtils = require(script.Parent.GearUtils)

local LoadoutView = Roact.Component:extend("LoadoutView")

local ARMOR_SLOTS = { "Helmet", "Chestplate", "Leggings", "Boots" }

function LoadoutView:init()
	self:setState({
		selectorTarget = nil,
	})
end

function LoadoutView:getCurrentArmorName(data, slotName: string): string
	return data["Equipped" .. slotName] or ""
end

function LoadoutView:openSelector(target)
	self:setState({
		selectorTarget = target,
	})
end

function LoadoutView:closeSelector()
	self:setState({
		selectorTarget = Roact.None,
	})
end

function LoadoutView:renderSlotCard(layoutOrder: number, label: string, itemName: string, onSelect)
	return createElement(SelectablePanel, {
		Size = UDim2.fromOffset(96, 96),
		aspectRatio = 1,
		selected = false,
		LayoutOrder = layoutOrder,
		onSelect = onSelect,
	}, {
		Label = createElement(TextLabel, {
			Text = label,
			textSize = 14,
			Size = UDim2.new(1, -8, 0, 18),
			Position = UDim2.new(0.5, 0, 0, 8),
			AnchorPoint = Vector2.new(0.5, 0),
			textProps = {
				TextScaled = true,
			},
		}),
		Icon = createElement("ImageLabel", {
			Image = "rbxassetid://" .. GearConfig.GetImageIdForItem(itemName ~= "" and itemName or ""),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			ImageTransparency = itemName == "" and 0.65 or 0,
		}),
		Name = createElement(TextLabel, {
			Text = itemName ~= "" and itemName or "Empty",
			textSize = 12,
			Size = UDim2.new(1, -8, 0, 24),
			Position = UDim2.new(0.5, 0, 1, -8),
			AnchorPoint = Vector2.new(0.5, 1),
			textProps = {
				TextScaled = true,
				TextWrapped = true,
			},
		}),
	})
end

function LoadoutView:renderOverview(data)
	local hotbarSlots = HotbarConfig.NormalizeStoredSlots(data.HotbarSlots or {})
	local hotbarCards = {}
	local armorCards = {}

	for index = 1, HotbarConfig.MAX_SLOTS do
		local itemName = hotbarSlots[index] or ""
		hotbarCards["Hotbar" .. tostring(index)] = self:renderSlotCard(index, "Slot " .. tostring(index), itemName, function()
			self:openSelector({
				kind = "hotbar",
				slotIndex = index,
				title = "Select gear for slot " .. tostring(index),
			})
		end)
	end

	for index, slotName in ipairs(ARMOR_SLOTS) do
		local itemName = self:getCurrentArmorName(data, slotName)
		armorCards["Armor" .. slotName] = self:renderSlotCard(index, slotName, itemName, function()
			self:openSelector({
				kind = "armor",
				slotName = slotName,
				title = "Select gear for " .. slotName,
			})
		end)
	end

	return createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		HotbarLabel = createElement(TextLabel, {
			Text = "Hotbar",
			textSize = 26,
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.zero,
			textProps = {
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
		}),
		HotbarRow = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 104),
			Position = UDim2.new(0, 0, 0, 38),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Slots = Roact.createFragment(hotbarCards),
		}),
		ArmorLabel = createElement(TextLabel, {
			Text = "Armor",
			textSize = 26,
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 154),
			AnchorPoint = Vector2.zero,
			textProps = {
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
		}),
		ArmorRow = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 104),
			Position = UDim2.new(0, 0, 0, 192),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Slots = Roact.createFragment(armorCards),
		}),
	})
end

function LoadoutView:renderSelector(data)
	local target = self.state.selectorTarget
	local selectedItemName = nil
	local gearEntries

	if target.kind == "hotbar" then
		local hotbarSlots = HotbarConfig.NormalizeStoredSlots(data.HotbarSlots or {})
		selectedItemName = hotbarSlots[target.slotIndex] or ""
		gearEntries = GearUtils.GetOwnedGearEntries(data, function(itemName)
			return HotbarConfig.IsEntryHotbarEligible(itemName)
		end)
	else
		selectedItemName = self:getCurrentArmorName(data, target.slotName)
		gearEntries = GearUtils.GetOwnedGearEntries(data, function(itemName, itemData)
			return itemData.slot == target.slotName
		end)
	end

	return createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		Title = createElement(TextLabel, {
			Text = target.title,
			textSize = 26,
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.zero,
			textProps = {
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
		}),
		ActionRow = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 60),
			Position = UDim2.new(0, 0, 0, 38),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Back = createElement(Button, {
				customSize = UDim2.new(0.33, -6, 1, 0),
				LayoutOrder = 1,
				color = "yellow",
				disableHoverScaleTween = true,
				onClick = function()
					self:closeSelector()
				end,
			}, {
				Text = createElement(TextLabel, {
					Text = "Back",
					textSize = 16,
					Size = UDim2.fromScale(0.9, 0.9),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					textProps = { TextScaled = true },
				}),
			}),
			Wipe = createElement(Button, {
				customSize = UDim2.new(0.33, -6, 1, 0),
				LayoutOrder = 2,
				color = "red",
				disableHoverScaleTween = true,
				onClick = function()
					if target.kind == "hotbar" then
						clearHotbarSlotEvent:FireServer(target.slotIndex)
					else
						clearEquippedGearEvent:FireServer(target.slotName)
					end
					self:closeSelector()
				end,
			}, {
				Text = createElement(TextLabel, {
					Text = "Wipe Slot",
					textSize = 16,
					Size = UDim2.fromScale(0.9, 0.9),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					textProps = { TextScaled = true },
				}),
			}),
			Hint = createElement(TextLabel, {
				Text = "Select a gear item below",
				textSize = 16,
				Size = UDim2.new(0.34, -4, 1, 0),
				LayoutOrder = 3,
				textProps = {
					TextScaled = true,
					TextWrapped = true,
				},
			}),
		}),
		Grid = createElement(GearGridView, {
			Visible = true,
			interactive = true,
			selectedItemName = selectedItemName,
			Size = UDim2.new(1, -20, 1, -114),
			Position = UDim2.new(0.5, 0, 0, 114),
			AnchorPoint = Vector2.new(0.5, 0),
			gearEntries = gearEntries,
			onItemSelected = function(itemName: string)
				if target.kind == "hotbar" then
					assignHotbarSlotEvent:FireServer(target.slotIndex, itemName)
				else
					equipGearEvent:FireServer(itemName)
				end
				self:closeSelector()
			end,
		}),
	})
end

function LoadoutView:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			if not self.props.Visible then
				return nil
			end

			if self.state.selectorTarget ~= nil then
				return self:renderSelector(data)
			end

			return self:renderOverview(data)
		end,
	})
end

return LoadoutView
