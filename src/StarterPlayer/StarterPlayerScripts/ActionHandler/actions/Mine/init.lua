local ReplicatedStorage = game:GetService("ReplicatedStorage")

local APIService = require(ReplicatedStorage.services.APIService)
local GlobalConfig = require(ReplicatedStorage.GlobalConfig)
local Targeting = require(ReplicatedStorage.utils.ActionTargeting)
local Runtime = require(ReplicatedStorage.local_services.ActionRuntime)
local Feedback = require(ReplicatedStorage.local_services.ActionFeedback)

local MineAction = {}

function MineAction.Activate(tool: Tool?): number
	if not tool then return 0.5 end
	Runtime.PlaySwing("Mine", tool, function(actionId: string, character: Model, root: BasePart, floor: number)
		local node, position = Targeting.FindMineTarget(character, root, floor)
		if not node then return end
		Feedback.PredictMine(node, tool, actionId)
		task.spawn(function()
			local ok, result = pcall(function()
				return APIService.GetFunction("Mine"):InvokeServer(tool, node, position, actionId)
			end)
			Feedback.ResolveMine(node, actionId, if ok then result else nil)
			if not ok then warn("MineAction: request failed", result) end
		end)
	end)
	return GlobalConfig.MINE_SWING_COOLDOWN
end

return MineAction
