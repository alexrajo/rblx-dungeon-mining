local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local APIService = require(ReplicatedStorage.services.APIService)

local localServices = ReplicatedStorage:WaitForChild("local_services")
local ActionFireService = require(localServices.ActionFireService)
local ToolSelectionService = require(localServices:WaitForChild("ToolSelectionService"))

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local ActionButton = require(ModuleIndex.ActionButton)
local ScreenContext = require(ModuleIndex.ScreenContext)

local TOOL_CONFIG: {[string]: {imageId: string, activeColor: string}} = {
	Mine = { imageId = "84216914378212", activeColor = "green" },
	Attack = { imageId = "93381643136380", activeColor = "red" },
}

local ControlsOverlay = Roact.Component:extend("ControlsOverlay")

local cachedActions: {[string]: BindableFunction} = {}

local function getAction(name: string): BindableFunction?
	if cachedActions[name] == nil then
		cachedActions[name] = ActionFireService.GetAction(name)
	end
	return cachedActions[name]
end

function ControlsOverlay:init()
	self:setState({
		actionReady = true,
		selectedTool = ToolSelectionService.GetSelectedTool(),
		device = "computer",
	})
end

function ControlsOverlay:activateAction(toolName: string)
	if not self.state.actionReady then return end

	local action = getAction(toolName)
	if action == nil then return end

	-- Sync tool selection and notify server for tool swapping
	ToolSelectionService.SetSelectedTool(toolName)
	if self.selectActiveToolEvent then
		self.selectActiveToolEvent:FireServer(toolName)
	end

	self:setState({ actionReady = false })
	local cooldownTime = action:Invoke()
	if cooldownTime == nil then cooldownTime = 0 end

	task.delay(cooldownTime, function()
		self:setState({ actionReady = true })
	end)
end

function ControlsOverlay:didMount()
	self.selectActiveToolEvent = APIService.GetEvent("SelectActiveTool")

	self.selectionDisconnect = ToolSelectionService.OnChanged(function(toolName: string)
		self:setState({ selectedTool = toolName })
	end)

	self.inputBeganConnection = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then return end

		local device = self.state.device

		-- Q key — all devices
		if input.KeyCode == Enum.KeyCode.Q then
			print("Q key pressed — reserved for future use")
			return
		end

		if device == "computer" then
			-- Left click activates selected tool
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:activateAction(ToolSelectionService.GetSelectedTool())
			end
		elseif device == "console" then
			-- ButtonX = Mine, ButtonY = Attack
			if input.KeyCode == Enum.KeyCode.ButtonX then
				self:activateAction("Mine")
			elseif input.KeyCode == Enum.KeyCode.ButtonY then
				self:activateAction("Attack")
			end
		end
	end)

end

function ControlsOverlay:willUnmount()
	if self.selectionDisconnect then
		self.selectionDisconnect()
	end
	if self.inputBeganConnection then
		self.inputBeganConnection:Disconnect()
	end
end

function ControlsOverlay:renderPC()
	return createElement("Frame", {
		Position = self.props.Position,
		Size = self.props.Size,
		BackgroundTransparency = 1,
	})
end

function ControlsOverlay:renderMobileConsole(screenData)
	local device = screenData.Device
	local isAtleast: (string) -> boolean = screenData.IsAtleast
	local buttonSize = isAtleast("md") and "2xl" or "xl"

	local mineText = (device == "console" and "Mine (X)") or "Mine"
	local attackText = (device == "console" and "Attack (Y)") or "Attack"

	return createElement("Frame", {
		Position = self.props.Position,
		Size = self.props.Size,
		BackgroundTransparency = 1,
	}, {
		Mine = createElement(ActionButton, {
			color = self.state.actionReady and "green" or "gray",
			size = buttonSize,
			AnchorPoint = Vector2.new(0.5, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Position = isAtleast("md") and UDim2.new(0.8, 0, 0.6, 0) or UDim2.new(0.775, 0, 0.625, 0),
			imageId = TOOL_CONFIG.Mine.imageId,
			text = mineText,
			textSize = 20,
			onClick = function()
				self:activateAction("Mine")
			end,
		}),
		Attack = createElement(ActionButton, {
			color = self.state.actionReady and "red" or "gray",
			size = "md",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = isAtleast("md") and UDim2.new(0.9, 0, 0.6, 0) or UDim2.new(0.9, 0, 0.5, 0),
			imageId = TOOL_CONFIG.Attack.imageId,
			text = attackText,
			onPressDown = function()
				self:activateAction("Attack")
			end,
		}),
	})
end

function ControlsOverlay:render()
	return createElement(ScreenContext.context.Consumer, {
		render = function(data)
			-- Keep device in state so input handlers can read it
			if data.Device ~= self.state.device then
				self:setState({ device = data.Device })
			end

			if data.Device == "computer" then
				return self:renderPC()
			else
				return self:renderMobileConsole(data)
			end
		end,
	})
end

return ControlsOverlay
