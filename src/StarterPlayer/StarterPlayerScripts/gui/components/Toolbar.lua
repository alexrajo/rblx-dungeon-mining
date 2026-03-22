local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.services.Roact)

local utils = ReplicatedStorage:WaitForChild("utils")
local StatCalculation = require(utils:WaitForChild("StatCalculation"))
local NumberFormatter = require(utils:WaitForChild("NumberFormatter"))

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local TextLabel = require(ModuleIndex.TextLabel)
local ProgressBar = require(ModuleIndex.ProgressBar)

local StatsContext = require(ModuleIndex.StatsContext)

local createElement = Roact.createElement

local Toolbar = Roact.Component:extend("Toolbar")

local toolListeners = {}

function getEquippedToolFromPlayer(player: Player)
	if player == nil then return end
	
	local character = player.Character
	if character == nil then return end
	
	local tool = character:FindFirstChildOfClass("Tool")
	return tool
end

function Toolbar:getToolObjectsFromTools(tools: {Tool})
	local objects = {}
	
	return objects
end

function Toolbar:onToolEquipped(tool: Tool)
	self:setState(function(state)
		local toolsList = state.tools
		for _, toolObj in pairs(toolsList) do
			if toolObj.tool == tool then
				toolObj.isEquipped = true
				return {tools = toolsList}
			end
		end
	end)
end

function Toolbar:onToolUnequipped(tool: Tool)
	self:setState(function(state)
		local toolsList = state.tools
		for _, toolObj in pairs(toolsList) do
			if toolObj.tool == tool then
				toolObj.isEquipped = false
				return {tools = toolsList}
			end
		end
	end)
end

function Toolbar:onToolRemoved(tool: Tool)
	local listeners = toolListeners[tool]
	if listeners ~= nil then
		for _, connection in pairs(listeners) do
			connection:Disconnect()
		end
	end
	toolListeners[tool] = nil
	
	self:setState(function(state)
		local toolsList = state.tools
		for i, toolObj in pairs(toolsList) do
			if toolObj.tool == tool then
				table.remove(toolsList, i)
				return {tools = toolsList}
			end
		end
	end)
end

function Toolbar:init()
	self.state = {
		tools = {}
	}
end

function Toolbar:didMount()
	-- Ensure LocalPlayer is available
	self.player = game.Players.LocalPlayer
	if not self.player then
		self.player = game.Players.PlayerAdded:Wait()  -- Wait for LocalPlayer if not available
	end
	
	local function listenToTool(tool)
		local equippedListener = tool.Equipped:Connect(function()
			self:onToolEquipped(tool)
		end)
		local unequippedListener = tool.Unequipped:Connect(function()
			self:onToolUnequipped(tool)
		end)
		local deleteListener = tool:GetPropertyChangedSignal("Parent"):Connect(function()
			if tool.Parent == nil then
				self:onToolRemoved(tool)
			end
		end)
		
		toolListeners[tool] = {equippedListener, unequippedListener, deleteListener}
	end
	
	local function setupToolListeners()
		local backpack = self.player:WaitForChild("Backpack")
		local tools = backpack:GetChildren()

		local equippedTool = getEquippedToolFromPlayer(self.player)
		if equippedTool ~= nil then
			table.insert(tools, equippedTool)
		end

		local toolObjects = {}
		for _, tool: Tool in pairs(tools) do
			if tool:IsA("Tool") then
				local isEquipped = tool.Parent == self.player.Character
				table.insert(toolObjects, {tool=tool, isEquipped=isEquipped})
				listenToTool(tool)
			end
		end

		self:setState({
			tools = toolObjects
		})
		
		return toolObjects, backpack
	end
	
	local function setupListeners()
		local toolObjects, backpack = setupToolListeners()
		
		-- Listen to backpack updates
		self.backpackAddConnection = backpack.ChildAdded:Connect(function(child)
			-- Check if this tool already exists in the toolObjects
			for _, toolObj in pairs(toolObjects) do
				if toolObj.tool == child then
					return
				end
			end
			
			listenToTool(child)
			
			-- Append newToolObject to the state
			self:setState(function(state)
				local toolsList = state.tools
				local newToolObject = {tool=child, isEquipped=false}
				
				table.insert(toolsList, newToolObject)
				
				return {
					tools = toolsList
				}
			end)
		end)
		
		self.player.CharacterRemoving:Connect(function()
			self:setState({tools={}})
		end)
		
		self.player.CharacterAdded:Connect(setupToolListeners)
	end
	
	-- Ensure the player has a character (in case this script runs before spawning)
	if self.player.Character then
		setupListeners()
	else
		-- Wait for the player's character to load if it's not available yet
		self.player.CharacterAdded:Wait()
		setupListeners()
	end
	
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		local character = self.player.Character
		if not character then return end

		local humanoid: Humanoid = character:WaitForChild("Humanoid")
		if not humanoid then return end
		
		local index = input.KeyCode.Value-48
		if index > 0 and index <= 9 and index <= #self.state.tools then -- If input is a number and index is within bounds
			local toolObject = self.state.tools[index]
			local tool = toolObject.tool
			if tool then
				if toolObject.isEquipped then
					humanoid:UnequipTools()
					self:onToolUnequipped(tool)
				else
					humanoid:EquipTool(tool)
					self:onToolEquipped(tool)
				end
			end
		end
	end)
