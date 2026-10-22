# Item level playtests

Run the server and client Luau files from temporary local playtest runners in their respective Roblox execution contexts, after player data and the character have loaded. Each file returns a summary and raises an assertion on failure. Use Roblox Studio MCP to start the playtest and inspect output; remove the temporary runners afterwards.

- Server checks cover all 42 items at levels below, equal to, and above their requirement, equip/assignment/selection validation, direct action denials, item preservation, early acquisition, and starter potion use. Modified player fields are restored.
- Client checks mount the actual Roact components with isolated inventory contexts at desktop and smaller screen sizes. They cover badges, details, button availability, drop targets, and live level updates, then remove the preview UI.

For networking smoke tests, run checks through local scripts so they share the running game's module context. Requiring server modules directly from MCP can create a separate module state.
