local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local StoryUtils = require(script.Parent.StoryUtils)
local Button = require(ModuleIndex.Button)
local TextButton = require(ModuleIndex.TextButton)
local ActionButton = require(ModuleIndex.ActionButton)
local TextLabel = require(ModuleIndex.TextLabel)

local createElement = Roact.createElement

local function makeButtonCell(component, layoutOrder: number)
	return StoryUtils.makeCell(component, {
		layoutOrder = layoutOrder,
		size = UDim2.fromOffset(190, 100),
	})
end

function story(target: Frame)
	local component = StoryUtils.makeCanvas({
		Title = StoryUtils.makeLabel("Buttons", 1),
		TextButtons = StoryUtils.makeRow({
			Green = makeButtonCell(createElement(TextButton, {
				text = "MINE",
				size = "md",
				color = "green",
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				onClick = StoryUtils.noop,
			}), 1),
			Yellow = makeButtonCell(createElement(TextButton, {
				text = "CRAFT",
				size = "md",
				color = "yellow",
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				onClick = StoryUtils.noop,
			}), 2),
			Red = makeButtonCell(createElement(TextButton, {
				text = "SELL",
				size = "md",
				color = "red",
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				onClick = StoryUtils.noop,
			}), 3),
			Disabled = makeButtonCell(createElement(TextButton, {
				text = "LOCKED",
				size = "md",
				color = "green",
				disabled = true,
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}), 4),
		}, {
			layoutOrder = 2,
			size = UDim2.new(1, 0, 0, 100),
		}),
		IconButtons = StoryUtils.makeRow({
			PlainButton = makeButtonCell(createElement(Button, {
				size = "md",
				color = "green",
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				onClick = StoryUtils.noop,
			}, {
				Text = createElement(TextLabel, {
					Text = "OK",
					textSize = 20,
					Size = UDim2.fromScale(0.9, 0.9),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					textProps = {
						TextScaled = true,
					},
				}),
			}), 1),
			Action = makeButtonCell(createElement(ActionButton, {
				size = "xl",
				color = "yellow",
				imageId = "114615443431858",
				text = "BOMB",
				textSize = 14,
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				onClick = StoryUtils.noop,
			}), 2),
			ActionRed = makeButtonCell(createElement(ActionButton, {
				size = "xl",
				color = "red",
				imageId = "88490528639781",
				text = "POTION",
				textSize = 14,
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				onClick = StoryUtils.noop,
			}), 3),
		}, {
			layoutOrder = 3,
			size = UDim2.new(1, 0, 0, 100),
		}),
	})

	return StoryUtils.mount(target, component)
end

return story
