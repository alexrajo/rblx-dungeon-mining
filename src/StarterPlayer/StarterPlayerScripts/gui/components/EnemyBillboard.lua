local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local ProgressBar = require(ModuleIndex.ProgressBar)
local TextLabel = require(ModuleIndex.TextLabel)

local EnemyBillboard = Roact.Component:extend("EnemyBillboard")

function EnemyBillboard:init()
	self._connections = {}

	local enemyModel = self.props.enemyModel
	local humanoid = enemyModel and enemyModel:FindFirstChildOfClass("Humanoid")
	local enemyType = enemyModel and (enemyModel:GetAttribute("EnemyType") or enemyModel.Name) or "Enemy"

	self:setState({
		health = humanoid and math.floor(humanoid.Health) or 0,
		maxHealth = humanoid and math.floor(humanoid.MaxHealth) or 0,
		enemyType = enemyType,
	})
end

function EnemyBillboard:_updateFromHumanoid()
	local enemyModel = self.props.enemyModel
	if enemyModel == nil then return end

	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then return end

	self:setState({
		health = math.floor(humanoid.Health),
		maxHealth = math.floor(humanoid.MaxHealth),
	})
end

function EnemyBillboard:_updateEnemyType()
	local enemyModel = self.props.enemyModel
	if enemyModel == nil then return end

	self:setState({
		enemyType = enemyModel:GetAttribute("EnemyType") or enemyModel.Name,
	})
end

function EnemyBillboard:didMount()
	local enemyModel = self.props.enemyModel
	if enemyModel == nil then return end

	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		table.insert(self._connections, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			self:_updateFromHumanoid()
		end))
		table.insert(self._connections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
			self:_updateFromHumanoid()
		end))
	end

	table.insert(self._connections, enemyModel:GetAttributeChangedSignal("EnemyType"):Connect(function()
		self:_updateEnemyType()
	end))

	table.insert(self._connections, enemyModel:GetPropertyChangedSignal("Name"):Connect(function()
		self:_updateEnemyType()
	end))

	self:_updateEnemyType()
	self:_updateFromHumanoid()
end

function EnemyBillboard:willUnmount()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end

	self._connections = {}
end

function EnemyBillboard:render()
	local health = self.state.health
	local maxHealth = self.state.maxHealth
	local progress = maxHealth > 0 and math.clamp(health / maxHealth, 0, 1) or 0

	return createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Name = createElement(TextLabel, {
			Text = self.state.enemyType,
			Size = UDim2.new(1, 0, 0.4, 0),
			Position = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.zero,
            textProps = {
                TextScaled = true
            }
		}),
		Health = createElement(ProgressBar, {
			progress = progress,
			text = "HP: " .. health .. "/" .. maxHealth,
			colorName = "red",
			width = UDim.new(1, 0),
			height = UDim.new(0.6, 0),
			textSize = 12,
			Position = UDim2.new(0, 0, 0.4, 0),
			doAnimation = true,
            autoScaleText = true,
		}),
	})
end

return EnemyBillboard
