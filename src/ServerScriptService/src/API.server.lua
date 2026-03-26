local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

-- Handlers
local ServerScriptService = game:GetService("ServerScriptService")
local ServerModules = ServerScriptService.modules
local PlayerDataHandler = require(ServerModules.PlayerDataHandler)

-- Endpoint handlers
local EndpointFolder = ServerModules.api_endpoints
local MineEndpoint = require(EndpointFolder.Mine)
local SellOreEndpoint = require(EndpointFolder.SellOre)
local EquipGearEndpoint = require(EndpointFolder.EquipGear)
local CraftEndpoint = require(EndpointFolder.Craft)
local AttackEndpoint = require(EndpointFolder.Attack)
local EnterMineEndpoint = require(EndpointFolder.EnterMine)
local ExitMineEndpoint = require(EndpointFolder.ExitMine)
local ToolEquipHandler = require(ServerModules.ToolEquipHandler)

-- Cross script communication
local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local startTutorialEvent = crossScriptCommunicationBindables.StartTutorial
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial
local skipTutorialEvent = crossScriptCommunicationBindables.SkipTutorial

-- Game endpoints
APIService:CreateFunctionEndpoint("Mine", MineEndpoint.Call)
APIService:CreateFunctionEndpoint("SellOre", SellOreEndpoint.Call)
APIService:CreateEventEndpoint("EquipGear", EquipGearEndpoint.Call)
APIService:CreateFunctionEndpoint("Craft", CraftEndpoint.Call)
APIService:CreateFunctionEndpoint("Attack", AttackEndpoint.Call)
APIService:CreateFunctionEndpoint("EnterMine", EnterMineEndpoint.Call)
APIService:CreateFunctionEndpoint("ExitMine", ExitMineEndpoint.Call)

-- Tool equipping
ToolEquipHandler.Initialize()
APIService:CreateEventEndpoint("SelectActiveTool", function(player: Player, actionName: string)
	ToolEquipHandler.SetActiveSlot(player, actionName)
end)

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
