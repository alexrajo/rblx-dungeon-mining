local plr = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local Maid = require(Services.Maid)
local APIService = require(Services.APIService)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local PageWrapper = require(ModuleIndex.PageWrapper)
local Window = require(ModuleIndex.Window)
local TextButton = require(ModuleIndex.TextButton)
local ProgressBar = require(ModuleIndex.ProgressBar)
local TextLabel = require(ModuleIndex.TextLabel)

local FactoryPage = Roact.Component:extend("StatsPage")

local upgradeFunc = APIService.GetFunction("Upgrade")

local dataUpdateMaid = Maid.new()

function FactoryPage:init()
	self:setState({})
end

function FactoryPage:willUnmount()
	dataUpdateMaid:Destroy()
end

function FactoryPage:render()
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()

	local function onExit()
		closeAllPages()
	end
	
	return createElement(PageWrapper, {isOpen = (currentPage == "Factory")}, {
		Window = createElement(Window, {title = "Factory", Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), onExit = onExit}, {
			UIListLayout = createElement("UIListLayout", {VerticalFlex = Enum.UIFlexAlignment.SpaceAround, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 5), FillDirection = Enum.FillDirection.Vertical}),
			Progress = createElement("Frame", {
				Size = UDim2.new(1, -10, 0.3, -10),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1}, {
				Title = createElement(TextLabel, {
					Text = "Production",
					Size = UDim2.new(1, 0, 0.5, -5),
					textSize = 16
				}),
				Bar = createElement(ProgressBar, {
					width = UDim.new(1, 0),
					progress = 0.5,
					text = "745,544",
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0)
				})
			}),
			UpgradeButton = createElement(TextButton, {
				size = "md",
				text = "Upgrade",
				Position = UDim2.fromScale(0.5, 1),
				AnchorPoint = Vector2.new(0.5, 1),
				color = "yellow",
				onClick = function(rbx)
					if upgradeFunc == nil then return end
					upgradeFunc:InvokeServer()
				end
			})
		})
	})
end

return FactoryPage
