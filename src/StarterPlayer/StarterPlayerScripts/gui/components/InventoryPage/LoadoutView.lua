local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)

local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local TextLabel = require(ModuleIndex.TextLabel)

local LoadoutSlotCard = Roact.Component:extend("LoadoutSlotCard")
local LoadoutView = Roact.PureComponent:extend("LoadoutView")

local HOTBAR_SLOT_DEFINITIONS = {
	{ slotIndex = 1, badgeText = "1" },
	{ slotIndex = 2, badgeText = "2" },
	{ slotIndex = 3, badgeText = "3" },
	{ slotIndex = 4, badgeText = "4" },
	{ slotIndex = 5, badgeText = "5" },
}

local ARMOR_SLOT_DEFINITIONS = {
	{ slotName = "Helmet", placeholderImageId = "ASSET_ID_HERE" },
	{ slotName = "Chestplate", placeholderImageId = "ASSET_ID_HERE" },
	{ slotName = "Leggings", placeholderImageId = "ASSET_ID_HERE" },
	{ slotName = "Boots", placeholderImageId = "ASSET_ID_HERE" },
}

local PANEL_PADDING = 10
local PANEL_HEADER_HEIGHT = 30
local PANEL_HEADER_GAP = 10
local COLUMN_PADDING = 8
local HOTBAR_SLOT_COUNT = #HOTBAR_SLOT_DEFINITIONS
local ARMOR_SLOT_COUNT = #ARMOR_SLOT_DEFINITIONS

local function getSquareSlotSize(columnWidth: number, availableHeight: number, slotCount: number): number
	if slotCount <= 0 then
		return 0
	end

	local heightLimitedSize = math.floor((availableHeight - COLUMN_PADDING * (slotCount - 1)) / slotCount)
	local widthLimitedSize = math.floor(columnWidth)
	return math.max(0, math.min(widthLimitedSize, heightLimitedSize))
end

function LoadoutSlotCard:init()
	self:setState({
		hovering = false,
	})
end

function LoadoutSlotCard:render()
	local itemName = self.props.itemName or ""
	local imageId = itemName ~= "" and GearConfig.GetImageIdForItem(itemName) or ""
	local hovering = self.state.hovering
	local hasItem = itemName ~= ""
	local zIndex = self.props.ZIndex or 1
	local showName = self.props.showName == true
	local numberInset = 10

	return createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(16, 121, 191),
		Size = self.props.Size,
		LayoutOrder = self.props.LayoutOrder,
		ZIndex = zIndex,
	}, {
		UICorner = createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		UIStroke = createElement("UIStroke", {
			Color = Color3.fromRGB(0, 43, 106),
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 2,
		}),
		Shadow = createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 5),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.82,
			ZIndex = zIndex - 1,
		}, {
			UICorner = createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}),
		Inner = createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(22, 151, 230),
			Position = UDim2.fromOffset(4, 4),
			Size = UDim2.new(1, -8, 1, -8),
			ZIndex = zIndex + 1,
			ClipsDescendants = true,
		}, {
			UICorner = createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Placeholder = self.props.placeholderImageId and createElement("ImageLabel", {
				Image = "rbxassetid://" .. self.props.placeholderImageId,
				Size = UDim2.new(1, -12, 1, -24),
				Position = UDim2.new(0.5, 0, 0.5, -4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ImageTransparency = hasItem and 0.82 or 0.55,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = zIndex + 1,
			}) or nil,
			ItemImage = hasItem and createElement("ImageLabel", {
				Image = "rbxassetid://" .. imageId,
				Size = UDim2.new(0.62, 0, 0.62, 0),
				Position = UDim2.new(0.5, 0, 0.44, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = zIndex + 2,
			}) or nil,
			Badge = self.props.badgeText and createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 43, 106),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -numberInset, 0, numberInset),
				Size = UDim2.fromOffset(18, 18),
				ZIndex = zIndex + 3,
			}, {
				UICorner = createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				Text = createElement(TextLabel, {
					Text = self.props.badgeText,
					textSize = 11,
					Size = UDim2.fromScale(1, 1),
					ZIndex = zIndex + 4,
					textProps = {
						TextScaled = true,
					},
				}),
			}) or nil,
			ItemLabel = showName and hasItem and createElement(TextLabel, {
				Text = itemName,
				textSize = 12,
				Size = UDim2.new(1, -12, 0, 26),
				Position = UDim2.new(0.5, 0, 1, -6),
				AnchorPoint = Vector2.new(0.5, 1),
				ZIndex = zIndex + 3,
				textProps = {
					TextScaled = true,
					TextWrapped = true,
				},
			}) or nil,
			RemoveButton = hasItem and hovering and createElement("TextButton", {
				Text = "",
				BackgroundColor3 = Color3.fromRGB(185, 22, 22),
				BorderSizePixel = 0,
				AutoButtonColor = true,
				Size = UDim2.fromOffset(24, 24),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -6, 0, 6),
				ZIndex = zIndex + 4,
				[Roact.Event.Activated] = self.props.onRemove,
			}, {
				UICorner = createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				UIStroke = createElement("UIStroke", {
					Color = Color3.fromRGB(0, 0, 0),
					Thickness = 1,
				}),
				Text = createElement(TextLabel, {
					Text = "X",
					textSize = 12,
					Size = UDim2.new(1, -4, 1, -4),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					ZIndex = zIndex + 5,
					textProps = {
						TextScaled = true,
					},
				}),
			}) or nil,
			HoverCatcher = createElement("TextButton", {
				Text = "",
				BackgroundTransparency = hovering and 0.92 or 1,
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.fromScale(1, 1),
				ZIndex = zIndex + 3,
				AutoButtonColor = false,
				[Roact.Event.MouseEnter] = function()
					self:setState({
						hovering = true,
					})
				end,
				[Roact.Event.MouseLeave] = function()
					self:setState({
						hovering = false,
					})
				end,
			}),
		}),
	})
