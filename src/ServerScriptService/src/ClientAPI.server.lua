local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)

-- Event that tells the client to visualize coin drops when fired
APIService:CreateEventEndpoint("DropCoins")

-- Event that tells the client to visualize item drops when fired
APIService:CreateEventEndpoint("DropItems")

-- Event that tells the client to visualize mining hit effects
APIService:CreateEventEndpoint("VisualizeMineHit")

-- Event that tells the client to show damage indicators on hit enemies
APIService:CreateEventEndpoint("VisualizeAttackHit")

-- Event to send a notification from the server to the client
APIService:CreateEventEndpoint("SendNotification")

-- Event to send the next step of a tutorial to the client
APIService:CreateEventEndpoint("SendNextTutorialStep")

-- Event to start the client-side mine transition overlay
APIService:CreateEventEndpoint("StartMineTransition")

-- Event to update the local player's reward chest appearance immediately after opening
APIService:CreateEventEndpoint("MineChestOpened")

-- Event to open the mine elevator checkpoint selector UI on the client
APIService:CreateEventEndpoint("OpenMineElevator")

-- Event to show or update the active conversation UI on the client
APIService:CreateEventEndpoint("ShowConversationStep")

-- Event to close the active conversation UI on the client
APIService:CreateEventEndpoint("EndConversation")
