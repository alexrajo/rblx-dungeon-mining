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
local QuestService = require(ServerModules.QuestService)
local ConversationService = require(ServerModules.ConversationService)

-- Endpoint handlers
local EndpointFolder = ServerModules.api_endpoints
local MineEndpoint = require(EndpointFolder.Mine)
local SellOreEndpoint = require(EndpointFolder.SellOre)
local SellItemsEndpoint = require(EndpointFolder.SellItems)
local EquipGearEndpoint = require(EndpointFolder.EquipGear)
local CraftEndpoint = require(EndpointFolder.Craft)
local AttackEndpoint = require(EndpointFolder.Attack)
local UseBombEndpoint = require(EndpointFolder.UseBomb)
local UseConsumableEndpoint = require(EndpointFolder.UseConsumable)
local EnterMineEndpoint = require(EndpointFolder.EnterMine)
local ExitMineEndpoint = require(EndpointFolder.ExitMine)
local AssignHotbarSlotEndpoint = require(EndpointFolder.AssignHotbarSlot)
local ClearHotbarSlotEndpoint = require(EndpointFolder.ClearHotbarSlot)
local ClearEquippedGearEndpoint = require(EndpointFolder.ClearEquippedGear)
local SelectHotbarSlotEndpoint = require(EndpointFolder.SelectHotbarSlot)
local BuyItemsEndpoint = require(EndpointFolder.BuyItems)
local MineElevatorTravelEndpoint = require(EndpointFolder.MineElevatorTravel)
local StartQuestEndpoint = require(EndpointFolder.StartQuest)
local TrackQuestEndpoint = require(EndpointFolder.TrackQuest)
local UntrackQuestEndpoint = require(EndpointFolder.UntrackQuest)
local AbandonQuestEndpoint = require(EndpointFolder.AbandonQuest)
local ClaimQuestRewardEndpoint = require(EndpointFolder.ClaimQuestReward)
local ToolEquipHandler = require(ServerModules.ToolEquipHandler)
local ArmorAttachmentService = require(ServerModules.ArmorAttachmentService)

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
APIService:CreateFunctionEndpoint("MineElevatorTravel", MineElevatorTravelEndpoint.Call)
APIService:CreateFunctionEndpoint("StartQuest", StartQuestEndpoint.Call)
APIService:CreateFunctionEndpoint("TrackQuest", TrackQuestEndpoint.Call)
APIService:CreateFunctionEndpoint("UntrackQuest", UntrackQuestEndpoint.Call)
APIService:CreateFunctionEndpoint("AbandonQuest", AbandonQuestEndpoint.Call)
APIService:CreateFunctionEndpoint("ClaimQuestReward", ClaimQuestRewardEndpoint.Call)
APIService:CreateEventEndpoint("EquipGear", EquipGearEndpoint.Call)
APIService:CreateFunctionEndpoint("Craft", CraftEndpoint.Call)
APIService:CreateFunctionEndpoint("Attack", AttackEndpoint.Call)
APIService:CreateFunctionEndpoint("UseBomb", UseBombEndpoint.Call)
APIService:CreateFunctionEndpoint("UseConsumable", UseConsumableEndpoint.Call)
APIService:CreateFunctionEndpoint("EnterMine", EnterMineEndpoint.Call)
APIService:CreateFunctionEndpoint("ExitMine", ExitMineEndpoint.Call)
APIService:CreateFunctionEndpoint("CompleteMineTransition", MineTransitionService.CompleteTransition)
APIService:CreateEventEndpoint("MineTransitionReady", MineTransitionService.MarkReady)
APIService:CreateEventEndpoint("FinishMineTransition", MineTransitionService.FinishTransition)
APIService:CreateEventEndpoint("AssignHotbarSlot", AssignHotbarSlotEndpoint.Call)
APIService:CreateEventEndpoint("ClearHotbarSlot", ClearHotbarSlotEndpoint.Call)
APIService:CreateEventEndpoint("ClearEquippedGear", ClearEquippedGearEndpoint.Call)
APIService:CreateEventEndpoint("SelectHotbarSlot", SelectHotbarSlotEndpoint.Call)
APIService:CreateEventEndpoint("AdvanceConversation", ConversationService.AdvanceConversation)
APIService:CreateEventEndpoint("SelectConversationResponse", ConversationService.SelectResponse)
APIService:CreateEventEndpoint("LeaveConversation", ConversationService.LeaveConversation)

-- Initialize mine floor preloading
MineFloorManager.Init()
MineTransitionService.Init()
QuestService.Init()

-- Tool equipping
ToolEquipHandler.Initialize()
ArmorAttachmentService.Initialize()

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