end

function LoadoutView:getCurrentArmorName(data, slotName: string): string
	return data["Equipped" .. slotName] or ""
end

function LoadoutView:init()
	self.rootRef = Roact.createRef()
	self:setState({
		absoluteSize = Vector2.zero,
	})
end

function LoadoutView:updateAbsoluteSize()
	local root = self.rootRef:getValue()
	if root == nil then
		return
	end

	local absoluteSize = root.AbsoluteSize
	local currentSize = self.state.absoluteSize
	if currentSize.X == absoluteSize.X and currentSize.Y == absoluteSize.Y then
		return
	end

	self:setState({
		absoluteSize = absoluteSize,
	})
end

function LoadoutView:didMount()
	self:updateAbsoluteSize()
end

function LoadoutView:didUpdate()
	self:updateAbsoluteSize()
end

function LoadoutView:getLayoutMetrics()
	local absoluteSize = self.state.absoluteSize
	local widthOffset = absoluteSize.X
	local heightOffset = absoluteSize.Y

	local contentWidth = math.max(0, widthOffset - PANEL_PADDING * 2)
	local contentHeight = math.max(0, heightOffset - PANEL_PADDING * 2 - PANEL_HEADER_HEIGHT - PANEL_HEADER_GAP)
	local columnWidth = math.max(0, (contentWidth - COLUMN_PADDING) / 2)

	return {
		contentHeight = contentHeight,
		columnWidth = columnWidth,
		hotbarSlotSize = getSquareSlotSize(columnWidth, contentHeight, HOTBAR_SLOT_COUNT),
		armorSlotSize = getSquareSlotSize(columnWidth, contentHeight, ARMOR_SLOT_COUNT),
	}
end

function LoadoutView:renderHotbarColumn(data, layoutMetrics)
	local hotbarSlots = HotbarConfig.NormalizeStoredSlots(data.HotbarSlots or {})
	local cards = {}

	for _, slotInfo in ipairs(HOTBAR_SLOT_DEFINITIONS) do
		cards["Hotbar" .. tostring(slotInfo.slotIndex)] = createElement(LoadoutSlotCard, {
			LayoutOrder = slotInfo.slotIndex,
			Size = UDim2.fromOffset(layoutMetrics.hotbarSlotSize, layoutMetrics.hotbarSlotSize),
			badgeText = slotInfo.badgeText,
			itemName = hotbarSlots[slotInfo.slotIndex] or "",
			onRemove = function()
				if self.props.onClearHotbarSlot ~= nil then
					self.props.onClearHotbarSlot(slotInfo.slotIndex)
				end
			end,
			ZIndex = 5,
		})
	end

	return createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.48, 0, 1, 0),
		Position = UDim2.fromScale(0, 0),
	}, {
		List = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, COLUMN_PADDING),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Cards = Roact.createFragment(cards),
		}),
	})
end

function LoadoutView:renderArmorColumn(data, layoutMetrics)
	local cards = {}

	for index, slotInfo in ipairs(ARMOR_SLOT_DEFINITIONS) do
		cards["Armor" .. slotInfo.slotName] = createElement(LoadoutSlotCard, {
			LayoutOrder = index,
			Size = UDim2.fromOffset(layoutMetrics.armorSlotSize, layoutMetrics.armorSlotSize),
			itemName = self:getCurrentArmorName(data, slotInfo.slotName),
			placeholderImageId = slotInfo.placeholderImageId,
			onRemove = function()
				if self.props.onClearArmorSlot ~= nil then
					self.props.onClearArmorSlot(slotInfo.slotName)
				end
			end,
			ZIndex = 5,
		})
	end

	return createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.48, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
	}, {
		List = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			UIListLayout = createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, COLUMN_PADDING),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Cards = Roact.createFragment(cards),
		}),
	})
end

function LoadoutView:render()
	if not self.props.Visible then
		return nil
	end

	local data = self.props.data or {}
	local layoutMetrics = self:getLayoutMetrics()

	return createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(11, 95, 150),
		BackgroundTransparency = 0.08,
		Size = self.props.Size or UDim2.fromScale(1, 1),
		Position = self.props.Position,
		AnchorPoint = self.props.AnchorPoint,
		[Roact.Ref] = self.rootRef,
		[Roact.Change.AbsoluteSize] = function()
			self:updateAbsoluteSize()
		end,
	}, {
		UICorner = createElement("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		UIStroke = createElement("UIStroke", {
			Color = Color3.fromRGB(0, 43, 106),
			Thickness = 2,
		}),
		Padding = createElement("UIPadding", {
			PaddingTop = UDim.new(0, PANEL_PADDING),
			PaddingBottom = UDim.new(0, PANEL_PADDING),
			PaddingLeft = UDim.new(0, PANEL_PADDING),
			PaddingRight = UDim.new(0, PANEL_PADDING),
		}),
		Title = createElement(TextLabel, {
			Text = "Loadout",
			textSize = 26,
			Size = UDim2.new(1, 0, 0, PANEL_HEADER_HEIGHT),
			textProps = {
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
		}),
		Columns = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, -(PANEL_HEADER_HEIGHT + PANEL_HEADER_GAP)),
			Position = UDim2.fromOffset(0, PANEL_HEADER_HEIGHT + PANEL_HEADER_GAP),
		}, {
			HotbarColumn = self:renderHotbarColumn(data, layoutMetrics),
			ArmorColumn = self:renderArmorColumn(data, layoutMetrics),
		}),
	})
end

return LoadoutView
