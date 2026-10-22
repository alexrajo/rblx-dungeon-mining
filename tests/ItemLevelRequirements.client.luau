-- Run in a local client playtest runner after player data and the character load.
-- Exercises the actual Roact components with isolated inventory and screen contexts.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
assert(RunService:IsStudio() and RunService:IsRunning(), "Run in a Studio playtest")

local player = Players.LocalPlayer
local gui = player.PlayerScripts.gui
local Roact = require(ReplicatedStorage.services.Roact)
local StoryUtils = require(gui.stories.StoryUtils)
local GearView = require(gui.components.InventoryPage.GearView)
local LoadoutView = require(gui.components.InventoryPage.LoadoutView)
local ShopPage = require(gui.pages.ShopPage)
local CraftingPage = require(gui.pages.CraftingPage)

local target = Instance.new("ScreenGui")
target.Name = "ItemLevelRegressionTest"
target.DisplayOrder = 1000
target.IgnoreGuiInset = true
target.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
target.Parent = player.PlayerGui

local stats = {
	Level = 1, Coins = 100,
	Inventory = {
		{ id = "test-pickaxe", name = "Iron Pickaxe" },
		{ id = "test-helmet", name = "Iron Helmet" },
		{ name = "Mega Bomb", value = 4 },
		{ name = "Strength Potion", value = 3 },
		{ name = "Iron", value = 20 }, { name = "Wood", value = 20 },
	},
}
local mountedInstance
local root
local renderTree
local checks = 0
local function check(condition: boolean, message: string)
	assert(condition, message)
	checks += 1
end
local function nextFrame()
	RunService.Heartbeat:Wait()
	RunService.Heartbeat:Wait()
end
local function captureClass(base)
	-- This bundled Roact exposes extend only on Component, but can copy a class for a test fixture.
	local testClass = Roact.Component.extend(base, "ItemLevelRegressionPreview")
	function testClass:init()
		base.init(self)
		mountedInstance = self
	end
	return testClass
end
local classes = { Gear = captureClass(GearView), Shop = captureClass(ShopPage), Craft = captureClass(CraftingPage) }

local function findText(text: string): TextLabel?
	for _, child in ipairs(target:GetDescendants()) do
		if child:IsA("TextLabel") and child.Text == text then return child end
	end
	return nil
end

local function countBadges(): number
	local count = 0
	for _, child in ipairs(target:GetDescendants()) do
		if child:IsA("TextLabel") and string.match(child.Text, "^Lv%. %d+$") then count += 1 end
	end
	return count
end

local function mount(kind: string, width: number, height: number, level: number)
	if root then Roact.unmount(root) end
	stats.Level = level
	local binding = Roact.createBinding(kind == "Shop" and "Shop" or "CraftingPage")
	local element = Roact.createElement(classes[kind], {
		Visible = true, currentPageBinding = binding, currentShopId = "GearShop", closeAllPages = function() end,
	})
	if kind == "Gear" then
		element = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.6, 0.56), Position = UDim2.fromScale(0.2, 0.22),
			BackgroundColor3 = Color3.fromRGB(15, 70, 120),
		}, { View = element })
	end
	renderTree = function()
		return Roact.createElement("Frame", {
			Size = UDim2.fromOffset(width, height), Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
		}, { Preview = StoryUtils.withMockContexts(element, {
			stats = stats, screen = { Size = width <= 750 and "xs" or "md" },
		}) })
	end
	root = Roact.mount(renderTree(), target)
	if kind == "Shop" or kind == "Craft" then
		-- PageWrapper normally animates on a closed-to-open transition.
		for _, child in ipairs(target:GetDescendants()) do
			if child:IsA("Frame") and child:FindFirstChild("Window") then child.Position = UDim2.fromScale(0, 0) end
		end
	end
	nextFrame()
end

local function getDropChecks(element, callbacks)
	if type(element) ~= "table" then return end
	if element.props and element.props.canDrop then table.insert(callbacks, element.props.canDrop) end
	for _, children in ipairs({ element.props and element.props[Roact.Children] or {}, element.elements or {} }) do
		for _, child in pairs(children) do getDropChecks(child, callbacks) end
	end
end

