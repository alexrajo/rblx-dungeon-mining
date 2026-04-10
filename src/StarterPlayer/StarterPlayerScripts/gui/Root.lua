local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local ModuleIndex = require(script.Parent.ModuleIndex)

local pages = script.Parent.pages

local createElement = Roact.createElement

local PageManager = require(ModuleIndex.PageManager)
local ControlsOverlay = require(ModuleIndex.ControlsOverlay)
local Toolbar = require(ModuleIndex.Toolbar)
local StatsContext = require(ModuleIndex.StatsContext)
local ScreenContext = require(ModuleIndex.ScreenContext)
local ChangeVisualizer = require(ModuleIndex.ChangeVisualizer)
local NotificationManager = require(ModuleIndex.NotificationManager)
local MineTransitionOverlay = require(ModuleIndex.MineTransitionOverlay)
local TutorialManager = require(ModuleIndex.TutorialManager)
local HealthBar = require(ModuleIndex.HealthBar)
local InventoryPopupManager = require(ModuleIndex.InventoryPopupManager)

local pageModules = pages:GetChildren()

local Root = Roact.Component:extend("Root")

function Root:render()
	return Roact.createFragment({
		MainGui = createElement("ScreenGui", {
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ResetOnSpawn = false,
			IgnoreGuiInset = false,
		}, {
			StatsContextController = createElement(StatsContext.controller, {}, {
				ScreenContextController = createElement(ScreenContext.controller, {}, {
					PageManager = createElement(PageManager, {
						pages = pageModules,
						Size = UDim2.new(1, 0, 1, 0),
					}),
					Toolbar = createElement(Toolbar, {}),
					Controls = createElement(ControlsOverlay, {
						Size = UDim2.new(1, 0, 1, 0),
						Position = UDim2.new(0, 0, 0, 0),
					}),
					ChangeVisualizer = createElement(ChangeVisualizer),
					Notifications = createElement(NotificationManager),
					TutorialManager = createElement(TutorialManager),
					HealthBar = createElement(HealthBar),
					InventoryPopupManager = createElement(InventoryPopupManager),
				}),
			}),
		}),
		MineTransitionOverlay = createElement(MineTransitionOverlay),
	})
end

return Root
