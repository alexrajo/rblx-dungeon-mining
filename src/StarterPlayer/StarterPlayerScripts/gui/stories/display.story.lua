local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local StoryUtils = require(script.Parent.StoryUtils)
local Panel = require(ModuleIndex.Panel)
local ProgressBar = require(ModuleIndex.ProgressBar)
local TextLabel = require(ModuleIndex.TextLabel)

local createElement = Roact.createElement

function story(target: Frame)
	local component = StoryUtils.makeCanvas({
		Title = StoryUtils.makeLabel("Display", 1),
		Labels = StoryUtils.makeRow({
			Plain = StoryUtils.makeCell(createElement(TextLabel, {
				Text = "Dungeon Mining",
				textSize = 22,
				Size = UDim2.fromScale(1, 1),
				textProps = {
					TextScaled = true,
				},
			}), {
				layoutOrder = 1,
				size = UDim2.fromOffset(220, 80),
			}),
			Rich = StoryUtils.makeCell(createElement(TextLabel, {
				Text = 'Need <font color="rgb(255, 30, 15)">12</font> copper',
				textSize = 18,
				Size = UDim2.fromScale(1, 1),
				textProps = {
					TextScaled = true,
				},
			}), {
				layoutOrder = 2,
				size = UDim2.fromOffset(260, 80),
			}),
		}, {
			layoutOrder = 2,
			size = UDim2.new(1, 0, 0, 80),
		}),
		Panels = StoryUtils.makeRow({
			Panel = StoryUtils.makeCell(createElement(Panel, {
				Size = UDim2.fromScale(1, 1),
			}, {
				Text = createElement(TextLabel, {
					Text = "Panel Content",
					textSize = 18,
					Size = UDim2.fromScale(1, 1),
					textProps = {
						TextScaled = true,
					},
				}),
			}), {
				layoutOrder = 1,
				size = UDim2.fromOffset(260, 100),
				backgroundTransparency = 1,
			}),
			Square = StoryUtils.makeCell(createElement(Panel, {
				Size = UDim2.fromScale(1, 1),
				aspectRatio = 1,
			}, {
				Text = createElement(TextLabel, {
					Text = "1:1",
					textSize = 20,
					Size = UDim2.fromScale(1, 1),
				}),
			}), {
				layoutOrder = 2,
				size = UDim2.fromOffset(110, 110),
				backgroundTransparency = 1,
			}),
		}, {
			layoutOrder = 3,
			size = UDim2.new(1, 0, 0, 110),
		}),
		Bars = StoryUtils.makeRow({
			Green = StoryUtils.makeCell(createElement(ProgressBar, {
				progress = 0.72,
				text = "HP: 72 / 100",
				colorName = "green",
				width = UDim.new(0, 220),
				height = UDim.new(0, 30),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}), {
				layoutOrder = 1,
				size = UDim2.fromOffset(270, 80),
			}),
			Blue = StoryUtils.makeCell(createElement(ProgressBar, {
				progress = 0.38,
				text = "XP: 380 / 1000",
				colorName = "blue",
				width = UDim.new(0, 220),
				height = UDim.new(0, 30),
				showIcon = true,
				iconImageId = "11953924179",
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}), {
				layoutOrder = 2,
				size = UDim2.fromOffset(270, 80),
			}),
			Red = StoryUtils.makeCell(createElement(ProgressBar, {
				progress = 0.18,
				text = "Low Health",
				colorName = "red",
				width = UDim.new(0, 220),
				height = UDim.new(0, 30),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}), {
				layoutOrder = 3,
				size = UDim2.fromOffset(270, 80),
			}),
		}, {
			layoutOrder = 4,
			size = UDim2.new(1, 0, 0, 80),
		}),
	})

	return StoryUtils.mount(target, component)
end

return story
