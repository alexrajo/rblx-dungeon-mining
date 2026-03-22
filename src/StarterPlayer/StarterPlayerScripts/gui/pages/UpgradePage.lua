local plr = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local PageWrapper = require(ModuleIndex.PageWrapper)
local Window = require(ModuleIndex.Window)
local TextButton = require(ModuleIndex.TextButton)
local ProgressBar = require(ModuleIndex.ProgressBar)
local TextLabel = require(ModuleIndex.TextLabel)

local StatsContext = require(ModuleIndex.StatsContext)

local UpgradePage = Roact.Component:extend("UpgradePage")

function UpgradePage:render()
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()
	
	local function onExit()
		closeAllPages()
	end
	
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			return createElement(PageWrapper, {isOpen = (currentPage == "UpgradePage")}, {
				Window = createElement(Window, {title = "Upgrade", Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), onExit = onExit}, {
					BurpPoints = createElement("Frame", {
						Size = UDim2.fromScale(1, 0.3),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1
					}, {
						Title = createElement(TextLabel, {
							Text = "Burp points",
							Size = UDim2.new(1, 0, 0.5, -5),
							textSize = 16
						}),
						Counter = createElement(TextLabel, {
							Text = data.BurpPoints,
							Size = UDim2.new(1, 0, 0.5, -5),
							Position = UDim2.new(0, 0, 0.5, 5),
							textSize = 24
						})
					}),
				})
			})
		end
	})
end

return UpgradePage
