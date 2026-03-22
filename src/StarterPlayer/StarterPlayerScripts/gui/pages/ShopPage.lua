local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local PageWrapper = require(script.Parent.Parent.components.PageWrapper)
local Window = require(script.Parent.Parent.components.Window)
local TextButton = require(script.Parent.Parent.components.TextButton)

local ShopPage = Roact.Component:extend("ShopPage")

function ShopPage:render()
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()
	
	local function onExit()
		closeAllPages()
	end
	
	return createElement(PageWrapper, {isOpen = (currentPage == "Shop")}, {
		Window = createElement(Window, {title = "Shop", Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), onExit = onExit})
	})
end

return ShopPage
