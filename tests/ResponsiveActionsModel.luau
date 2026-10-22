-- Run as a ModuleScript in either Studio playtest context.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MiningPrediction = require(ReplicatedStorage.utils.MiningPrediction)
local checks = 0

local function expectHP(model: any, expected: number, context: string): ()
	assert(model:GetHP() == expected, context .. ": expected " .. expected .. ", got " .. model:GetHP())
	checks += 1
end

local function snapshot(revision: number, hp: number, receipts: {[string]: boolean}?): any
	return { targetId = "test-ore", revision = revision, remainingHP = hp, maxHP = 10,
		appliedActions = receipts or {} }
end

local model = MiningPrediction.new(10)
expectHP(model, 10, "Initial authoritative HP")
model:Predict("a", 2)
expectHP(model, 8, "First local hit appears immediately")
model:Predict("a", 2)
expectHP(model, 8, "Repeated local identifier does not count twice")
model:Predict("b", 3)
expectHP(model, 5, "Overlapping hits accumulate")
model:Apply(snapshot(1, 8, { a = true }))
expectHP(model, 5, "First receipt settles only its pending hit")
model:Apply(snapshot(2, 5, { a = true, b = true }))
expectHP(model, 5, "Second receipt does not subtract damage again")
model:Apply(snapshot(1, 8, { a = true }))
expectHP(model, 5, "Older confirmation cannot roll HP backward")
model:Predict("a", 2)
expectHP(model, 5, "Confirmed action cannot be predicted again")
model:Apply(snapshot(3, 4, { a = true, b = true }))
expectHP(model, 4, "Other-player hit becomes authoritative")
model:Predict("c", 2)
model:Apply(snapshot(4, 3, { a = true, b = true }))
expectHP(model, 1, "Other-player snapshot retains unresolved local damage")
model:Reject("c")
expectHP(model, 3, "Rejection rolls back only unresolved local damage")
model:Reject("c")
expectHP(model, 3, "Repeated rejection is harmless")
model:Predict("timeout", 8)
expectHP(model, 0, "Predicted finishing hit clamps at zero")
model:Reject("timeout")
expectHP(model, 3, "Timeout rollback restores authoritative HP")
model:Apply(snapshot(5, 0, { a = true, b = true, timeout = true }))
expectHP(model, 0, "Late acceptance after timeout still settles safely")

model = MiningPrediction.new(10)
model:Predict("first", 2)
model:Predict("second", 3)
model:Apply(snapshot(2, 5, { first = true, second = true }))
expectHP(model, 5, "Later confirmation may arrive first")
model:Apply(snapshot(1, 8, { first = true }))
expectHP(model, 5, "Out-of-order earlier response cannot revive pending damage")
model:Reject("first")
expectHP(model, 5, "Late rejection does not undo settled authoritative damage")
model:Predict("third", 2)
model:Apply(snapshot(2, 5, { first = true, second = true }))
expectHP(model, 3, "Repeated state keeps newer pending prediction")
model:Apply(snapshot(3, 0, { first = true, second = true }))
expectHP(model, 0, "Another player or bomb can break a predicted node")
model:Reject("third")
expectHP(model, 0, "Rollback never revives a confirmed break")

return { suite = "ResponsiveActionsModel", checks = checks }
