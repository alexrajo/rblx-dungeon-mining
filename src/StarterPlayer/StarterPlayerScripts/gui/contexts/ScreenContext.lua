local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local IS_STUDIO = game:GetService("RunService"):IsStudio()

local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)

local createElement = Roact.createElement

local SCREEN_SIZE_MAX_WIDTHS = {
	xs = 750,
	sm = 1024,
	md = 1366,
	lg = 1920,
	xl = 2560,
	["2xl"] = 3840,
}

function isAtleastSize(sizeToCompare: string, actualSize: string): boolean
	return SCREEN_SIZE_MAX_WIDTHS[sizeToCompare] <= SCREEN_SIZE_MAX_WIDTHS[actualSize]
end

local DEFAULT_VALUE = {
	Size = "xs",
	Device = "mobile",
	IsAtleast = function(sizeToCompare: string)
		return isAtleastSize(sizeToCompare, "xs")
	end,
}
local ScreenContext = Roact.createContext(DEFAULT_VALUE)
local ScreenContextController = Roact.Component:extend("ScreenContextController")

function classifyScreenSize(viewportSize: Vector2)
	local lowestFittingMaxWidth = math.huge
	local screenSizeClassification = nil
	for k, v in pairs(SCREEN_SIZE_MAX_WIDTHS) do
		if v >= viewportSize.X and v < lowestFittingMaxWidth then
			lowestFittingMaxWidth = v
			screenSizeClassification = k
		end
	end
	
	if screenSizeClassification == nil then
		screenSizeClassification = "xxl"
	end
	
	return screenSizeClassification
end

function getDeviceType()
	if GuiService:IsTenFootInterface() then
		return "console"
	elseif IS_STUDIO then
		-- Try to infer based on screen size for Studio testing
		if game.Workspace.CurrentCamera.ViewportSize.X <= SCREEN_SIZE_MAX_WIDTHS.xs then
			return "mobile"
		else
			return "computer"
		end
	elseif UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return "computer"
	else
		return "mobile"
	end
end

function ScreenContextController:init()
	self:setState(DEFAULT_VALUE)
end

function ScreenContextController:didMount()
	local camera = game.Workspace.CurrentCamera
	local function updateScreenSize()
		local size = camera.ViewportSize
		local screenSize = classifyScreenSize(size)
		local deviceType = getDeviceType()
		--print(screenSize, deviceType)
		self:setState({
			Size = screenSize,
			Device = deviceType,
			IsAtleast = function(sizeToCompare)
				return isAtleastSize(sizeToCompare, screenSize)
			end,
		})
	end

	self._conn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScreenSize)
	updateScreenSize()
end

function ScreenContextController:render()
	return createElement(ScreenContext.Provider, {
		value = self.state
	}, self.props[Roact.Children])
end

return {context = ScreenContext, controller = ScreenContextController}
