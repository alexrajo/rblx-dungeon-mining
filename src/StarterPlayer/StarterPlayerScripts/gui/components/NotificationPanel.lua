local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local gui = script.Parent.Parent
local createElement = Roact.createElement
local ModuleIndex = require(gui.ModuleIndex)
local Panel = require(ModuleIndex.Panel)
local TextLabel = require(ModuleIndex.TextLabel)

local uiUtils = gui.utils
local Tweener = require(uiUtils.Tweener)

local NotificationPanel = Roact.Component:extend("NotificationPanel")

function NotificationPanel:init()
	self.ref = Roact.createRef()
end

function NotificationPanel:didMount()
	local panel = self.ref:getValue()
	if panel == nil then return end
	
	local duration = self.props.duration
	if not duration then 
		warn("No duration specified for NotificationPanel, using 3 seconds")
		duration = 3 
	end
	
	-- Tween panel in and out
	local tweener = Tweener.New(panel)
	tweener:FadeIn(0.5)
	task.wait(2)
	tweener:FadeOut(0.5)
end

function NotificationPanel:_renderLevelUpContent(level)
	return {
		Graphics = Roact.createElement("Frame", {
			Size = UDim2.new(0.2, -8, 0.95, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			BackgroundTransparency = 1
		}, {
			uIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				DominantAxis = Enum.DominantAxis.Height,
				AspectRatio = 1
			}),

			imageLabel = Roact.createElement("ImageLabel", {
				Image = "rbxassetid://11953924179",
				--ImageContent = Content.new(Content),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, {
				uIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(107, 227, 249)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(65, 145, 242)),
					}),
					Rotation = 90,
				}),
			}),

			imageLabelStroke = Roact.createElement("ImageLabel", {
				Image = "rbxassetid://11953924179",
				ImageColor3 = Color3.fromRGB(5, 25, 68),
				--ImageContent = Content.new(Content),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.new(0.5, 1, 0.5, 2),
				Size = UDim2.fromScale(1.04, 1.04),
			}),

			text = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 3,
			}, {
				textLabel = Roact.createElement("TextLabel", {
					FontFace = Font.new("rbxasset://fonts/families/LuckiestGuy.json"),
					Text = level or "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 28,
					AnchorPoint = Vector2.new(0.5, 0.45),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				}, {
					uIStroke = Roact.createElement("UIStroke"),

					uITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
						MinTextSize = 9,
					}),
				}),

				textLabelStroke = Roact.createElement("TextLabel", {
					FontFace = Font.new("rbxasset://fonts/families/LuckiestGuy.json"),
					Text = level or "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 28,
					AnchorPoint = Vector2.new(0.5, 0.45),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Position = UDim2.new(0.5, 0, 0.5, 3),
					Size = UDim2.fromScale(1, 1),
				}, {
					uITextSizeConstraint1 = Roact.createElement("UITextSizeConstraint", {
						MinTextSize = 9,
					}),
				}),
			}),
		}),
		Content = createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0.8, -16, 0.9, 0)
		}, {
			Title = createElement(TextLabel, {
				Text = self.title or "Level up!",
				textSize = 24,
				Size = UDim2.new(1, 0, 1, 0)
			})
		})
	}
end

function NotificationPanel:_renderInfoContent()
	return {
		Content = createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -16, 1, -16)
		}, {
			Title = createElement(TextLabel, {
				Text = self.title or "Information",
				textSize = 24,
				Size = UDim2.new(1, 0, 1, 0)
			})
		})
	}
end

function NotificationPanel:render()
	local passedProps = {}
	passedProps[Roact.Ref] = self.ref
	passedProps.Size = UDim2.new(0.4, 0, 0.2, 0)
	passedProps.AnchorPoint = self.props.AnchorPoint
	passedProps.Position = self.props.Position
	
	local notificationInfo = self.props.notification
	local notificationType = notificationInfo.Type
	self.title = notificationInfo.Title
	
	local level = notificationInfo.Level
	
	local content = notificationType == "levelup" and self:_renderLevelUpContent(level) or self:_renderInfoContent()
	
	return createElement(Panel, passedProps, content)
end

return NotificationPanel