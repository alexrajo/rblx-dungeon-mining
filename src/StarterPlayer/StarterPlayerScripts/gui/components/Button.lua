local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local Button = Roact.Component:extend("Button")

local SIZES = {
	["xs-square"] = {
		container = UDim2.fromOffset(20, 20),
	},
	["sm-square"] = {
		container = UDim2.fromOffset(30, 30),
	},
	["md-square"] = {
		container = UDim2.fromOffset(50, 50),
	},
	["lg-square"] = {
		container = UDim2.fromOffset(60, 60),
	},
	["xl-square"] = {
		container = UDim2.fromOffset(80, 80),
	},
	["2xl-square"] = {
		container = UDim2.fromOffset(100, 100),
	},
	["3xl-square"] = {
		container = UDim2.fromOffset(140, 140),
	},
	xs = {
		container = UDim2.fromOffset(90, 30)
	},
	sm = {
		container = UDim2.fromOffset(120, 40)
	},
	md = {
		container = UDim2.fromOffset(150, 50),
	},
	lg = {
		container = UDim2.fromOffset(180, 60),
	},
}

local COLORS = {
	green = {
		primary = "#33ac29", -- Color1 - Bottom - Gradient start
		secondary = "#42c018", -- Color1 - Bottom - Gradient end
		tertiary = "#4fd502", -- Color1 - Top
		quaternary = "#1d7e02", -- Color2
	},
	red = {
		primary = "#b91616",
		secondary = "#d71a1a",
		tertiary = "#ff3232",
		quaternary = "#9c1313",
	},
	gray = {
		primary = "#525252",
		secondary = "#696969",
		tertiary = "#858585",
		quaternary = "#454545",
	},
	yellow = {
		primary = "#d9c729",
		secondary = "#e8d423",
		tertiary = "#f7e64f",
		quaternary = "#c29f02",
	}
}

local CLICK_SOUND_ID = 1897534957

local onHoverBeginTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local onHoverEndTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

function Button:init()
	self.clickSoundRef = Roact.createRef()
	self.hoverElementRef = Roact.createRef()
	self.hoverTweens = {}
	
	self:setState({
		isPressedDown = false
	})
end

