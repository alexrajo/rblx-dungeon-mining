local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

-- Event that tells the client to visualize coin drops when fired
APIService:CreateEventEndpoint("DropCoins")

-- Event that tells the client to visualize item drops when fired
APIService:CreateEventEndpoint("DropItems")

-- Event that tells the client to visualize burps from other players
APIService:CreateEventEndpoint("VisualizeBurp")

-- Event to send a notification from the server to the client
APIService:CreateEventEndpoint("SendNotification")

-- Event to send the next step of a tutorial to the client
APIService:CreateEventEndpoint("SendNextTutorialStep")
