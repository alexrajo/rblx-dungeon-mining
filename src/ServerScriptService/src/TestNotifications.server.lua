local ReplicatedStorage = game:GetService("ReplicatedStorage")
local services = ReplicatedStorage.services
local APIService = require(services.APIService)

local event = APIService.GetEvent("SendNotification")

while true do
	task.wait(10)
	event:FireAllClients({Type = "levelup", Title = "Test", Level = 11})
end