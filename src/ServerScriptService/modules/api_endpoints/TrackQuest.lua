local ServerScriptService = game:GetService("ServerScriptService")

local QuestService = require(ServerScriptService.modules.QuestService)

local endpoint = {}

function endpoint.Call(player: Player, questId: string)
	return QuestService.TrackQuest(player, questId)
end

return endpoint
