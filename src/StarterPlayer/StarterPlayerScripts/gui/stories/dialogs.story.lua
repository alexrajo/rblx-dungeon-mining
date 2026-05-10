local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local StoryUtils = require(script.Parent.StoryUtils)
local ConfirmationModal = require(ModuleIndex.ConfirmationModal)
local GearDetailPopup = require(script.Parent.Parent.components.InventoryPage.GearDetailPopup)
local InventoryPopup = require(ModuleIndex.InventoryPopup)
local SellConfirmationDialog = require(ModuleIndex.SellConfirmationDialog)
local TextLabel = require(ModuleIndex.TextLabel)
local Window = require(ModuleIndex.Window)

local createElement = Roact.createElement

local gearDetails = {
	name = "Iron Sword",
	imageId = "111950185917024",
	equippedText = "Equipped",
	primaryStatText = "Damage: 18",
	description = "A sturdy blade for deeper mine floors.",
	detailLines = {
		"Cooldown: 0.48s",
		"Critical chance: 10%",
		"Knockback: 56",
	},
}

function story(target: Frame)
	local component = StoryUtils.makeCanvas({
		Title = StoryUtils.makeLabel("Dialogs and Popups", 1),
		WindowPreview = createElement("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Size = UDim2.fromOffset(420, 260),
		}, {
			Window = createElement(Window, {
				title = "INVENTORY",
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(0, 0),
				Visible = true,
				onExit = StoryUtils.noop,
			}, {
				Body = createElement(TextLabel, {
					Text = "Window body content",
					textSize = 18,
					Size = UDim2.fromScale(1, 1),
					textProps = {
						TextScaled = true,
					},
				}),
			}),
		}),
		Dialogs = StoryUtils.makeRow({
			Confirm = StoryUtils.makeCell(createElement(ConfirmationModal, {
				visible = true,
				title = "Craft item?",
				message = "Spend these resources to craft an Iron Sword?",
				confirmText = "CRAFT",
				cancelText = "CANCEL",
				onConfirm = StoryUtils.noop,
				onCancel = StoryUtils.noop,
			}), {
				layoutOrder = 1,
				size = UDim2.fromOffset(340, 220),
				backgroundColor = Color3.fromRGB(7, 18, 31),
			}),
			Sell = StoryUtils.makeCell(createElement(SellConfirmationDialog, {
				visible = true,
				itemName = "Copper Ore",
				quantity = 24,
				totalValue = 360,
				onConfirm = StoryUtils.noop,
				onCancel = StoryUtils.noop,
			}), {
				layoutOrder = 2,
				size = UDim2.fromOffset(280, 220),
				backgroundColor = Color3.fromRGB(7, 18, 31),
			}),
			Gear = StoryUtils.makeCell(createElement(GearDetailPopup, {
				details = gearDetails,
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				primaryButtonText = "EQUIP",
				actionHintText = "Equipping replaces the current weapon.",
				onPrimaryAction = StoryUtils.noop,
				onClose = StoryUtils.noop,
			}), {
				layoutOrder = 3,
				size = UDim2.fromOffset(300, 260),
				backgroundColor = Color3.fromRGB(7, 18, 31),
			}),
		}, {
			layoutOrder = 3,
			size = UDim2.new(1, 0, 0, 260),
		}),
		Popup = StoryUtils.makeRow({
			InventoryPopup = createElement(InventoryPopup, {
				itemName = "Diamond Pickaxe",
				amount = 1,
				popupWidth = 240,
				layoutOrder = 1,
			}),
		}, {
			layoutOrder = 4,
			size = UDim2.new(1, 0, 0, 110),
		}),
	}, {
		spacing = 18,
	})

	return StoryUtils.mount(target, component)
end

return story
