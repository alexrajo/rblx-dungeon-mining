local plr = game.Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

local visualizeEvent = APIService.GetEvent("VisualizeBurp")
local utils = ReplicatedStorage.utils
local VisualizeBurp = require(utils.VisualizeBurp)

function visualize(character, level, charge)
	if character == plr.Character then return end
	
	VisualizeBurp.Visualize(character, level, charge)
end

visualizeEvent.OnClientEvent:Connect(visualize)