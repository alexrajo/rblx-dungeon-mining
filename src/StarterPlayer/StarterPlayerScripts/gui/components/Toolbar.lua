local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.services.Roact)
local APIService = require(ReplicatedStorage.services.APIService)

local localServices = ReplicatedStorage:WaitForChild("local_services")
local ToolSelectionService = require(localServices:WaitForChild("ToolSelectionService"))

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local ActionButton = require(ModuleIndex.ActionButton)
local ScreenContext = require(ModuleIndex.ScreenContext)

local createElement = Roact.createElement

local TOOLS = {
	{ name = "Mine", imageId = "84216914378212", activeColor = "green", key = Enum.KeyCode.One },
	{ name = "Attack", imageId = "93381643136380", activeColor = "red", key = Enum.KeyCode.Two },
}

local Toolbar = Roact.Component:extend("Toolbar")

function Toolbar:init()
	self:setState({
		selectedTool = ToolSelectionService.GetSelectedTool(),
	})
end

function Toolbar:didMount()
	local selectActiveToolEvent = APIService.GetEvent("SelectActiveTool")

	-- Fire initial selection so server knows the active tool on mount
	selectActiveToolEvent:FireServer(ToolSelectionService.GetSelectedTool())

	self.selectionDisconnect = ToolSelectionService.OnChanged(function(toolName: string)
		self:setState({ selectedTool = toolName })
		selectActiveToolEvent:FireServer(toolName)
	end)

	self.inputConnection = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then return end
		for _, toolDef in ipairs(TOOLS) do
			if input.KeyCode == toolDef.key then
				ToolSelectionService.SetSelectedTool(toolDef.name)
				break
			end
		end
	end)
end

function Toolbar:willUnmount()
	if self.selectionDisconnect then
		self.selectionDisconnect()
	end
	if self.inputConnection then
		self.inputConnection:Disconnect()
	end
end

function Toolbar:renderToolbar(screenData)
	local device = screenData.Device
	if device ~= "computer" then
		return createElement("Frame", { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 })
	end

	local isAtleast: (string) -> boolean = screenData.IsAtleast
	local buttonSize = isAtleast("md") and "xl" or "lg"

	local toolButtons = {}
	for i, toolDef in ipairs(TOOLS) do
		local isSelected = self.state.selectedTool == toolDef.name
		toolButtons[toolDef.name] = createElement(ActionButton, {
			color = isSelected and toolDef.activeColor or "gray",
			size = buttonSize,
			imageId = toolDef.imageId,
			text = toolDef.name .. " (" .. tostring(i) .. ")",
			textSize = 14,
			LayoutOrder = i,
			onClick = function()
				ToolSelectionService.SetSelectedTool(toolDef.name)
			end,
		})
	end

	return createElement("Frame", {
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(0, 200, 0, 80),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
	}, {
		UIListLayout = createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		}),
		Tools = Roact.createFragment(toolButtons),
	})
end

function Toolbar:render()
	return createElement(ScreenContext.context.Consumer, {
		render = function(data)
			return self:renderToolbar(data)
		end,
	})
end

return Toolbar
