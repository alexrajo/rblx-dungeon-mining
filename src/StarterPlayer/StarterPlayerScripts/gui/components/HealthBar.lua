local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local ProgressBar = require(ModuleIndex.ProgressBar)
local TextLabel = require(ModuleIndex.TextLabel)
local StatsContext = require(ModuleIndex.StatsContext)

local HealthBar = Roact.Component:extend("HealthBar")

function HealthBar:init()
	self:setState({
		health = 100,
		maxHealth = 100
	})
end

function HealthBar:didMount()
	local plr = game.Players.LocalPlayer

	local function updateHealth()
		local character = plr.Character
		if character == nil then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid == nil then return end

		self:setState({
			health = math.floor(humanoid.Health),
			maxHealth = math.floor(humanoid.MaxHealth)
		})
	end

	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid:GetPropertyChangedSignal("Health"):Connect(updateHealth)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
		updateHealth()
	end

	plr.CharacterAdded:Connect(onCharacterAdded)
	if plr.Character then
		onCharacterAdded(plr.Character)
	end
end

function HealthBar:render()
	local health = self.state.health
	local maxHealth = self.state.maxHealth
	local progress = maxHealth > 0 and health / maxHealth or 0

	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local inMine = data.InMine == true
			local currentFloor = data.CurrentFloor or 0
			local showFloor = inMine and currentFloor > 0

			return createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 10),
				Size = UDim2.new(0, 200, 0, showFloor and 47 or 25),
			}, {
				Health = createElement(ProgressBar, {
					progress = progress,
					text = "HP: " .. health .. "/" .. maxHealth,
					width = UDim.new(0, 200),
					Size = UDim2.new(0, 200, 0, 25),
				}),
				Floor = showFloor and createElement(TextLabel, {
					Text = "Floor " .. currentFloor,
					Size = UDim2.new(0, 200, 0, 18),
					Position = UDim2.new(0, 0, 0, 29),
					AnchorPoint = Vector2.new(0, 0),
					textSize = 17,
					textProps = {
						TextXAlignment = Enum.TextXAlignment.Left,
					},
				}) or nil,
			})
		end,
	})
end

return HealthBar
