local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local Services = ReplicatedStorage.services
local ItemLookupService = require(Services.ItemLookupService)

local createElement = Roact.createElement
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Panel = require(ModuleIndex.Panel)
local TextLabel = require(ModuleIndex.TextLabel)

local ItemCounter = Roact.Component:extend("ItemCounter")

--[[
	@param name
	@param amount
	@param amountOwned?
]]
function ItemCounter:render()
	local name = self.props.name
	local amount = self.props.amount
	local amountOwned = self.props.amountOwned
	local itemConfig = ItemLookupService.GetItemDefinitionFromName(name) or {}
	
	local useRedText = amountOwned ~= nil and amountOwned < amount
	local counterText = amountOwned ~= nil and tostring(amountOwned).." / "..tostring(amount) or tostring(amount) 
	
	local imageId = itemConfig.imageId or "76280156712677"

	return createElement(Panel, {}, {
		Icon = createElement("ImageLabel", {
			Image = "rbxassetid://"..imageId,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = amountOwned == nil and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.4),
			Size = amountOwned == nil and UDim2.new(0.75, 0, 0.75, 0) or UDim2.fromScale(0.65, 0.65),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ImageColor3 = amountOwned == 0 and Color3.fromRGB(203, 203, 203) or Color3.fromRGB(255, 255, 255)
		}, {
			UISizeConstraint = createElement("UISizeConstraint", {
				MaxSize = Vector2.new(64, 64)
			})	
		}),
		Counter = createElement(TextLabel, {
			Text = useRedText and '<font color="rgb(255, 30, 15)">'..counterText..'</font>' or counterText,
			textProps = {TextScaled = true, TextXAlignment = amountOwned == nil and Enum.TextXAlignment.Right or Enum.TextXAlignment.Center},
			Size = UDim2.fromScale(0.9, 0.2),
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(0.95, 0.95),
			ZIndex = 2,
		})
	})
end

return ItemCounter