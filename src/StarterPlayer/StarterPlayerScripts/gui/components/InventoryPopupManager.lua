local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)

local createElement = Roact.createElement

local gui = script.Parent.Parent
local ModuleIndex = require(gui.ModuleIndex)
local InventoryPopup = require(ModuleIndex.InventoryPopup)
local ScreenContext = require(ModuleIndex.ScreenContext)

local POPUP_DURATION = 3
local SLIDE_OUT_DURATION = 0.35
local MAX_POPUPS = 5
local CONTAINER_MAX_WIDTH = 230
local CONTAINER_HEIGHT = 530  -- room for 5 popups at max size + gaps

local InventoryPopupManager = Roact.Component:extend("InventoryPopupManager")

function InventoryPopupManager:init()
	self.containerRef = Roact.createRef()
	self._popupQueue = {}        -- { {id, handle} } oldest first
	self._layoutOrderCounter = 0
	self._inventoryCache = {}    -- { [itemName] = quantity }
	self._connections = {}
	self._screenData = nil
end

function InventoryPopupManager:_getPopupWidth(): number
	local screenData = self._screenData
	if screenData == nil then return 175 end
	local isAtleast = screenData.IsAtleast
	if isAtleast("md") then
		return 220
	elseif isAtleast("sm") then
		return 195
	else
		return 175
	end
end

function InventoryPopupManager:_showPopup(itemName: string, amount: number)
	local container = self.containerRef:getValue()
	if container == nil then return end

	-- Evict oldest popup if at capacity
	if #self._popupQueue >= MAX_POPUPS then
		local oldest = table.remove(self._popupQueue, 1)
		Roact.unmount(oldest.handle)
	end

	self._layoutOrderCounter += 1
	local id = self._layoutOrderCounter
	local popupWidth = self:_getPopupWidth()

	local handle = Roact.mount(
		createElement(InventoryPopup, {
			itemName = itemName,
			amount = amount,
			popupWidth = popupWidth,
			layoutOrder = id,
		}),
		container,
		tostring(id)
	)

	table.insert(self._popupQueue, { id = id, handle = handle })

	-- Schedule unmount after popup has fully slid out
	task.delay(POPUP_DURATION + SLIDE_OUT_DURATION + 0.15, function()
		for i, entry in ipairs(self._popupQueue) do
			if entry.id == id then
				table.remove(self._popupQueue, i)
				Roact.unmount(handle)
				break
			end
		end
	end)
end

function InventoryPopupManager:_connectChild(child: ValueBase)
	if not child:IsA("ValueBase") then return end
	local itemName = child.Name
	local conn = child.Changed:Connect(function(newValue: number)
		local prevValue = self._inventoryCache[itemName] or 0
		if newValue > prevValue then
			self:_showPopup(itemName, newValue - prevValue)
		end
		self._inventoryCache[itemName] = newValue
	end)
	table.insert(self._connections, conn)
end

function InventoryPopupManager:didMount()
	local plr = game.Players.LocalPlayer
	local playerData = ReplicatedStorage:WaitForChild("PlayerData")
	local myData = playerData:WaitForChild(plr.Name)
	local inventoryFolder = myData:WaitForChild("Inventory")

	-- Seed cache from existing items without showing popups
	for _, child in pairs(inventoryFolder:GetChildren()) do
		if child:IsA("ValueBase") then
			self._inventoryCache[child.Name] = child.Value
			self:_connectChild(child)
		end
	end

	-- New items added after load
	local addedConn = inventoryFolder.ChildAdded:Connect(function(child)
		if child:IsA("ValueBase") then
			local amount = child.Value
			self._inventoryCache[child.Name] = amount
			if amount > 0 then
				self:_showPopup(child.Name, amount)
			end
			self:_connectChild(child)
		elseif child:IsA("Folder") then
			local nameValue = child:FindFirstChild("name")
			if nameValue and nameValue:IsA("StringValue") and nameValue.Value ~= "" then
				self:_showPopup(nameValue.Value, nil)
			end
		end
	end)
	table.insert(self._connections, addedConn)
end

function InventoryPopupManager:willUnmount()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}
end

function InventoryPopupManager:render()
	return createElement(ScreenContext.context.Consumer, {
		render = function(screenData)
			self._screenData = screenData
			local device = screenData.Device
			local yOffset = (device == "mobile") and -100 or -20

			return createElement("Frame", {
				Size = UDim2.fromOffset(CONTAINER_MAX_WIDTH, CONTAINER_HEIGHT),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 10, 1, yOffset),
				BackgroundTransparency = 1,
				ZIndex = 10,
				[Roact.Ref] = self.containerRef,
			}, {
				UIListLayout = createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}),
			})
		end,
	})
end

return InventoryPopupManager
