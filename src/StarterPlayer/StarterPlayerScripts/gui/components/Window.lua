local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local Window = Roact.Component:extend("Window")

function Window:render()
	local title = self.props.title
	local Position = self.props.Position
	local AnchorPoint = self.props.AnchorPoint
	local Size = self.props.Size or UDim2.fromScale(0.6, 0.7)
	
	if AnchorPoint == nil then AnchorPoint = Vector2.zero end
	
	local onExitButtonClicked = self.props.onExit
	local Visible = self.props.Visible
	
	return Roact.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = Position,
		AnchorPoint = AnchorPoint,
		Size = Size,
		Visible = Visible
	}, {
		uICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),

		uIStroke = Roact.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),

		background = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			shadow = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.8,
				Size = UDim2.new(1, 0, 1, 5),
			}, {
				uICorner1 = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),

			gradient = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 4,
			}, {
				imageLabel = Roact.createElement("ImageLabel", {
					Image = "rbxassetid://11953711609",
					ImageTransparency = 0.8,
					AnchorPoint = Vector2.new(0.5, 0.35),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0),
					Size = UDim2.fromScale(1.25, 1.25),
				}, {
					uIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint"),
				}),
			}),

			color = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(3, 54, 119),
				Position = UDim2.fromOffset(0, 4),
				Size = UDim2.new(1, 0, 1, -4),
				ZIndex = 3,
			}, {
				uICorner2 = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),

			highlight = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 86, 154),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, {
				uICorner3 = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
		}),

		content = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}, {
			header = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.fromScale(1, 0.2),
			}, {
				title = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				}, {
					text = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
					}, {
						textLabel = Roact.createElement("TextLabel", {
							FontFace = Font.new("rbxasset://fonts/families/LuckiestGuy.json"),
							Text = title,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 30,
							TextWrapped = true,
							AnchorPoint = Vector2.new(0.5, 0.45),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromScale(1, 1),
							ZIndex = 2,
						}, {
							uIStroke1 = Roact.createElement("UIStroke"),

							uITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
								MinTextSize = 9,
							}),
						}),

						textLabelStroke = Roact.createElement("TextLabel", {
							FontFace = Font.new("rbxasset://fonts/families/LuckiestGuy.json"),
							Text = title,
							TextColor3 = Color3.fromRGB(0, 0, 0),
							TextSize = 30,
							TextWrapped = true,
							AnchorPoint = Vector2.new(0.5, 0.45),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Position = UDim2.new(0.5, 0, 0.5, 3),
							Size = UDim2.fromScale(1, 1),
						}, {
							uITextSizeConstraint1 = Roact.createElement("UITextSizeConstraint", {
								MinTextSize = 9,
							}),
						}),
					}),
				}),

				gradient1 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.fromScale(1, 1),
				}, {
					imageLabel1 = Roact.createElement("ImageLabel", {
						Image = "rbxassetid://11953710574",
						ImageColor3 = Color3.fromRGB(0, 0, 0),
						ImageTransparency = 0.9,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
					}),
				}),

				uISizeConstraint = Roact.createElement("UISizeConstraint", {
					MaxSize = Vector2.new(math.huge, 70),
				}),
			}),

			body = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.2),
				Size = UDim2.fromScale(1, 0.8),
			}, self.props[Roact.Children]),
		}),

		close = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.7, 0.3),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromScale(0.11, 0.11),
			ZIndex = 3,
		}, {
			uIAspectRatioConstraint1 = Roact.createElement("UIAspectRatioConstraint", {
				DominantAxis = Enum.DominantAxis.Height,
			}),

			uISizeConstraint1 = Roact.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(36, 36),
				MinSize = Vector2.new(24, 24),
			}),

			exitButton = Roact.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				[Roact.Event.Activated] = onExitButtonClicked
			}, {
				uICorner4 = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),

				uIStroke2 = Roact.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),

				background1 = Roact.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, {
					color2 = Roact.createElement("Frame", {
						BackgroundColor3 = Color3.fromRGB(63, 58, 76),
						Size = UDim2.fromScale(1, 1),
						ZIndex = 2,
					}, {
						uICorner5 = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
					}),

					shadow1 = Roact.createElement("Frame", {
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.8,
						Size = UDim2.new(1, 0, 1, 3),
					}, {
						uICorner6 = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
					}),

					color1 = Roact.createElement("Frame", {
						BackgroundColor3 = Color3.fromRGB(88, 79, 105),
						Size = UDim2.new(1, 0, 1, -3),
						ZIndex = 3,
					}, {
						uICorner7 = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
					}),
				}),

				image = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				}, {
					imageLabel2 = Roact.createElement("ImageLabel", {
						Image = "rbxassetid://11953885530",
						AnchorPoint = Vector2.new(0.5, 0.6),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.6, 0.6),
						ZIndex = 2,
					}),

					uIAspectRatioConstraint2 = Roact.createElement("UIAspectRatioConstraint"),

					imageLabelStroke = Roact.createElement("ImageLabel", {
						Image = "rbxassetid://11953885530",
						ImageColor3 = Color3.fromRGB(0, 0, 0),
						AnchorPoint = Vector2.new(0.5, 0.6),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Position = UDim2.new(0.5, 0, 0.5, 2),
						Size = UDim2.fromScale(0.6, 0.6),
					}),
				}),
			}),
		}),
	})
end

return Window