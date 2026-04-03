local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

-- Handlers
local ServerScriptService = game:GetService("ServerScriptService")
local ServerModules = ServerScriptService.modules
local PlayerDataHandler = require(ServerModules.PlayerDataHandler)

local MineFloorManager = require(ServerModules.MineFloorManager)
local MineTransitionService = require(ServerModules.MineTransitionService)

-- Endpoint handlers
local EndpointFolder = ServerModules.api_endpoints
local MineEndpoint = require(EndpointFolder.Mine)
local SellOreEndpoint = require(EndpointFolder.SellOre)
local SellItemsEndpoint = require(EndpointFolder.SellItems)
local EquipGearEndpoint = require(EndpointFolder.EquipGear)
local CraftEndpoint = require(EndpointFolder.Craft)
local AttackEndpoint = require(EndpointFolder.Attack)
local UseBombEndpoint = require(EndpointFolder.UseBomb)
local EnterMineEndpoint = require(EndpointFolder.EnterMine)
local ExitMineEndpoint = require(EndpointFolder.ExitMine)
local AssignHotbarSlotEndpoint = require(EndpointFolder.AssignHotbarSlot)
local ClearHotbarSlotEndpoint = require(EndpointFolder.ClearHotbarSlot)
local ClearEquippedGearEndpoint = require(EndpointFolder.ClearEquippedGear)
local SelectHotbarSlotEndpoint = require(EndpointFolder.SelectHotbarSlot)
local BuyItemsEndpoint = require(EndpointFolder.BuyItems)
local ToolEquipHandler = require(ServerModules.ToolEquipHandler)

-- Cross script communication
local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local startTutorialEvent = crossScriptCommunicationBindables.StartTutorial
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial
local skipTutorialEvent = crossScriptCommunicationBindables.SkipTutorial

-- Game endpoints
APIService:CreateFunctionEndpoint("Mine", MineEndpoint.Call)
APIService:CreateFunctionEndpoint("SellOre", SellOreEndpoint.Call)
APIService:CreateFunctionEndpoint("SellItems", SellItemsEndpoint.Call)
APIService:CreateFunctionEndpoint("BuyItems", BuyItemsEndpoint.Call)
APIService:CreateEventEndpoint("EquipGear", EquipGearEndpoint.Call)
APIService:CreateFunctionEndpoint("Craft", CraftEndpoint.Call)
APIService:CreateFunctionEndpoint("Attack", AttackEndpoint.Call)
APIService:CreateFunctionEndpoint("UseBomb", UseBombEndpoint.Call)
APIService:CreateFunctionEndpoint("EnterMine", EnterMineEndpoint.Call)
APIService:CreateFunctionEndpoint("ExitMine", ExitMineEndpoint.Call)
APIService:CreateFunctionEndpoint("CompleteMineTransition", MineTransitionService.CompleteTransition)
APIService:CreateEventEndpoint("FinishMineTransition", MineTransitionService.FinishTransition)
APIService:CreateEventEndpoint("AssignHotbarSlot", AssignHotbarSlotEndpoint.Call)
APIService:CreateEventEndpoint("ClearHotbarSlot", ClearHotbarSlotEndpoint.Call)
APIService:CreateEventEndpoint("ClearEquippedGear", ClearEquippedGearEndpoint.Call)
APIService:CreateEventEndpoint("SelectHotbarSlot", SelectHotbarSlotEndpoint.Call)

-- Initialize mine floor preloading
MineFloorManager.Init()
MineTransitionService.Init()

-- Tool equipping
ToolEquipHandler.Initialize()

-- Tutorial
function startTutorial(...)
	startTutorialEvent:Fire(...)
end

function skipTutorial(...)
	skipTutorialEvent:Fire(...)
end

function signalTutorial(...)
    signalTutorialEvent:Fire(...)
end

APIService:CreateEventEndpoint("StartTutorial", startTutorial)
APIService:CreateEventEndpoint("SkipTutorial", skipTutorial)
APIService:CreateEventEndpoint("SignalTutorial", signalTutorial)
