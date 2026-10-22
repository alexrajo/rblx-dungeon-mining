# Mining and combat responsiveness

Mining and attacks retain character-facing controls, existing reach limits and
shared cooldowns. Targets are discovered at animation contact, so turning or a
moving enemy during the windup affects the hit. Mining uses the same forward,
upward and downward rays; attacks retain the forward half-circle.

## Timing and input

`ActionConfig` owns animations, sounds, contact fallbacks and responsiveness
constants. An `Impact` animation marker triggers contact when available. Marker
metadata is fetched asynchronously; unavailable metadata/assets use the existing
270 ms mining / 200 ms attack contact delay. Playback and metadata preparation
never wait on the input path. Cooldowns start at activation, not confirmation.

The shared cooldown remains 400 ms for mining and the configured per-weapon value
for attacks. One mining/attack input in its final 100 ms is buffered; the latest
input replaces the earlier one. It executes only for the same selected tool,
character and floor. Hold-to-mine repeats at the cooldown deadline without a
polling loop. Release stops repetition but lets an already-started swing finish.
Tool changes, death, transitions and lost focus cancel queued or unsent hits.
Bombs and consumables retain their existing effects and shared cooldown behavior.

## Prediction and authority

The client plays mining sound/shake and attack contact sound/highlight immediately
at contact. The latest struck ore shows a provisional HP billboard for two
seconds. Deterministic mining power predicts ore HP and finishing hits. Predicted
broken ore is hidden locally with collision/querying disabled, allowing passage.
The replicated node is never destroyed by prediction.

The server continues to calculate damage, critical hits, knockback, destruction,
XP, inventory rewards, quests and ladder reveals. Enemy HP and damage numbers
are confirmed only. Crates get local impact feedback but no predicted break.
No player-data migration or animation publishing is required.

Rejected or unanswered mining requests restore the predicted state; requests
time out locally after two seconds and are never automatically resent. Restored
ore is visible immediately. Collision restoration waits while the local character
overlaps it, avoiding trapping or teleporting that character. Late authoritative
results remain valid. Character/floor changes and streaming removal clean up
prediction, displays, shake transforms and property overrides.

## Networking contract

All endpoints use the existing `APIService` layer.

- `Mine(tool, node, hitPosition, actionId?)` preserves existing fields and adds
  `actionId` and an authoritative `state` on success.
- `Attack(tool, targets, actionId?)` preserves its results and adds `actionId`.
  Each unique target can receive damage once per request.
- `VisualizeMineHit(state)` broadcasts authoritative node state. State contains
  `targetId`, optional `node`, `revision`, `remainingHP`, `maxHP`, `broken`,
  `floorNumber`, and cumulative `appliedActions` receipts. IDs are server-generated
  `DestructibleId` attributes; revisions are `MiningRevision` attributes.
- `VisualizeAttackHit(hitData, actionId?)` retains confirmed damage/critical
  indicators and suppresses the impact sound if it was predicted for that action.
- `DestructibleBroken(payload)` carries `targetId`, `kind` (`Ore`/`Crate`),
  `position`, `floorNumber`, `actorUserId`, and optional `actionId`. Clients render
  break audio/smoke once per target, including breaks caused by bombs. Confirming
  a locally predicted break does not replay it.

Mining reconciliation combines the newest versioned server HP with only those
pending hits absent from its receipts. Replicated `CurrentHP` alone is not used
to settle predictions because it does not identify the local hits it includes.
Replayed mining action IDs do not apply damage twice. Rejections preserve the
existing level-failure contract. Range uses the existing server pivot/root
definition on both sides; ore floor membership is validated like other targets.

## Validation

The `tests/ResponsiveActions*.luau` checks run from temporary local Studio runners
through Rojo, using the running game's module context. A dedicated testing
subagent owns playstate, runs the responsiveness and existing item-level checks,
inspects output, and removes temporary runners afterward. Runtime timing evidence
must distinguish network emulation from delayed-confirmation tests and state
which mouse/touch/controller and multiplayer cases were actually exercised.