local ok, failure = xpcall(function()
	for _, dimensions in ipairs({ { 1400, 900 }, { 720, 480 } }) do
		mount("Gear", dimensions[1], dimensions[2], 1)
		check(countBadges() == 4, "All four locked inventory entries have badges")
		check(mountedInstance:getEquipActionState("Iron Pickaxe", stats).disabled, "Locked Equip is disabled")
		mountedInstance:setState({ selectedEntryId = "test-pickaxe", selectedItemName = "Iron Pickaxe" })
		nextFrame()
		local requirement = findText("Requires level 6 — Your level: 1")
		check(requirement ~= nil, "Inventory details show required and current levels")
		check(findText("Requires level 6") ~= nil, "Locked button explains required level")
		check(requirement.TextFits, "Requirement fits inventory details")
		local popup = target:FindFirstChild("Popup", true)
		check(popup ~= nil and popup.AbsoluteSize.X <= dimensions[1] and popup.AbsoluteSize.Y <= dimensions[2], "Popup fits screen")
		local statList = popup:FindFirstChild("Stats", true)
		local hint = popup:FindFirstChild("ActionHint", true)
		check(statList.AbsolutePosition.Y + statList.AbsoluteSize.Y <= hint.AbsolutePosition.Y,
			"Scrollable stats do not overlap the action hint")

		mount("Gear", dimensions[1], dimensions[2], 6)
		check(countBadges() == 1, "Eligible equipment and potions lose badges")
		check(not mountedInstance:getEquipActionState("Iron Pickaxe", stats).disabled, "Equip unlocks at exact level")
		mountedInstance:setState({ selectedEntryId = "test-pickaxe", selectedItemName = "Iron Pickaxe" })
		nextFrame()
		local unlocked = findText("Requires level 6 — Your level: 6")
		check(unlocked ~= nil and unlocked.TextColor3.G > unlocked.TextColor3.R, "Satisfied requirement is green")

		for _, kind in ipairs({ "Shop", "Craft" }) do
			mount(kind, dimensions[1], dimensions[2], 1)
			mountedInstance:setState(kind == "Shop" and { selectedItem = "Mega Bomb" }
				or { selectedRecipeName = "Iron Pickaxe" })
			nextFrame()
			local required = kind == "Shop" and 12 or 6
			local text = string.format("Requires level %d — Your level: 1\nYou can obtain this now and use it at level %d.", required, required)
			local label = findText(text)
			check(label ~= nil, kind .. " shows early-acquisition explanation")
			check(label.TextFits, kind .. " requirement fits")
			check(findText(kind == "Shop" and "BUY" or "CRAFT") ~= nil, kind .. " keeps acquisition action")
			local scrolling = label.Parent
			check(scrolling:IsA("ScrollingFrame") and scrolling.AbsoluteCanvasSize.Y >= scrolling.AbsoluteSize.Y,
				kind .. " details scroll on smaller screens")
		end
	end

	-- Check live level updates without remounting the inventory component.
	mount("Gear", 1400, 900, 1)
	mountedInstance:setState({ selectedEntryId = "test-pickaxe", selectedItemName = "Iron Pickaxe" })
	nextFrame()
	local originalInstance = mountedInstance
	local previousState = mountedInstance:getEquipActionState("Iron Pickaxe", stats)
	stats.Level = 6
	root = Roact.update(root, renderTree())
	nextFrame()
	check(mountedInstance == originalInstance and countBadges() == 1, "Live context updates badges without remounting")
	check(findText("Requires level 6 — Your level: 6") ~= nil, "Open popup updates with live level changes")
	check(previousState.disabled and not mountedInstance:getEquipActionState("Iron Pickaxe", stats).disabled,
		"Equip availability reads the current level")

	local fakeView = { props = {}, getCurrentArmorName = LoadoutView.getCurrentArmorName }
	local metrics = { hotbarSlotSize = 60, armorSlotSize = 60 }
	for _, level in ipairs({ 1, 6 }) do
		stats.Level = level
		local hotbarChecks, armorChecks = {}, {}
		getDropChecks(LoadoutView.renderHotbarColumn(fakeView, stats, metrics), hotbarChecks)
		getDropChecks(LoadoutView.renderArmorColumn(fakeView, stats, metrics), armorChecks)
		check(#hotbarChecks == 5 and #armorChecks == 4, "All loadout targets expose drop checks")
		for _, canDrop in ipairs(hotbarChecks) do
			check(canDrop({ itemName = "Iron Pickaxe" }) == (level >= 6), "Hotbar drops respect level")
		end
		local acceptingArmorSlots = 0
		for _, canDrop in ipairs(armorChecks) do
			if canDrop({ itemName = "Iron Helmet" }) then acceptingArmorSlots += 1 end
		end
		check(acceptingArmorSlots == (level >= 6 and 1 or 0), "Armor drops respect level and slot")
	end
end, debug.traceback)

if root then Roact.unmount(root) end
target:Destroy()
assert(ok, failure)
return { passed = checks, layouts = { "1400x900", "720x480" } }
