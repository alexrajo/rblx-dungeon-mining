local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.services.Roact)
local GuiService = game:GetService("GuiService")

local createElement = Roact.createElement

local PageWrapper = Roact.Component:extend("PageWrapper")

local openTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local closeTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local topLeft, bottomRight = GuiService:GetGuiInset()
local closedPosition = UDim2.new(UDim.new(0, 0), UDim.new(-1, -topLeft.Y-16))

function PageWrapper:init()
	self.pageRef = Roact.createRef()
	self.movementTween = nil
end

--[[
	@param isOpen
]]
function PageWrapper:render()
	return createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = self.props.isOpen and 2 or 1,
		Position = closedPosition,
		[Roact.Ref] = self.pageRef
	}, self.props[Roact.Children])
end

function PageWrapper:didUpdate(prevProps, prevState)
	local page = self.pageRef:getValue()
	if page == nil or self.props.isOpen == prevProps.isOpen then return end
	
	if self.movementTween ~= nil then
		self.movementTween:Pause()
	end
	
	if self.props.isOpen then -- If the page is set to open
		self.movementTween = TweenService:Create(page, openTweenInfo, {Position = UDim2.fromScale(0, 0)})
	else
		self.movementTween = TweenService:Create(page, closeTweenInfo, {Position = closedPosition})
	end
	self.movementTween:Play()
end

return PageWrapper