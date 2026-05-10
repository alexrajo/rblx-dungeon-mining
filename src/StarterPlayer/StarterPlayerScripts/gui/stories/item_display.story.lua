local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local StoryUtils = require(script.Parent.StoryUtils)
local ItemCounter = require(ModuleIndex.ItemCounter)

local createElement = Roact.createElement

local function makeCounter(name: string, amount: number, amountOwned: number?, layoutOrder: number)
	return StoryUtils.makeCell(createElement(ItemCounter, {
		name = name,
		amount = amount,
		amountOwned = amountOwned,
		Size = UDim2.fromScale(1, 1),
	}), {
		layoutOrder = layoutOrder,
		size = UDim2.fromOffset(96, 96),
		backgroundTransparency = 1,
	})
end

function story(target: Frame)
	local component = StoryUtils.makeCanvas({
		Title = StoryUtils.makeLabel("Item Display", 1),
		Counters = StoryUtils.makeRow({
			Enough = makeCounter("Wood Pickaxe", 1, nil, 1),
			Owned = makeCounter("Mini Bomb", 12, 20, 2),
			Missing = makeCounter("Health Potion", 8, 3, 3),
			Fallback = makeCounter("Mystery Ore", 99, nil, 4),
		}, {
			layoutOrder = 2,
			size = UDim2.new(1, 0, 0, 100),
		}),
	})

	return StoryUtils.mount(target, component)
end

return story