end

--[[
	
]]
function Toolbar:render()
	
	local function onClick(toolObject: {tool: Tool, isEquipped: boolean})
		local character = self.player.Character
		if not character then return end
		
		local humanoid: Humanoid = character:WaitForChild("Humanoid")
		if not humanoid then return end
		
		local tool = toolObject.tool
		if tool then
			if toolObject.isEquipped then
				humanoid:UnequipTools()
				self:onToolUnequipped(tool)
			else
				humanoid:EquipTool(tool)
				self:onToolEquipped(tool)
			end
		end
	end
	
	local toolFrames = {}
	for i, toolObject in ipairs(self.state.tools) do
		local tool = toolObject.tool
		local frame = createElement("TextButton", {
			Text = "",
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BorderMode = Enum.BorderMode.Inset,
			BorderSizePixel = toolObject.isEquipped and 3 or 0,
			BorderColor3 = Color3.fromRGB(45, 158, 255),
			[Roact.Event.Activated] = function()
				onClick(toolObject)
			end,
		}, {
			NumberLabel = createElement(TextLabel, {
				Size = UDim2.fromOffset(12, 12),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -4, 0, 4),
				BackgroundTransparency = 1,
				textSize = 10,
				Text = i
			}),
			NameLabel = createElement(TextLabel, {
				Size = UDim2.new(1, -8, 1, -8),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
				textSize = 14,
				Text = tool.Name
			})
		})
		table.insert(toolFrames, frame)
	end
	
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local clampedProgress = math.clamp(data.BurpCharge / data.BurpChargeThreshold, 0, 1)
			local burpPower = math.floor(StatCalculation.GetBurpPower(data.Level, data.BurpCharge))
			local burpPowerString = NumberFormatter:GetFormattedLargeNumber(burpPower)
			
			return createElement("Frame", {
				Position = UDim2.new(0.5, 0, 1, -32),
				Size = UDim2.new(0.7, -200, 0, 112),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
			}, {
				BurpPowerLabel = createElement(TextLabel, {
					Text = 'Power: <font color="rgb(255, 15, 15)">'..burpPowerString..'</font>',
					textSize = 16,
					Size = UDim2.new(0.3, 0, 0, 20),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 0)
				}),
				ChargeUp = createElement(ProgressBar, {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = clampedProgress < 1 and UDim2.new(0.5, 0, 0, 26) or UDim2.new(0.5, 0, 0, 24),
					width = UDim.new(0.5, 0),
					height = clampedProgress < 1 and UDim.new(0, 16) or UDim.new(0, 20),
					progress = clampedProgress,
					text = clampedProgress < 1 and "Burp charge ("..data.BurpCharge..")" or "FULLY CHARGED ("..data.BurpCharge..")",
					textSize = clampedProgress < 1 and 12 or 14,
					doAnimation = true,
					colorName = clampedProgress < 1 and "green" or "orange"
				}),
				Toolbar = createElement("Frame", {
					Position = UDim2.new(0, 0, 1, 0),
					Size = UDim2.new(1, 0, 1, -48),
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0, 1)
				}, {
					UIListLayout = createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						ItemLineAlignment = Enum.ItemLineAlignment.Center,
						Padding = UDim.new(0, 8),
						HorizontalAlignment = Enum.HorizontalAlignment.Center
					}),
					Tools = Roact.createFragment(toolFrames)
				})
			})
		end,
	})
end

function Toolbar:willUnmount()
	if self.backpackAddConnection then
		self.backpackAddConnection:Disconnect()
	end
end

return Toolbar
