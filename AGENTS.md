# Repository Guidelines

## Project Structure & Module Organization

`src/` mirrors the Roblox data model defined in `default.project.json`. Core shared code lives in `src/ReplicatedStorage/`:
`services/` for bundled libraries such as `APIService`, `ProfileService`, `Roact`, and `Maid`
`configs/` for pure data tables like ore, gear, enemy, and crafting definitions
`utils/` and `local_services/` for reusable helpers

Server logic is split between `src/ServerScriptService/src/` entry scripts and `src/ServerScriptService/modules/` feature modules such as `api_endpoints/`, `tag_handlers/`, and `PlayerDataHandler/`. Client logic lives under `src/StarterPlayer/StarterPlayerScripts/`, especially `ActionHandler/` and `gui/`. Assets and mapped instances live in folders such as `src/Workspace/`, `src/StarterGui/`, and `src/ServerStorage/`.

## Build, Test, and Development Commands

Run `rokit install` once to install the pinned toolchain from `rokit.toml`.

Run `rojo serve` to sync the filesystem into Roblox Studio during development.

Run `rojo build -o build.rbxlx` to produce a place file for inspection or export.

This repository does not currently define a project-wide test runner, linter, or CI pipeline.

## Coding Style & Naming Conventions

Use Luau with service declarations at the top of each file via `game:GetService("...")`. Match the existing style: tabs are common, local variables use `camelCase`, modules and component names use `PascalCase`, and constants use `UPPER_SNAKE_CASE`. Prefer typed function signatures where practical.

Keep server-only code in `ServerScriptService/modules/`; do not move sensitive logic into `ReplicatedStorage`. For CollectionService handlers, the filename should match the tag exactly, for example `tag_handlers/OreNode.lua`.

## Testing Guidelines

There is no formal app test suite yet. Validate changes in Roblox Studio through `rojo serve`, then smoke-test the affected gameplay flow. Existing `*.spec.lua` files under `src/ReplicatedStorage/services/Roact/` are vendored library tests and should not be treated as coverage for game code.

## Commit & Pull Request Guidelines

Recent history follows Conventional Commit prefixes such as `feat:`, `fix:`, and `chore:`. Keep subjects short and imperative, for example `fix: prevent mining hit desync`.

Pull requests should describe player-facing behavior changes, list touched systems, and include Studio screenshots or short clips for UI or animation work. Link related issues when available and note any manual test steps reviewers should repeat.

## Project specific skills

There are project specific skills, or instructions, inside .claude/skills. When implkementing features, first look into the skills to know how to structure the code and the project in general, and to get guidance on the game idea and direction.
