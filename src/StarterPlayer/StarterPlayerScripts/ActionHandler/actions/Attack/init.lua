local ReplicatedStorage = game:GetService("ReplicatedStorage")

local APIService = require(ReplicatedStorage.services.APIService)
local GearConfig = require(ReplicatedStorage.configs.GearConfig)
local Targeting = require(ReplicatedStorage.utils.ActionTargeting)
local Runtime = require(ReplicatedStorage.local_services.ActionRuntime)
local Feedback = require(ReplicatedStorage.local_services.ActionFeedback)

local AttackAction = {}

function AttackAction.Activate(tool: Tool?): number
	local stats = GearConfig.GetWeaponCombatStats(tool and tool:GetAttribute("HotbarItemName"))
	if tool then
		Runtime.PlaySwing("Attack", tool, function(actionId: string, character: Model, root: BasePart, floor: number)
			local targets = Targeting.FindAttackTargets(character, root, floor)
			Feedback.PredictAttack(actionId, targets)
			task.spawn(function()
				local ok, result = pcall(function()
					return APIService.GetFunction("Attack"):InvokeServer(tool, targets, actionId)
				end)
				if not ok then warn("AttackAction: request failed", result) end
			end)
		end)
	end
	return stats.attackCooldown
end

return AttackAction
