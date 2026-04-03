local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.services.Roact)

local localServices = ReplicatedStorage:WaitForChild("local_services")
local HotbarService = require(localServices:WaitForChild("HotbarService"))
local HotbarConfig = require(ReplicatedStorage.configs.HotbarConfig)
local BombConfig = require(ReplicatedStorage.configs.BombConfig)

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local SelectablePanel = require(ModuleIndex.SelectablePanel)
local TextLabel = require(ModuleIndex.TextLabel)
local ScreenContext = require(ModuleIndex.ScreenContext)
local StatsContext = require(ModuleIndex.StatsContext)
local InventoryUtils = require(ModuleIndex.InventoryUtils)

local createElement = Roact.createElement

local Toolbar = Roact.Component:extend("Toolbar")

function Toolbar:init()
	self:setState({
		hotbar = HotbarService.GetState(),
	})
end

function Toolbar:didMount()
	self.selectionDisconnect = HotbarService.OnChanged(function(hotbarState)
		self:setState({ hotbar = hotbarState })
	end)

	self.inputConnection = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then return end

		local numericKeys = {
			[Enum.KeyCode.One] = 1,
			[Enum.KeyCode.Two] = 2,
			[Enum.KeyCode.Three] = 3,
			[Enum.KeyCode.Four] = 4,
			[Enum.KeyCode.Five] = 5,
		}

		local slotIndex = numericKeys[input.KeyCode]
		if slotIndex ~= nil then
			HotbarService.SelectSlot(slotIndex)
			return
		end

		if input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.ButtonL1 then
			local previousSlot = HotbarService.FindNextFilledSlot(-1)
			if previousSlot ~= 0 then
				HotbarService.SelectSlot(previousSlot)
			end
		elseif input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.ButtonR1 then
			local nextSlot = HotbarService.FindNextFilledSlot(1)
			if nextSlot ~= 0 then
				HotbarService.SelectSlot(nextSlot)
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

function Toolbar:renderToolbar(screenData, statsData)
	local isAtleast: (string) -> boolean = screenData.IsAtleast
	local slotSize = isAtleast("md") and 86 or 70
	local padding = isAtleast("md") and 10 or 6
	local hotbarSlots = self.state.hotbar.slots or {}
	local selectedSlot = self.state.hotbar.selectedSlot or 0

	local slotButtons = {}
	local visibleSlotCount = 0
	for i = 1, HotbarConfig.MAX_SLOTS do
		local itemName = hotbarSlots[i] or ""
		if itemName ~= "" then
			local imageId = HotbarConfig.GetImageId(itemName)
			local isSelected = selectedSlot == i
			local bombCount = InventoryUtils.GetBombInventoryCount(statsData, itemName)
			visibleSlotCount += 1

			slotButtons["Slot" .. tostring(i)] = createElement(SelectablePanel, {
				selected = isSelected,
				Size = UDim2.fromOffset(slotSize, slotSize),
				aspectRatio = 1,
				LayoutOrder = i,
				onSelect = function()
					HotbarService.SelectSlot(i)
				end,
			}, {
				SlotNumber = createElement(TextLabel, {
					Text = tostring(i),
					textSize = 14,
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0, 10, 0, 10),
					AnchorPoint = Vector2.zero,
					textProps = {
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Left,
					},
				}),
				Icon = createElement("ImageLabel", {
					Image = "rbxassetid://" .. imageId,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.45),
					Size = UDim2.fromScale(0.5, 0.5),
					BackgroundTransparency = 1,
				}),
				BombCount = BombConfig.IsBombItem(itemName) and bombCount ~= nil and createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 43, 106),
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -8, 1, -8),
					Size = UDim2.fromOffset(24, 18),
					ZIndex = 5,
				}, {
					UICorner = createElement("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
					Text = createElement(TextLabel, {
						Text = tostring(bombCount),
						textSize = 11,
						Size = UDim2.fromScale(1, 1),
						ZIndex = 6,
						textProps = {
							TextScaled = true,
						},
					}),
				}) or nil,
				Name = createElement(TextLabel, {
					Text = itemName,
					textSize = 12,
					Size = UDim2.new(1, -8, 0, 20),
					Position = UDim2.new(0.5, 0, 1, -14),
					AnchorPoint = Vector2.new(0.5, 1),
					textProps = {
						TextScaled = true,
						TextWrapped = true,
					},
				}),
				SelectionTint = isSelected and createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.85,
					Size = UDim2.new(1, -8, 1, -8),
					Position = UDim2.fromOffset(4, 4),
					ZIndex = 4,
				}, {
					UICorner = createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
				}),
			})
		end
	end

	if visibleSlotCount == 0 then
		return nil
	end

	return createElement("Frame", {
		Position = screenData.Device == "mobile" and UDim2.new(0.5, 0, 1, -18) or UDim2.new(0.5, 0, 1, -20),
		Size = UDim2.new(0, visibleSlotCount * slotSize + (visibleSlotCount - 1) * padding, 0, slotSize),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
	}, {
		UIListLayout = createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, padding),
		}),
		Tools = Roact.createFragment(slotButtons),
	})
end

function Toolbar:render()
	return createElement(ScreenContext.context.Consumer, {
		render = function(data)
			return createElement(StatsContext.context.Consumer, {
				render = function(statsData)
					return self:renderToolbar({
						Device = data.Device,
						IsAtleast = data.IsAtleast,
					}, statsData)
				end,
			})
		end,
	})
end

return Toolbar