--[[
	@param size
	@param customSize
	@param color
	@param AnchorPoint
	@param Position
 	@param onClick
 	@param disabled?
 	@param disableHoverScaleTween?
]]
function Button:render()
	
	local size: string = self.props.size
	local customSize: UDim2 | nil = self.props.customSize
	
	local buttonSize = customSize or (size and SIZES[size].container)
	local isDisabled = self.props.disabled
	local disableHoverScaleTween = self.props.disableHoverScaleTween == true
	
	-- Colors
	local color: {primary: string, secondary: string, tertiary: string, quaternary: string} = isDisabled and COLORS["gray"] or COLORS[self.props.color]
	local primaryColor = Color3.fromHex(color.primary)
	local secondaryColor = Color3.fromHex(color.secondary)
	local tertiaryColor = Color3.fromHex(color.tertiary)
	local quaternaryColor = Color3.fromHex(color.quaternary)
	
	local function cancelHoverTweenInPlace()
		for _, tween in pairs(self.hoverTweens) do
			if tween ~= nil then
				tween:Pause()
			end
		end
		self.hoverTweens = {}
	end
	
	local function onClick(rbxInstance)
		if self.props.onClick ~= nil then
			self.props.onClick()
		end
	end
	
	local function onPressDown(rbxInstance)
		self:setState({isPressedDown = true})
		local clickSound = self.clickSoundRef:getValue()
		if clickSound ~= nil then
			clickSound:Play()
		end
	end
	
	local function onPressUp(rbxInstance)
		self:setState({isPressedDown = false})
	end
	
	local function onHoverBegin(rbxInstance)
		cancelHoverTweenInPlace()
		local hoverInstance = self.hoverElementRef:getValue()
		if hoverInstance ~= nil then
			local tween = TweenService:Create(hoverInstance, onHoverBeginTweenInfo, {
				Size = UDim2.fromScale(1, 0.7)
			})
			table.insert(self.hoverTweens, tween)
			tween:Play()
		end
		if buttonSize ~= nil and not disableHoverScaleTween then
			local rbxInstanceTween = TweenService:Create(rbxInstance, onHoverBeginTweenInfo, {
				Size = UDim2.new(
					buttonSize.X.Scale,
					buttonSize.X.Offset + 10,
					buttonSize.Y.Scale,
					buttonSize.Y.Offset + 10
				)
			})
			table.insert(self.hoverTweens, rbxInstanceTween)
			rbxInstanceTween:Play()
		end
	end
	
	local function onHoverEnd(rbxInstance)
		cancelHoverTweenInPlace()
		local hoverInstance = self.hoverElementRef:getValue()
		if hoverInstance ~= nil then
			local tween = TweenService:Create(hoverInstance, onHoverBeginTweenInfo, {
				Size = UDim2.fromScale(1, 0.5)
			})
			table.insert(self.hoverTweens, tween)
			tween:Play()
		end
		if buttonSize ~= nil and not disableHoverScaleTween then
			local rbxInstanceTween = TweenService:Create(rbxInstance, onHoverBeginTweenInfo, {
				Size = buttonSize
			})
			table.insert(self.hoverTweens, rbxInstanceTween)
			rbxInstanceTween:Play()
		end
	end
	
	return createElement("TextButton", {
		Size = buttonSize,
		AnchorPoint = self.props.AnchorPoint,
		Position = self.props.Position,
		[Roact.Ref] = self.props.hostRef,
		--TextValue = self.props.text,
		[Roact.Event.Activated] = (not isDisabled) and onClick or nil,
		[Roact.Event.MouseEnter] = (not isDisabled) and onHoverBegin or nil,
		[Roact.Event.MouseLeave] = (not isDisabled) and onHoverEnd or nil,
		[Roact.Event.MouseButton1Down] = (not isDisabled) and onPressDown or nil,
		[Roact.Event.MouseButton1Up] = (not isDisabled) and onPressUp or nil,
	}, {
		UICorner = createElement("UICorner", {CornerRadius = UDim.new(0, 8)}),
		UIStroke = createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(0, 0, 0),
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 1,
			Transparency = 0,
			Enabled = true,
		}),
		Background = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 1,
		}, {
			Color1 = createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, -5),
				ZIndex = 3,
			}, {
				Bottom = createElement("Frame", {
					Position = UDim2.new(0.5, 0, 1, 0),
					Size = UDim2.new(1, 0, 0.7, 0),
					ZIndex = 1,
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				}, {
					UICorner = createElement("UICorner", {CornerRadius = UDim.new(0, 8)}),
					UIGradient = createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, primaryColor),
							ColorSequenceKeypoint.new(1, secondaryColor),
						}),
						Enabled = true,
						Rotation = 90,
						Transparency = NumberSequence.new(0),
					}),
				}),
				Top = createElement("Frame", {
					BackgroundColor3 = tertiaryColor, 
					Position = UDim2.new(0.5, 0, 0, 0),
					Size = UDim2.new(1, 0, 0.5, 0),
					ZIndex = 2,
					AnchorPoint = Vector2.new(0.5, 0),
					[Roact.Ref] = self.hoverElementRef
				}, {
					UICorner = createElement("UICorner", {CornerRadius = UDim.new(0, 8)})
				})
			}),
			Color2 = createElement("Frame", {
				ZIndex = 2,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = quaternaryColor
			}, {
				UICorner = createElement("UICorner", {CornerRadius = UDim.new(0, 8)})
			}),
			Shadow = createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0), 
				BackgroundTransparency = 0.8, 
				Size = UDim2.new(1, 0, 1, 5), 
				ZIndex = 1
			}, {
				UICorner = createElement("UICorner", {CornerRadius = UDim.new(0, 8)})
			})
		}),
		Cover = createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.7,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 3,
			Visible = self.state.isPressedDown
		}, {
			UICorner = createElement("UICorner", {CornerRadius = UDim.new(0, 8)}),
		}),
		Content = createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}, self.props[Roact.Children]),
		ClickSoundEffect = createElement("Sound", {
			SoundId = "http://roblox.com/asset/?id="..CLICK_SOUND_ID,
			[Roact.Ref] = self.clickSoundRef
		})
	})
end

return Button
