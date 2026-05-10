local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local StoryUtils = require(script.Parent.StoryUtils)

StoryUtils.ensureMockApiEvents({
	"EquipGear",
	"AssignHotbarSlot",
	"ClearHotbarSlot",
	"ClearEquippedGear",
})

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local InventoryPage = require(script.Parent.Parent.pages.InventoryPage)
local ResourcesView = require(ModuleIndex.InventoryResourcesView)
local GearView = require(ModuleIndex.InventoryGearView)

local createElement = Roact.createElement

local MOCK_STATS = {
	Coins = 1840,
	Level = 12,
	XP = 625,
	MaxFloorReached = 37,
	LatestCheckpointFloor = 35,
	Inventory = {
		{name = "Stone", value = 128},
		{name = "Copper", value = 64},
		{name = "Iron", value = 36},
		{name = "Gold", value = 14},
		{name = "Diamond", value = 3},
		{name = "Wood", value = 22},
		{name = "Slime Gel", value = 9},
		{name = "Bat Wing", value = 5},
		{name = "Mini Bomb", value = 6},
		{name = "Health Potion", value = 4},
		{id = "gear_wood_pickaxe", name = "Wood Pickaxe"},
		{id = "gear_iron_pickaxe", name = "Iron Pickaxe"},
		{id = "gear_copper_sword", name = "Copper Sword"},
		{id = "gear_iron_sword", name = "Iron Sword"},
		{id = "gear_copper_helmet", name = "Copper Helmet"},
		{id = "gear_iron_helmet", name = "Iron Helmet"},
		{id = "gear_copper_chestplate", name = "Copper Chestplate"},
		{id = "gear_copper_leggings", name = "Copper Leggings"},
		{id = "gear_iron_boots", name = "Iron Boots"},
		{id = "gear_gold_boots", name = "Gold Boots"},
	},
	EquippedHelmet = "gear_copper_helmet",
	EquippedChestplate = "gear_copper_chestplate",
	EquippedLeggings = "gear_copper_leggings",
	EquippedBoots = "gear_iron_boots",
	HotbarSlots = {
		{name = "1", value = "gear_wood_pickaxe"},
		{name = "2", value = "gear_copper_sword"},
		{name = "3", value = "Mini Bomb"},
		{name = "4", value = "Health Potion"},
		{name = "5", value = ""},
	},
	SelectedHotbarSlot = 1,
	CurrentFloor = 24,
	InMine = true,
}

local InventoryStory = Roact.Component:extend("InventoryStory")

function InventoryStory:init()
	self:setState({
		currentPage = "",
	})
end

function InventoryStory:didMount()
	task.defer(function()
		self:setState({
			currentPage = "Inventory",
		})
	end)
end

function InventoryStory:render()
	local currentPageBinding = {
		getValue = function()
			return self.state.currentPage
		end,
	}

	return StoryUtils.withMockContexts(StoryUtils.makeCanvas({
		Title = StoryUtils.makeLabel("Inventory", 1),
		FullPage = createElement("Frame", {
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 360),
		}, {
			InventoryPage = createElement(InventoryPage, {
				currentPageBinding = currentPageBinding,
				closeAllPages = StoryUtils.noop,
			}),
		}),
		FocusedViews = StoryUtils.makeRow({
			Resources = StoryUtils.makeCell(createElement(ResourcesView, {
				Visible = true,
				Size = UDim2.fromScale(1, 1),
			}), {
				layoutOrder = 1,
				size = UDim2.new(0, 420, 0, 300),
				backgroundColor = Color3.fromRGB(7, 18, 31),
			}),
			Gear = StoryUtils.makeCell(createElement(GearView, {
				Visible = true,
				Size = UDim2.fromScale(1, 1),
			}), {
				layoutOrder = 2,
				size = UDim2.new(0, 560, 0, 300),
				backgroundColor = Color3.fromRGB(7, 18, 31),
			}),
		}, {
			layoutOrder = 3,
			size = UDim2.new(1, 0, 0, 300),
			spacing = 18,
		}),
	}, {
		spacing = 18,
	}), {
		stats = MOCK_STATS,
		screen = {
			Size = "lg",
			Device = "computer",
		},
	})
end

function story(target: Frame)
	return StoryUtils.mount(target, createElement(InventoryStory))
end

return story
