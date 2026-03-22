local plr = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local PageWrapper = require(ModuleIndex.PageWrapper)
local Window = require(ModuleIndex.Window)
local ResourcesView = require(ModuleIndex.InventoryResourcesView)
local GearView = require(ModuleIndex.InventoryGearView)
local Tab = require(ModuleIndex.Tab)

local StatsContext = require(ModuleIndex.StatsContext)

local InventoryPage = Roact.Component:extend("InventoryPage")

local TAB_NAMES = {"Resources", "Gear"}

function InventoryPage:init()
	self:setState({
		currentView = TAB_NAMES[1]
	})
end

function InventoryPage:render()
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()

	local currentView = self.state.currentView

	local tabComponents = {}
	for i, tabName in ipairs(TAB_NAMES) do
		local component = createElement(Tab, {
			text = tabName,
			selected = currentView == tabName,
			LayoutOrder = i,
			xSize = UDim.new(0.4, 0),
			onClick = function()
				self:setState({
					currentView = tabName
				})
			end,
		})
		table.insert(tabComponents, component)
	end

	local function onExit()
		closeAllPages()
	end

	return createElement(PageWrapper, {isOpen = (currentPage == "Inventory")}, {
		Tabs = createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Size = UDim2.fromScale(0.6, 0.1),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0.15, 0)
		}, {
			uIListLayout = createElement("UIListLayout", {
				Padding = UDim.new(0, 5),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			TabComponents = Roact.createFragment(tabComponents)
		}),
		Window = createElement(Window, {title = "Inventory", Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.7), AnchorPoint = Vector2.new(0.5, 0.5), onExit = onExit}, {
			ResourcesView = createElement(ResourcesView, {Visible = currentView == "Resources"}),
			GearView = createElement(GearView, {Visible = currentView == "Gear"})
		})
	})
end

return InventoryPage
