local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local configs = ReplicatedStorage.configs
local MineLayerConfig = require(configs.MineLayerConfig)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local TextLabel = require(ModuleIndex.TextLabel)
local StatsContext = require(ModuleIndex.StatsContext)

local FloorIndicator = Roact.Component:extend("FloorIndicator")

function FloorIndicator:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local inMine = data.InMine
			local currentFloor = data.CurrentFloor or 0

			if not inMine or currentFloor <= 0 then
				return nil
			end

			-- Determine layer name
			local layerName = "Unknown"
			for layerNum, layerData in pairs(MineLayerConfig) do
				if type(layerNum) ~= "number" then continue end
				if currentFloor >= layerData.floors.min and currentFloor <= layerData.floors.max then
					layerName = layerData.name
					break
				end
			end

			return createElement("Frame", {
				Size = UDim2.new(0, 300, 0, 30),
				Position = UDim2.new(0.5, 0, 0, 10),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0
			}, {
				UICorner = createElement("UICorner", {
					CornerRadius = UDim.new(0, 6)
				}),
				Label = createElement(TextLabel, {
					Text = "Floor " .. currentFloor .. " - " .. layerName,
					Size = UDim2.fromScale(1, 1),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					textSize = 18
				})
			})
		end
	})
end

return FloorIndicator
