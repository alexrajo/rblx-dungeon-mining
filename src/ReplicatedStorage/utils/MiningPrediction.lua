-- Pure reconciliation model. Only state messages carry receipts; replicated HP
-- alone cannot tell us whether it already includes an outstanding local hit.
local MiningPrediction = {}
MiningPrediction.__index = MiningPrediction

export type Snapshot = {
	targetId: string, revision: number, remainingHP: number, maxHP: number,
	appliedActions: {[string]: boolean}, node: Instance?, broken: boolean?, floorNumber: number?,
}

function MiningPrediction.new(hp: number, revision: number?): any
	return setmetatable({ hp = hp, revision = revision or 0, pending = {}, appliedActions = {} }, MiningPrediction)
end

function MiningPrediction:Predict(actionId: string, damage: number): ()
	if not self.appliedActions[actionId] then self.pending[actionId] = damage end
end

function MiningPrediction:Apply(snapshot: Snapshot): ()
	if snapshot.revision < self.revision then return end
	self.revision = snapshot.revision
	self.hp = snapshot.remainingHP
	self.appliedActions = snapshot.appliedActions
	for actionId in pairs(self.pending) do
		if snapshot.appliedActions[actionId] then self.pending[actionId] = nil end
	end
end

function MiningPrediction:Reject(actionId: string): ()
	self.pending[actionId] = nil
end

function MiningPrediction:GetHP(): number
	local hp = self.hp
	for _, damage in pairs(self.pending) do hp -= damage end
	return math.max(0, hp)
end

return MiningPrediction
