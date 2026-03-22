local ServerScriptService = game:GetService("ServerScriptService")
local ServerModules = ServerScriptService.modules
local PlayerDataHandler = require(ServerModules.PlayerDataHandler)
local ServerStorage = game:GetService("ServerStorage")

-- Cross script communication
local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GlobalConfig = require(ReplicatedStorage:WaitForChild("GlobalConfig"))
local DRINK_INTERVAL = GlobalConfig.DRINK_INTERVAL
local NETWORK_LEEWAY = 0.1

local debounces = {}

local endpoint = {}

function endpoint.Call(player: Player)
	if debounces[player] == true then return end
	debounces[player] = true
	
	delay(DRINK_INTERVAL-NETWORK_LEEWAY, function()
		debounces[player] = nil
	end)

    signalTutorialEvent:Fire(player, "drink")
	
	local data = game.ReplicatedStorage:FindFirstChild("PlayerData")
	if data then
		local playerData = data:FindFirstChild(player.Name)
		if playerData then
			local burpCharge = playerData:FindFirstChild("BurpCharge")
			local threshold = playerData:FindFirstChild("BurpChargeThreshold")
			if burpCharge and threshold then
				burpCharge.Value = math.min(burpCharge.Value + 1, threshold.Value)
			end
		end
	end
	
	PlayerDataHandler.GiveBurpPoints(player, 1)
end

return endpoint
