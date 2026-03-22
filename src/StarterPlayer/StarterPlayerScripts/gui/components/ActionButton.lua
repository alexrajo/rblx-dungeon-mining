local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local TextLabel = require(ModuleIndex.TextLabel)

local Button = Roact.Component:extend("ActionButton")

local SIZES = {
	xs = {
		container = UDim2.fromOffset(30, 30)
	},
	sm = {
		container = UDim2.fromOffset(40, 40)
	},
	md = {
		container = UDim2.fromOffset(50, 50),
	},
	lg = {
		container = UDim2.fromOffset(60, 60),
	},
	xl = {
		container = UDim2.fromOffset(80, 80),
	},
	["2xl"] = {
		container = UDim2.fromOffset(100, 100),
	},
	["3xl"] = {
		container = UDim2.fromOffset(140, 140),
	},
}

local COLORS = {
	green = {
		primary = "#33ac29",
		secondary = "#42c018",
		tertiary = "#4fd502",
		quaternary = "#1d7e02",
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
 	@param SizeConstraint?
 	@param imageId?
 	@param text?
 	@param textSize?
]]
function Button:render()
	
	local size: string = self.props.size
	local customSize: UDim2 | nil = self.props.customSize
	
	local buttonSize = customSize or (size and SIZES[size].container)
	local imageId = self.props.imageId or "11953925580"
	local text = self.props.text or ""
	
	-- Colors
	local color: {primary: string, secondary: string, tertiary: string, quaternary: string} = COLORS[self.props.color]
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
		if buttonSize ~= nil then
			if hoverInstance ~= nil then
				local tween = TweenService:Create(hoverInstance, onHoverBeginTweenInfo, {
					Size = UDim2.fromScale(1, 0.7)
				})
				table.insert(self.hoverTweens, tween)
				tween:Play()
			end
			local rbxInstanceTween = TweenService:Create(rbxInstance, onHoverBeginTweenInfo, {
				Size = UDim2.fromOffset(buttonSize.Width.Offset+10, buttonSize.Height.Offset+10)
			})
			table.insert(self.hoverTweens, rbxInstanceTween)
			rbxInstanceTween:Play()
		end
	end
	
	local function onHoverEnd(rbxInstance)
		cancelHoverTweenInPlace()
		local hoverInstance = self.hoverElementRef:getValue()
		if buttonSize ~= nil then
			if hoverInstance ~= nil then
				local tween = TweenService:Create(hoverInstance, onHoverBeginTweenInfo, {
					Size = UDim2.fromScale(1, 0.5)
				})
				table.insert(self.hoverTweens, tween)
				tween:Play()
			end
			local rbxInstanceTween = TweenService:Create(rbxInstance, onHoverBeginTweenInfo, {
				Size = buttonSize
			})
			table.insert(self.hoverTweens, rbxInstanceTween)
			rbxInstanceTween:Play()
		end
	end
	
	return createElement("ImageButton", {
		BackgroundTransparency = 1,
		Size = buttonSize,
		AnchorPoint = self.props.AnchorPoint,
		Position = self.props.Position,
		SizeConstraint = self.props.SizeConstraint,
		--TextValue = self.props.text,
		[Roact.Event.Activated] = onClick,
		[Roact.Event.MouseEnter] = onHoverBegin,
		[Roact.Event.MouseLeave] = onHoverEnd,
		[Roact.Event.MouseButton1Down] = onPressDown,
		[Roact.Event.MouseButton1Up] = onPressUp,
		[Roact.Ref] = self.hoverElementRef
	}, {
		image = createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}, {
			imageLabel = createElement("ImageLabel", {
				Image = "rbxassetid://"..imageId,
				AnchorPoint = Vector2.new(0.5, 0.55),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.6, 0.6),
				ZIndex = 2,
			}),

			uIAspectRatioConstraint = createElement("UIAspectRatioConstraint"),

			--[[
			imageLabelStroke = createElement("ImageLabel", {
				Image = "rbxassetid://"..imageId,
				ImageColor3 = Color3.fromRGB(0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0.55),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.new(0.5, 0, 0.5, 2),
				Size = UDim2.fromScale(0.5, 0.5),
			}),
			]]
		}),

		background = createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Size = UDim2.fromScale(1, 1),
		}, {
			color2 = createElement("ImageLabel", {
				Image = "rbxassetid://11953889677",
				ImageColor3 = primaryColor,
				ImageTransparency = 0.5,
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.5, 0.9),
				Size = UDim2.fromScale(0.7, 0.5),
				ZIndex = 4,
			}),

			shadow = createElement("ImageLabel", {
				Image = "rbxassetid://11953889677",
				ImageColor3 = Color3.fromRGB(0, 0, 0),
				ImageTransparency = 0.8,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.new(0.5, 0, 0.5, 5),
				Size = UDim2.fromScale(1, 1),
			}),

			color1 = createElement("ImageLabel", {
				Image = "rbxassetid://11953889677",
				ImageColor3 = tertiaryColor,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 3,
			}),

			stroke = createElement("ImageLabel", {
				Image = "rbxassetid://11953889677",
				ImageColor3 = Color3.fromRGB(0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 2, 1, 2),
				ZIndex = 2,
			}),
		}),
		TextLabel = createElement(TextLabel, {
			Size = UDim2.new(1, 0, 0, 16),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 1),
			Text = text,
			ZIndex = 2,
			textSize = self.props.textSize
		}),
		ClickSoundEffect = createElement("Sound", {
			SoundId = "http://roblox.com/asset/?id="..CLICK_SOUND_ID,
			[Roact.Ref] = self.clickSoundRef
		})
	})
end

return Button
