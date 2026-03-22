local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local ProgressBar = require(script.Parent.ProgressBar)

local LevelBar = Roact.Component:extend("LevelBar")

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)
local NumberFormatter = require(utils.NumberFormatter)

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local ScreenContext = require(ModuleIndex.ScreenContext)

--[[
@param level: number
@param xp: number
@param Size: UDim2
]]
function LevelBar:render()
	local level = self.props.level
	local xp = self.props.xp
	local Size = self.props.Size
	
	local levelUpRequirement = StatCalculation.GetLevelUpXPRequirement(level)
	
	return Roact.createElement(ScreenContext.context.Consumer, {
		render = function(screenData)
			local isAtleast = screenData.IsAtleast
			local device = screenData.Device
			
			local barText = isAtleast("md") and NumberFormatter:GetFormattedLargeNumber(xp).." / "..NumberFormatter:GetFormattedLargeNumber(levelUpRequirement) or (math.floor(xp/levelUpRequirement*1000)/10).."%"
			
			local props = {
				progress = xp / levelUpRequirement,
				text = barText,
				textSize = 14,
				showPlusButton = false,
				showIcon = true,
				doAnimation = true,
				colorName = "blue",
				Position = UDim2.fromScale(0.2, 0.5),
				width = UDim.new(0.8, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				customIcon = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.7, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromScale(1.75, 1.75),
					SizeConstraint = Enum.SizeConstraint.RelativeYY
				}, {
					uIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
						DominantAxis = Enum.DominantAxis.Height,
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
							Text = level,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 20,
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
							Text = level,
							TextColor3 = Color3.fromRGB(0, 0, 0),
							TextSize = 20,
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
				})
			}

			return Roact.createElement("Frame", {
				Size = Size,
				BackgroundTransparency = 1
			}, {
				progressBar = Roact.createElement(ProgressBar, props)
			})
		end,
	})
end

return LevelBar