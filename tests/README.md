# Item level playtests

Run the server and client Luau files from temporary local playtest runners in their respective Roblox execution contexts, after player data and the character have loaded. Each file returns a summary and raises an assertion on failure. Use Roblox Studio MCP to start the playtest and inspect output; remove the temporary runners afterwards.

- Server checks cover all 42 items at levels below, equal to, and above their requirement, equip/assignment/selection validation, direct action denials, item preservation, early acquisition, and starter potion use. Modified player fields are restored.
- Client checks mount the actual Roact components with isolated inventory contexts at desktop and smaller screen sizes. They cover badges, details, button availability, drop targets, and live level updates, then remove the preview UI.

For networking smoke tests, run checks through local scripts so they share the running game's module context. Requiring server modules directly from MCP can create a separate module state.

## Responsive action regression suites

These files are ModuleScript test bodies, outside the production Rojo mapping:

| Suite | Context | Checks |
| --- | --- | --- |
| `ResponsiveActionsModel.luau` | Server or client | 21 reconciliation, overlapping/stale confirmations, receipts, rollback and late acceptance |
| `ResponsiveActionsServer.luau` | Server | 13 stable identity, mining damage/replay/cooldown/floor/range, attack deduplication and transition rejection |
| `ResponsiveActionsTargeting.luau` | Client | 12 pivot/root reach, floor, front arc, fresh queries and multipart deduplication |
| `ResponsiveActionsFeedback.luau` | Client | 14 immediate hiding/HP, deduplication, rejection, overlapping collision restoration, timeout and shake cleanup |
| `ResponsiveActionsInput.luau` | Client | 13 early/near-ready input, one queued action, cancellation, hold/release and exactly one contact |
| `ResponsiveActionsNetworkServer.luau` + `ResponsiveActionsNetworkClient.luau` | Server fixture + client | 10 real remote confirmations, terminal identity, destruction/event/reward deduplication and ladder reveal |

The input suite temporarily replaces the selected-tool getter, mining callback, and `ActionRuntime.IsValid` with an isolated fixture. The validity replacement preserves character/tool/health/transition checks but omits OS focus: background Studio emits `WindowFocusReleased`, and MCP keyboard injection does not restore it. Replacements are restored even on assertion failure. This validates the actual input scheduler and contact implementation, not physical input-device behavior.

To run through Rojo without editing Studio script Source:

1. Copy these files into a temporary `src/ReplicatedStorage/ResponsiveTestModules/` folder. Copy existing item-level bodies there as `ItemLevelRequirementsServer.lua` and `ItemLevelRequirementsClient.lua`, avoiding the `.server`/`.client` suffix so the copies are ModuleScripts.
2. Add a temporary local server runner under `src/ServerScriptService/src/`. After player data/character load, sequentially require model, server, and existing item-level server suites. Then require the network server fixture and set `workspace:SetAttribute("ResponsiveServerTestsFinished", true)`.
3. Add a temporary local client runner under `src/StarterPlayer/StarterPlayerScripts/`. Wait for that attribute and two seconds for restored/fixture state to replicate, then sequentially require targeting, feedback, input, existing item-level client, and network client suites. Wrap each require with `xpcall` and print its summary or traceback. Do not run these suites concurrently.
4. Use Studio MCP to start play and inspect output. Stop play, remove all temporary runners/module copies, and verify their removal synced before building. Keep the original tests in this folder.

The server suite restores its changed inventory/hotbar/level/character state. The network fixture snapshots all ProfileTemplate fields plus character position/health/protection, grants deterministic one-Stone breaks, and restores everything through its temporary `ResponsiveTestsControl` endpoint. A 60-second fallback restores the fixture if the client aborts. Run only in an isolated Studio session.

## Recorded validation — 2026-10-22

Roblox Studio MCP ran one server and one client against locally synced scripts. All eight suites passed together: 83 new checks plus the existing 491 server and 53 client item-level checks, **627 checks per pass**. Tests cover real finishing-hit destruction, one break event, exactly 5 XP and one Stone, one ladder, rejected replay, and an unsolicited server `BreakNode` call producing one additional event/reward despite a repeated call.

- At `NetworkSettings.IncomingReplicationLag = 0.1`, the real mining RemoteFunction round trip was **249.16 ms**. This property is an incoming replication delay, not a measured RTT setting.
- A second complete 627-check pass at `IncomingReplicationLag = 0.2` observed a **449.23 ms** mining round trip. The original Studio setting, **0.3 seconds**, was restored after testing; Studio was left stopped in Edit mode.
- Independently injecting 0/100/200 ms before confirmation handling left synchronous local finishing prediction at **0.237–0.514 ms** in that pass. These measurements are function execution times, not rendered-frame or network-latency measurements.
- Model scenarios represent concurrent other-player/bomb state updates; they do not replace a two-player session. Physical mouse/touch/controller behavior, actual focus-loss recovery, multiplayer contention, streaming/respawn during live requests, and prolonged asset/network-failure soak tests remain manual checks.
- Existing Studio output included disabled DataStore API access (ProfileService used unsaved data), asset `203785492` type mismatch, missing armor models exercised by level tests, preview `ASSET_ID_HERE` requests, and an Atmos plugin asset load. No production action-script exceptions appeared in passing runs.
