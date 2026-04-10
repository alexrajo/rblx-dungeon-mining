local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local ItemLookupService = require(Services.ItemLookupService)

local createElement = Roact.createElement

local gui = script.Parent.Parent
local ModuleIndex = require(gui.ModuleIndex)
local Panel = require(ModuleIndex.Panel)
local TextLabel = require(ModuleIndex.TextLabel)

local SLIDE_IN_DURATION = 0.25
local POPUP_DURATION = 3
local SLIDE_OUT_DURATION = 0.35
local QUANTITY_COLOR = "rgb(100, 230, 100)"

local InventoryPopup = Roact.Component:extend("InventoryPopup")

function InventoryPopup:init()
	self.panelRef = Roact.createRef()
end

function InventoryPopup:didMount()
	local panel = self.panelRef:getValue()
	if panel == nil then return end

	local slideInTween = TweenService:Create(
		panel,
		TweenInfo.new(SLIDE_IN_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 0, 0, 0) }
	)
	slideInTween:Play()

	task.delay(POPUP_DURATION, function()
		if panel == nil or not panel.Parent then return end
		local slideOutTween = TweenService:Create(
			panel,
			TweenInfo.new(SLIDE_OUT_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(-1, 0, 0, 0) }
		)
		slideOutTween:Play()
	end)
end

--[[
	@param itemName: string
	@param amount: number
	@param popupWidth: number
	@param layoutOrder: number
]]
function InventoryPopup:render()
	local itemName = self.props.itemName
	local amount = self.props.amount
	local popupWidth = self.props.popupWidth or 200
	local layoutOrder = self.props.layoutOrder or 0

	local itemDef = ItemLookupService.GetItemDefinitionFromName(itemName) or {}
	local imageId = itemDef.imageId or "76280156712677"

	-- Derive pixel dimensions so layout is explicit
	local popupHeight = math.floor(popupWidth / 2.5)
	local contentHeight = popupHeight - 8  -- Panel insets 4px per side
	local iconSize = contentHeight
	local textGap = 6
	local textWidth = popupWidth - 8 - iconSize - textGap

	local quantityText = '<font color="' .. QUANTITY_COLOR .. '">+' .. tostring(amount) .. "</font>"

	-- Wrapper: fixed size + aspect ratio, clips so panel slides under the edge
	return createElement("Frame", {
		Size = UDim2.fromOffset(popupWidth, popupHeight),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = layoutOrder,
	}, {
		-- Panel starts off-screen left; tweened into view in didMount
		Panel = createElement(Panel, {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.new(-1, 0, 0, 0),
			[Roact.Ref] = self.panelRef,
		}, {
			IconFrame = createElement("Frame", {
				Size = UDim2.fromOffset(iconSize, iconSize),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				BackgroundTransparency = 1,
			}, {
				Icon = createElement("ImageLabel", {
					Image = "rbxassetid://" .. imageId,
					Size = UDim2.fromScale(0.85, 0.85),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
				}),
			}),

			TextFrame = createElement("Frame", {
				Size = UDim2.fromOffset(textWidth, contentHeight),
				Position = UDim2.fromOffset(iconSize + textGap, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
			}, {
				NameLabel = createElement(TextLabel, {
					Text = itemName,
					textSize = 13,
					Size = UDim2.new(1, 0, 0.5, 0),
					Position = UDim2.fromScale(0, 0),
					AnchorPoint = Vector2.new(0, 0),
					textProps = {
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextScaled = false,
					},
				}),
				QuantityLabel = createElement(TextLabel, {
					Text = quantityText,
					textSize = 12,
					Size = UDim2.new(1, 0, 0.5, 0),
					Position = UDim2.fromScale(0, 0.5),
					AnchorPoint = Vector2.new(0, 0),
					textProps = {
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextScaled = false,
					},
				}),
			}),
		}),
	})
end

return InventoryPopup
