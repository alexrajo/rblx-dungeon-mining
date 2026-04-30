local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local ProgressBar = Roact.Component:extend("ProgressBar")

local COLORS = {
	green = {
		foregroundTop = Color3.fromRGB(79, 213, 2),
		foregroundBottomBegin = Color3.fromRGB(51, 172, 41),
		foregroundBottomEnd = Color3.fromRGB(66, 192, 24)
	},
	yellow = {
		foregroundTop = Color3.fromRGB(255, 219, 49),
		foregroundBottomBegin = Color3.fromHex("#F7A013"),
		foregroundBottomEnd = Color3.fromHex("#FFC026")
	},
	orange = {
		foregroundTop = Color3.fromRGB(255, 117, 28),
		foregroundBottomBegin = Color3.fromRGB(224, 118, 43),
		foregroundBottomEnd = Color3.fromRGB(224, 134, 64),
	},
	red = {
		foregroundTop = Color3.fromRGB(255, 102, 102),
		foregroundBottomBegin = Color3.fromRGB(219, 61, 61),
		foregroundBottomEnd = Color3.fromRGB(235, 85, 85),
	},
	blue = {
		foregroundTop = Color3.fromRGB(46, 185, 254),
		foregroundBottomBegin = Color3.fromRGB(33, 127, 254),
		foregroundBottomEnd = Color3.fromRGB(38, 159, 255),
	}
}

function ProgressBar:init()
	self.barRef = Roact.createRef()
end

function ProgressBar:didUpdate(prevProps)
	-- Check if the progress prop has changed and animation is enabled
	if self.props.doAnimation == true and prevProps.progress ~= self.props.progress then
		self:tweenProgress(prevProps)
	end
end


function ProgressBar:tweenProgress(prevProps)
	local bar = self.barRef:getValue()
	if bar then
		bar.Size = UDim2.new(prevProps.progress, 0, bar.Size.Y.Scale, bar.Size.Y.Offset)
		
		-- Create a tween for the size property of the bar
		local tween = game:GetService("TweenService"):Create(bar, TweenInfo.new(0.25), {
			Size = UDim2.new(self.props.progress, 0, 1, 0)
		})
		tween:Play()
	end
end


