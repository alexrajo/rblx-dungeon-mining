local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local TextButton = require(ModuleIndex.TextButton)
local TextLabel = require(ModuleIndex.TextLabel)
local Button = require(ModuleIndex.Button)
local ProgressBar = require(ModuleIndex.ProgressBar)
local LevelBar = require(ModuleIndex.LevelBar)

local ScreenContext = require(ModuleIndex.ScreenContext)
local StatsContext = require(ModuleIndex.StatsContext)

local utils = ReplicatedStorage.utils
local NumberFormatter = require(utils.NumberFormatter)

local Sidebar = Roact.Component:extend("Sidebar")

function Sidebar:init()
	
end

function Sidebar:renderContent(screenData)
	local isAtleast = screenData.IsAtleast
	local device = screenData.Device
	local sidebarSize = (isAtleast("xl") and UDim2.new(0.1, 0, 0.5, 0)) 
		or (isAtleast("lg") and UDim2.new(0.125, 0, 0.5, 0)) 
		or UDim2.new(0.15, 0, 0.5, 0)
	
	local itemsPerRow = isAtleast("md") and 4 or 2
	local numItems = 4
	local numRows = math.ceil(numItems/itemsPerRow)
	local paddingPixels = 12
	
	local function togglePage(pageName: string)
		if self.props.togglePage ~= nil then
			self.props.togglePage(pageName)
		end
	end

	return createElement("Frame", {
		Size = sidebarSize,
		BackgroundTransparency = 1,
		Position = (device == "computer" or device == "console") and UDim2.new(0, 10,  0.5, 0) or UDim2.new(0, 10,  0, 10),
		AnchorPoint = (device == "computer" or device == "console") and Vector2.new(0, 0.5) or Vector2.new(0, 0)
	}, {
		UIListLayout = createElement("UIListLayout", {Padding = UDim.new(0, 10),  VerticalAlignment = (device == "computer" or device == "console") and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.Name}),
		StatsContextConsumer = createElement(StatsContext.context.Consumer, {
			render = function(data)
				return Roact.createFragment({
					["0_levels"] = Roact.createElement(LevelBar, {
						level = data.Level,
						xp = data.XP,
						Size = UDim2.new(1, 0, 0, 25*1.75)
					}),
					["1_coins"] = Roact.createElement(ProgressBar, {
						progress = 1,
						text = NumberFormatter:GetFormattedLargeNumber(data.Coins),
						showPlusButton = true,
						showIcon = true,
						iconImageId = "11953783945",
						colorName = "yellow",
						width = UDim.new(1, 0)
					})
				})
			end,	
		}),
		["2_MenuButtons"] = createElement("Frame", {
			Size = UDim2.new(1, 0, 1/itemsPerRow*numRows, -paddingPixels*(itemsPerRow-1)/itemsPerRow),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundTransparency = 1
		}, {
			UIGridLayout = createElement("UIGridLayout", {
				StartCorner = Enum.StartCorner.TopLeft,
				CellSize = UDim2.new(1/itemsPerRow, -paddingPixels*(itemsPerRow-1)/itemsPerRow, 1/numRows, 0),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.Name,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				CellPadding = UDim2.new(0, paddingPixels, 0, paddingPixels)
			}, {}),
			["0_StatsPageToggle"] = createElement(Button, {
				color = "green", 
				onClick = function()
					togglePage("Stats")
				end
			}, {
				Icon = createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(0.65, 0, 0.65, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://108621540777869"
				}),
				TextLabel = createElement(TextLabel, {
					Text = "Stats",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 1),
					ZIndex = 2
				})
			}),
			["1_ShopPageToggle"] = createElement(Button, {
				color = "green",
				onClick = function()
					togglePage("Shop")
				end
			}, {
				Icon = createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(0.75, 0, 0.75, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://123265243903080"
				}),
				TextLabel = createElement(TextLabel, {
					Text = "Shop",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 1),
					ZIndex = 2
				})
			}),
			["2_Inventory"] = createElement(Button, {
				color = "green",
				onClick = function()
					togglePage("Inventory")
				end
			}, {
				Icon = createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(0.75, 0, 0.75, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://114916340811088"
				}),
				TextLabel = createElement(TextLabel, {
					Text = "Inventory",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 1),
					ZIndex = 2
				})
			}),
			["3_Crafting"] = createElement(Button, {
				color = "green",
				onClick = function()
					togglePage("CraftingPage")
				end
			}, {
				Icon = createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(0.75, 0, 0.75, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://77344538197277"
				}),
				TextLabel = createElement(TextLabel, {
					Text = "Craft",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 1),
					ZIndex = 2
				})
			})
		})
	})
end

--[[
	@param togglePage: function(pageName: string) => void
]]
function Sidebar:render()
	return createElement(ScreenContext.context.Consumer, {
		render = function(data)
			return self:renderContent(data)
		end,
	})
end

return Sidebar
