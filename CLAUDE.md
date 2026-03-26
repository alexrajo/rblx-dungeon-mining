# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Install toolchain (first time setup)
rokit install

# Start Rojo dev server (syncs filesystem to Roblox Studio)
rojo serve

# Build place file
rojo build -o build.rbxlx
```

There is no test framework, linter, or CI pipeline configured.

## Architecture Overview

This is a Roblox game project (**Dungeon Mining**) built with **Rojo** and **Luau**. No frameworks (Knit, Flamework) or package managers (Wally) are used — dependencies are bundled in `src/ReplicatedStorage/services/`.

For detailed architecture, code patterns, and conventions, use the `/codebase` skill. For game design reference, use the `/game` skill.

### Key Architectural Decisions

- **Networking**: Custom `APIService` module wraps RemoteEvents/RemoteFunctions. All endpoints registered in `ServerScriptService/src/API.server.lua`. Never create RemoteEvents directly.
- **Data**: `ProfileService` + `DatabaseClient` wrapper. Player data uses `{name, value}` entry arrays (not dictionaries) for replication. Data replicates to `ReplicatedStorage.PlayerData` as ValueBase instances.
- **Tags**: CollectionService tag handlers in `ServerScriptService/modules/tag_handlers/`. Handler filename must match the tag name exactly. Each exports `.Apply(instance)`.
- **Client actions**: `StarterPlayerScripts/ActionHandler/actions/` — each action module exports `.Activate(...)` returning cooldown duration.
- **Configs**: Pure data tables in `ReplicatedStorage/configs/`.

### Source Layout

| Directory | Purpose |
|---|---|
| `ReplicatedStorage/services/` | Bundled libs (APIService, ProfileService, Roact, Maid) |
| `ReplicatedStorage/configs/` | Game config tables (ores, gear, enemies, recipes, layers) |
| `ReplicatedStorage/utils/` | Shared utilities (StatCalculation, StatRetrieval, ModuleLoader, etc.) |
| `ServerScriptService/src/` | Server entry scripts |
| `ServerScriptService/modules/` | Server modules (api_endpoints, tag_handlers, PlayerDataHandler) |
| `StarterPlayerScripts/ActionHandler/` | Client action system |
| `StarterPlayerScripts/gui/` | Client UI scripts |

## Critical Conventions

- Always use `game:GetService("X")` — never `game.X` (exception: `game.Players.LocalPlayer`, `game.Workspace` in client scripts)
- Type-annotate all function signatures with Luau types
- PascalCase for files/modules/classes/module methods; camelCase for local functions/variables; UPPER_SNAKE_CASE for constants; `_` prefix for private members
- Roblox service declarations go at the top of every file
- Server-only code belongs in `ServerScriptService/modules/`, never in `ReplicatedStorage`
