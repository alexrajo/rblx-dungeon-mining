local plr = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local Maid = require(Services.Maid)

local createElement = Roact.createElement

local DEFAULT_VALUE = {
	Coins = 0,
	Level = 1,
	XP = 0,
	MaxFloorReached = 0,
	LatestCheckpointFloor = 0,
	Inventory = {},
	EquippedHelmet = "",
	EquippedChestplate = "",
	EquippedLeggings = "",
	EquippedBoots = "",
	HotbarSlots = {
		{name = "1", value = ""},
		{name = "2", value = ""},
		{name = "3", value = ""},
		{name = "4", value = ""},
		{name = "5", value = ""},
	},
	SelectedHotbarSlot = 0,
	ActiveQuests = {},
	QuestObjectiveProgress = {},
	QuestCompletions = {},
	QuestClaims = {},
	UnlockedRecipes = {},
	TutorialStates = {{name = "Intro", value = false}},
	CurrentFloor = 0,
	InMine = false,
	ActiveTheme = "default",
}
local StatsContext = Roact.createContext(DEFAULT_VALUE)
local StatsController = Roact.Component:extend("StatsController")

local dataUpdateMaid = Maid.new()

function StatsController:init()
	self:setState(DEFAULT_VALUE)
end

function StatsController:didMount()
	local playerData = ReplicatedStorage:WaitForChild("PlayerData")
	if playerData == nil then
		warn("StatsController: No player data folder found in ReplicatedStorage!")
		return
	end
	local myData = playerData:WaitForChild(plr.Name)
	if myData == nil then
		warn("StatsController: No player data folder found for player: "..plr.Name)
		return
	end

	for statName, defaultStatValue in pairs(DEFAULT_VALUE) do
		local valueRef = myData:WaitForChild(statName)
		if valueRef == nil then
			warn("StatsController: No instance found for "..statName.."!")
			return
		end
		if valueRef:IsA("ValueBase") then
			dataUpdateMaid:GiveTask(valueRef.Changed:Connect(function(newValue)
				self:setState({
					[statName] = newValue
				})
			end))

			self:setState({
				[statName] = valueRef.Value
			})
		elseif valueRef:IsA("Folder") then
			local function updateFolderStat()
				local newStat = {}
				for _, child in ipairs(valueRef:GetChildren()) do
					if child:IsA("ValueBase") then
						table.insert(newStat, {name = child.Name, value = child.Value})
					elseif child:IsA("Folder") then
						local entry = {
							id = child.Name,
						}

						for _, field in ipairs(child:GetChildren()) do
							if field:IsA("ValueBase") then
								entry[field.Name] = field.Value
							end
						end

						table.insert(newStat, entry)
					end
				end

				self:setState({
					[statName] = newStat
				})
			end

			local function connectFolderChild(child)
				if child:IsA("ValueBase") then
					dataUpdateMaid:GiveTask(child.Changed:Connect(updateFolderStat))
				elseif child:IsA("Folder") then
					dataUpdateMaid:GiveTask(child.ChildAdded:Connect(function(field)
						if field:IsA("ValueBase") then
							dataUpdateMaid:GiveTask(field.Changed:Connect(updateFolderStat))
						end
						updateFolderStat()
					end))
					dataUpdateMaid:GiveTask(child.ChildRemoved:Connect(updateFolderStat))

					for _, field in ipairs(child:GetChildren()) do
						if field:IsA("ValueBase") then
							dataUpdateMaid:GiveTask(field.Changed:Connect(updateFolderStat))
						end
					end
				end
			end

			dataUpdateMaid:GiveTask(valueRef.ChildAdded:Connect(function(child)
				connectFolderChild(child)
				updateFolderStat()
			end))
			dataUpdateMaid:GiveTask(valueRef.ChildRemoved:Connect(updateFolderStat))

			for _, child: ValueBase in pairs(valueRef:GetChildren()) do
				connectFolderChild(child)
			end

			updateFolderStat()
		end
	end
end

function StatsController:willUnmount()
	dataUpdateMaid:Destroy()
end

function StatsController:render()
	return createElement(StatsContext.Provider, {
		value = self.state
	}, self.props[Roact.Children])
end

return {context = StatsContext, controller = StatsController}
