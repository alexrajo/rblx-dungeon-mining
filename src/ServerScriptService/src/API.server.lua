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
local UpgradeEndpoint = require(EndpointFolder.Upgrade)
local DrinkEndpoint = require(EndpointFolder.Drink)
local MixDrinkEndpoint = require(EndpointFolder.MixDrink)
local EquipDrinkEndpoint = require(EndpointFolder.EquipDrink)

-- Actions
local playerActions = ServerModules.player_actions
local BurpAction = require(playerActions.Burp)

-- Cross script communication
local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local startTutorialEvent = crossScriptCommunicationBindables.StartTutorial
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial
local skipTutorialEvent = crossScriptCommunicationBindables.SkipTutorial

function Burp(player: Player, cameraDirection: Vector3)
	return BurpAction.Activate(player, cameraDirection)
end

APIService:CreateEventEndpoint("Drink", DrinkEndpoint.Call)
APIService:CreateFunctionEndpoint("Burp", Burp)
APIService:CreateFunctionEndpoint("Upgrade", UpgradeEndpoint.Call)
APIService:CreateFunctionEndpoint("MixDrink", MixDrinkEndpoint.Call)
APIService:CreateEventEndpoint("EquipDrink", EquipDrinkEndpoint.Call)

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