--[[
	@param progress: number - from 0 to 1 indicating how filled the bar is
	@param colorName: string (options: "green") - string indicating which colors used to fill progress bar (default "green")
	@param text - the text to display on the progress bar
	@param textSize?: number - the font size (default 17)
	@param width?: UDim - the UDim width of the progress bar
	@param height?: UDim - the UDim height of the progress bar
	@param showPlusButton?: boolean - whether to show the plus button (default false)
	@param showIcon?: boolean - whether to show the icon (default false)
	@param iconImageId?: string | number - the id of the icon image (default 12186064862)
	@param customIcon?: Frame - a custom icon frame
	@param Position: Udim2 - position of the component
	@param AnchorPoint: Vector2 - anchor point of the component
	@param doAnimation?: boolean - whether to use tweens when updating progress (default false)
    @param autoScaleText?: boolean - whether to scale text automatically
]]
function ProgressBar:render()
	local width = self.props.width
	if width == nil then
		width = UDim.new(0, 150)
	end
	
	local height = self.props.height
	if height == nil then
		height = UDim.new(0, 25)
	end
	
	local textSize = self.props.textSize
	if textSize == nil then
		textSize = 17
	end
	
	local showPlusButton = self.props.showPlusButton == true
	local showIcon = self.props.showIcon == true
	local iconImageId = self.props.iconImageId or "12186064862"
	local customIcon = self.props.customIcon
	local colorName = self.props.colorName or "green"
	local color: {foregroundTop: Color3, foregroundBottomBegin: Color3, foregroundBottomEnd: Color3} = COLORS[colorName] or COLORS.green
	
	return Roact.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		LayoutOrder = self.props.LayoutOrder,
		Size = UDim2.new(width, height),
		Position = self.props.Position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = self.props.AnchorPoint or Vector2.new(0, 0)
	}, {
		text = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 4,
		}, {
			textLabel = Roact.createElement("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/LuckiestGuy.json"),
				Text = self.props.text,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = textSize,
				AnchorPoint = Vector2.new(0.5, 0.45),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 0.8),
				ZIndex = 2,
                TextScaled = self.props.autoScaleText,
			}, {
				uIStroke = Roact.createElement("UIStroke"),

				uITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
					MinTextSize = 9,
				}),
			}),

			textLabelStroke = Roact.createElement("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/LuckiestGuy.json"),
				Text = self.props.text,
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = textSize,
				AnchorPoint = Vector2.new(0.5, 0.45),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0.5, 3),
				Size = UDim2.fromScale(1, 0.8),
                TextScaled = self.props.autoScaleText,
			}, {
				uITextSizeConstraint1 = Roact.createElement("UITextSizeConstraint", {
					MinTextSize = 9,
				}),
			}),
		}),

		extras = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 3,
			Visible = showPlusButton or showIcon
		}, {
			image = customIcon or Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 3, 0.5, 0),
				Size = UDim2.new(1, -3, 1, -6),
				Visible = showIcon
			}, {
				imageLabel = Roact.createElement("ImageLabel", {
					Image = "rbxassetid://"..iconImageId,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				}),

				uIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
					DominantAxis = Enum.DominantAxis.Height,
				}),

				imageLabelStroke = Roact.createElement("ImageLabel", {
					Image = "rbxassetid://"..iconImageId,
					ImageColor3 = Color3.fromRGB(0, 0, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, 2, 1, 2),
				}),
			}),
			
			button = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.1, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromScale(1, 1.2),
				Visible = showPlusButton
			}, {
				uIAspectRatioConstraint1 = Roact.createElement("UIAspectRatioConstraint", {
					DominantAxis = Enum.DominantAxis.Height,
				}),

				imageButton = Roact.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
				}, {
					uICorner = Roact.createElement("UICorner"),

					uIStroke1 = Roact.createElement("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),

					image1 = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						ZIndex = 2,
					}, {
						imageLabel1 = Roact.createElement("ImageLabel", {
							Image = "rbxassetid://12184554010",
							AnchorPoint = Vector2.new(0.5, 0.6),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromScale(0.6, 0.6),
							ZIndex = 3,
						}),

						uIAspectRatioConstraint2 = Roact.createElement("UIAspectRatioConstraint"),

						imageLabelStroke1 = Roact.createElement("ImageLabel", {
							Image = "rbxassetid://12184554010",
							ImageColor3 = Color3.fromRGB(0, 0, 0),
							AnchorPoint = Vector2.new(0.5, 0.6),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.new(0.6, 2, 0.6, 2),
							ZIndex = 2,
						}),

						imageLabelStroke2 = Roact.createElement("ImageLabel", {
							Image = "rbxassetid://12184554010",
							ImageColor3 = Color3.fromRGB(0, 0, 0),
							AnchorPoint = Vector2.new(0.5, 0.6),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Position = UDim2.new(0.5, 1, 0.5, 2),
							Size = UDim2.fromScale(0.6, 0.6),
						}),
					}),

					background = Roact.createElement("Frame", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
					}, {
						color2 = Roact.createElement("Frame", {
							BackgroundColor3 = Color3.fromRGB(83, 121, 20),
							Size = UDim2.fromScale(1, 1),
							ZIndex = 2,
						}, {
							uICorner1 = Roact.createElement("UICorner"),
						}),

						shadow = Roact.createElement("Frame", {
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							BackgroundTransparency = 0.8,
							Size = UDim2.new(1, 0, 1, 3),
						}, {
							uICorner2 = Roact.createElement("UICorner"),
						}),

						color1 = Roact.createElement("Frame", {
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, -3),
							ZIndex = 3,
						}, {
							bottom = Roact.createElement("Frame", {
								AnchorPoint = Vector2.new(0.5, 1),
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								Position = UDim2.fromScale(0.5, 1),
								Size = UDim2.fromScale(1, 0.7),
							}, {
								uICorner3 = Roact.createElement("UICorner"),

								uIGradient = Roact.createElement("UIGradient", {
									Color = ColorSequence.new({
										ColorSequenceKeypoint.new(0, Color3.fromRGB(87, 144, 15)),
										ColorSequenceKeypoint.new(1, Color3.fromRGB(104, 170, 17)),
									}),
									Rotation = 90,
								}),
							}),

							top = Roact.createElement("Frame", {
								AnchorPoint = Vector2.new(0.5, 0),
								BackgroundColor3 = Color3.fromRGB(176, 223, 24),
								Position = UDim2.fromScale(0.5, 0),
								Size = UDim2.fromScale(1, 0.5),
								ZIndex = 2,
							}, {
								uICorner4 = Roact.createElement("UICorner"),
							}),
						}),
					}),
				}),
			}),
		}),

		background1 = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			shadow1 = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.8,
				Size = UDim2.new(1, 0, 1, 3),
			}, {
				uICorner5 = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
			}),

			color = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(15, 42, 115),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, {
				uICorner6 = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),

				uIStroke2 = Roact.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}),
		}),

		foreground = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 3,
		}, {
			bar = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(self.props.progress or 0, 1),
				[Roact.Ref] = self.barRef
			}, {
				color1 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, {
					bottom1 = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0.5, 1),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						Position = UDim2.fromScale(0.5, 1),
						Size = UDim2.fromScale(1, 0.7),
					}, {
						uIGradient1 = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, color.foregroundBottomBegin),
								ColorSequenceKeypoint.new(1, color.foregroundBottomEnd),
							}),
							Rotation = 90,
						}),

						uICorner7 = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
					}),

					top1 = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = color.foregroundTop,
						Position = UDim2.fromScale(0.5, 0),
						Size = UDim2.fromScale(1, 0.5),
						ZIndex = 2,
					}, {
						uICorner8 = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
					}),
				}),
			}),

			divisions = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				Visible = false,
				ZIndex = 2,
			}, {
				line10 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 1,
					Position = UDim2.fromScale(0.1, 0),
					Size = UDim2.new(0, 1, 1, 0),
				}),

				line20 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 2,
					Position = UDim2.fromScale(0.2, 0),
					Size = UDim2.new(0, 1, 1, 0),
				}),

				line30 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 3,
					Position = UDim2.fromScale(0.3, 0),
					Size = UDim2.new(0, 1, 1, 0),
				}),

				line40 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 4,
					Position = UDim2.fromScale(0.4, 0),
					Size = UDim2.new(0, 1, 1, 0),
				}),

				line50 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 5,
					Position = UDim2.fromScale(0.5, 0),
					Size = UDim2.new(0, 1, 1, 0),
				}),

				line60 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 6,
					Position = UDim2.fromScale(0.6, 0),
					Size = UDim2.new(0, 1, 1, 0),
				}),

				line70 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 7,
					Position = UDim2.fromScale(0.7, 0),
					Size = UDim2.new(0, 1, 1, 0),
				}),

				line80 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 8,
					Position = UDim2.fromScale(0.8, 0),
					Size = UDim2.new(0, 1, 1, 0),
				}),

				line90 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 9,
					Position = UDim2.fromScale(0.9, 0),
					Size = UDim2.new(0, 1, 1, 0),
				}),
			}),
		}),
	})
end

return ProgressBar
