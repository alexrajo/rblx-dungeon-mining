---
name: codebase
description: Explains the codebase setup and architecture, as well as code style and conventions. This is used as a reference when generating code to ensure consistency across the project.
---

# Roblox Game Development — Code Reference Guide

This document captures the architecture, patterns, and conventions used across Roblox simulator-style games built with Rojo. Use it as a reference when generating code to ensure consistency.

---

## Toolchain

- **Rojo** (v7.6.1+): File sync between filesystem and Roblox Studio
- **Rokit**: Toolchain version manager (`rokit.toml`)
- **No external package manager** (no Wally): Dependencies are bundled directly in the project under `src/ReplicatedStorage/services/`
- **Luau**: All code is written in Luau (Roblox's typed Lua variant)

---

## Project Structure

```
default.project.json          # Rojo config — maps src/ to Roblox services
rokit.toml                    # Toolchain versions
src/
├── ReplicatedFirst/          # Scripts that run first on client (loading screens)
├── ReplicatedStorage/        # Shared between client and server
│   ├── services/             # Bundled libraries (APIService, ProfileService, Roact, Maid)
│   ├── local_services/       # Client-only service modules
│   ├── configs/              # Game configuration tables
│   ├── utils/                # Shared utility modules
│   ├── tutorials/            # Tutorial definitions (data-driven)
│   ├── effects/              # Visual effect templates
│   ├── area_ambiance/        # Per-area lighting configs
│   └── tools/                # Tool-specific client modules (e.g., pickaxe swing, weapon slash)
├── ServerScriptService/
│   ├── src/                  # Entry-point server scripts (.server.lua)
│   └── modules/              # Server module library
│       ├── api_endpoints/    # RemoteEvent/Function handler modules
│       ├── player_actions/   # Server-side action logic
│       ├── tag_handlers/     # CollectionService tag behavior modules
│       └── PlayerDataHandler/# Data persistence layer
├── ServerStorage/            # Server-only assets (NPCs, hidden models)
├── StarterGui/               # UI ScreenGuis
├── StarterPlayer/
│   ├── StarterCharacterScripts/
│   └── StarterPlayerScripts/
│       ├── ActionHandler/    # Client action system
│       │   └── actions/      # Individual action modules
│       └── gui/              # Client UI scripts
└── Workspace/                # Level/map content
```

### File Naming Conventions

| Type                | Convention                                         | Example                                     |
| ------------------- | -------------------------------------------------- | ------------------------------------------- |
| Server scripts      | `Name.server.lua`                                  | `API.server.lua`, `TagManager.server.lua`   |
| Client scripts      | `Name.client.lua`                                  | `init.client.lua`                           |
| Module scripts      | `Name.lua`                                         | `DatabaseClient.lua`, `StatCalculation.lua` |
| Folder entry points | `init.lua` / `init.client.lua` / `init.server.lua` | `ActionHandler/init.client.lua`             |

---

## Rojo Configuration

The `default.project.json` maps each top-level folder in `src/` to its corresponding Roblox service. All services use `$ignoreUnknownInstances: true` to allow Studio-only instances to coexist. StarterPlayer has nested mappings for `StarterCharacterScripts` and `StarterPlayerScripts`.

```json
{
  "name": "project",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "$ignoreUnknownInstances": true,
      "$path": "src/ReplicatedStorage"
    }
  }
}
```

---

## Naming Conventions

| Element         | Convention                                     | Example                                                                  |
| --------------- | ---------------------------------------------- | ------------------------------------------------------------------------ |
| Files / Modules | PascalCase                                     | `DatabaseClient.lua`, `StatCalculation.lua`                              |
| Functions       | camelCase (local), PascalCase (module methods) | `local function swingPickaxe()`, `StatCalculation.GetDamageMultiplier()` |
| Variables       | camelCase                                      | `local playerDataFolder`, `local chargeAmount`                           |
| Constants       | UPPER_SNAKE_CASE                               | `local RESPAWN_TIME = 10`, `local DATASTORE_PREFIX = "PlayerData1_"`     |
| Class names     | PascalCase                                     | `DatabaseClient`, `TagHandler`                                           |
| Private members | Prefixed with `_`                              | `self._connections`, `self._profile`                                     |
| Roblox services | Declared at top of file                        | `local ReplicatedStorage = game:GetService("ReplicatedStorage")`         |

---

## Code Patterns

### Pattern 1: Singleton Service Module

Used for stateless shared functionality. No constructor, no metatable.

```lua
local MyService = {}

function MyService.DoSomething(param: string): boolean
    -- implementation
    return true
end

return MyService
```

**Examples:** `APIService`, `StatCalculation`, `StatRetrieval`, `ActionFireService`, `ModuleLoader`

### Pattern 2: Class with Constructor (Metatable OOP)

Used for stateful objects that need multiple instances.

```lua
local MyClass = {}
MyClass.__index = MyClass

function MyClass.new(param: string)
    local self = {}
    setmetatable(self, MyClass)

    -- Private fields
    self._connections = {}
    self._data = param
    ----------------

    return self
end

function MyClass:GetData(): string
    return self._data
end

function MyClass:Destroy()
    -- cleanup
end

return MyClass
```

**Examples:** `DatabaseClient`, `Maid`

### Pattern 3: Tag Handler Module

Used with CollectionService for behavior attached to tagged instances.

```lua
local TagHandler = {}

function TagHandler.Apply(instance: Instance)
    -- Set up behavior on the instance
end

return TagHandler
```

**Examples:** `Interactable`, `Animated`, `AreaGate`, `RunningNPC`, `Collectible`, `Destructible`

### Pattern 4: API Endpoint Module

Used for server-side RemoteEvent/RemoteFunction handlers.

```lua
local endpoint = {}

function endpoint.Call(player: Player, ...)
    -- Validate, process, return result
    return true
end

return endpoint
```

**Examples:** `Upgrade`, `UseItem`, `CraftItem`, `EquipItem`

### Pattern 5: Client Action Module

Used in the ActionHandler system. Each action lives in its own folder under `actions/`.

```lua
local action = {}

function action.Activate(...)
    -- Perform action, play animation, fire remote
    return cooldownTime -- Return cooldown duration
end

return action
```

**Examples:** `PrimaryAction`, `ToggleAutoUse`

---

## Networking (Client-Server Communication)

### APIService — Custom Networking Layer

No framework (Knit, Flamework, etc.) is used. Instead, a custom `APIService` module abstracts RemoteEvent/RemoteFunction creation and discovery.

**Server-side (in a `.server.lua` entry script):**

```lua
local APIService = require(ReplicatedStorage.services.APIService)

-- Fire-and-forget (client → server)
APIService:CreateEventEndpoint("UseItem", function(player: Player, ...)
    -- handler
end)

-- Request-response (client → server → client)
APIService:CreateFunctionEndpoint("CraftItem", function(player: Player, ...)
    -- handler
    return result
end)
```

**Client-side:**

```lua
local APIService = require(ReplicatedStorage.services.APIService)

-- Fire event
APIService.GetEvent("UseItem"):FireServer(...)

-- Invoke function
local result = APIService.GetFunction("CraftItem"):InvokeServer(...)
```

### Endpoint Registration Pattern

All endpoints are registered in a single `API.server.lua` file that:

1. Requires all endpoint handler modules
2. Calls `APIService:CreateEventEndpoint()` or `APIService:CreateFunctionEndpoint()` for each

### Cross-Script Communication (Server-to-Server)

BindableEvents stored in `ServerStorage.CrossScriptCommunicationBindables` for decoupled server-to-server signaling.

```lua
local bindables = ServerStorage.CrossScriptCommunicationBindables
local myEvent = bindables.MyEvent

-- Fire
myEvent:Fire(player, data)

-- Listen
myEvent.Event:Connect(function(player, data)
    -- handle
end)
```

### Client Action Invocation

Client actions use BindableFunctions stored on the player instance:

```lua
local ActionFireService = require(ReplicatedStorage.local_services.ActionFireService)
ActionFireService.GetAction("PrimaryAction"):Invoke(...)
```

---

## Data Management

### ProfileService + DatabaseClient Wrapper

Player data is persisted using the bundled `ProfileService` library, wrapped by a custom `DatabaseClient` class.

**Profile Template** (defines the data schema):

```lua
return {
    Coins = 0,
    XP = 0,
    Level = 1,
    Inventory = {},                 -- {name = "ItemName", value = amount}
    EquippedItems = {},             -- {name = "SlotName", value = "ItemName"}
    TutorialStates = {{name = "Intro", value = false}},
}
```

**Key conventions:**

- DataStore key prefix: `"PlayerData1_" .. player.UserId`
- Tables use `{name = "key", value = val}` entries (not dictionary keys) for replication compatibility
- Data replicates to `ReplicatedStorage.PlayerData[PlayerName]` as ValueBase instances
- Numbers → `NumberValue`, Strings → `StringValue`, Booleans → `BoolValue`, Tables → `Folder`

**Reading data (client):**

```lua
local StatRetrieval = require(ReplicatedStorage.utils.StatRetrieval)
local coins = StatRetrieval.GetPlayerStat("Coins", player)
```

**Writing data (server only):**

```lua
local dbClient = PlayerDataHandler.GetClient(player)
dbClient:SetDataValue("Coins", newValue)
```

---

## CollectionService Tag System

Tags are applied to instances in Studio. A `TagManager.server.lua` script auto-loads all handler modules from `modules/tag_handlers/` and applies them.

**How it works:**

1. `TagManager` loads all modules from `tag_handlers/` by name
2. For every tag in the game, if a handler module with that name exists, `.Apply(instance)` is called
3. New instances getting a tag at runtime are handled via `GetInstanceAddedSignal`

**Tag handler modules must:**

- Be named exactly as the tag (e.g., tag `"Interactable"` → `Interactable.lua`)
- Export a table with an `.Apply(instance: Instance)` function

---

## Configuration System

Game configs live in `ReplicatedStorage/configs/` as pure data modules returning tables.

```lua
-- CraftingRecipes.lua
return {
    IronSword = { materials = { Iron = 8, Wood = 2 } },
    HealthPotion = { materials = { HealingHerb = 3, SlimeGel = 1 } },
}
```

**Self-loading config folders** (like `DropsConfig`) use `init.lua` to auto-require child modules:

```lua
local config = { itemDefinitions = { ... }, types = {} }

for _, m in pairs(script:GetChildren()) do
    if m:IsA("ModuleScript") then
        config.types[m.Name] = require(m)
    end
end

return config
```

---

## Module Loading

The `ModuleLoader` utility dynamically loads modules from folder hierarchies:

```lua
local ModuleLoader = require(ReplicatedStorage.utils.ModuleLoader)

-- Load immediate children only
local modules = ModuleLoader.shallowLoad(someFolder)

-- Load recursively (folders become nested tables)
local modules = ModuleLoader.deepLoad(someFolder, maxDepth)
```

---

## UI Framework

- **Roact** (bundled): React-like declarative UI library
- **Epic UI Pack**: Custom extended classes for common UI components (`ExtendBarClass`, `ExtendGuiButtonClass`, `ExtendGuiObjectClass`, `ExtendTextLabelClass`)
- UI scripts live in `StarterPlayer/StarterPlayerScripts/gui/`

Note: when developing gui, use the ModuleIndex setup where applicable, as script hierarchies aren't necessarily dependable when the gui is rendered as components when mounted

---

## Tutorial System

Tutorials are data-driven, defined as modules in `ReplicatedStorage/tutorials/`.

```lua
return {
    rewards = {},
    steps = {
        {
            id = "WelcomeStep",
            description = "Welcome! Click to continue.",
            completeOn = "click",
            pointToPositionFunction = function() return Vector3.new(0, 5, 0) end, -- optional
        },
    }
}
```

**Built-in signals:** `"click"`, `"useItem"`, `"primaryAction"`, `"interact"`, `"collectResource"`, or custom strings like `"openPage_CraftingPage"`.

Server-side `TutorialManager.server.lua` orchestrates step progression. Tutorial signals are routed via `ServerStorage.CrossScriptCommunicationBindables`.

---

## Common Utility Modules

| Module            | Location    | Purpose                                             |
| ----------------- | ----------- | --------------------------------------------------- |
| `StatCalculation` | `utils/`    | Level-based formula calculations                    |
| `StatRetrieval`   | `utils/`    | Read replicated player stats on client              |
| `ModuleLoader`    | `utils/`    | Dynamic module loading from folders                 |
| `TableUtils`      | `utils/`    | Table manipulation helpers                          |
| `LinAlg`          | `utils/`    | Linear algebra operations                           |
| `CameraShake`     | `utils/`    | Camera shake effects                                |
| `NumberFormatter` | `utils/`    | Number display formatting                           |
| `Welding`         | `utils/`    | Mesh welding utilities                              |
| `Maid`            | `services/` | Connection/instance cleanup (prevents memory leaks) |
| `APIService`      | `services/` | Client-server networking abstraction                |
| `ProfileService`  | `services/` | DataStore persistence library                       |

---

## Type Annotations

Use Luau type annotations on function signatures:

```lua
function MyService.DoThing(name: string, count: number): boolean
function MyClass.new(player: Player): MyClass
function handler(player: Player, data: {string}): ()
```

Type local variables when the type isn't obvious from context:

```lua
local maid: Maid = Maid.new()
local event: RemoteEvent = self._createEvent(name)
local dataValue: ValueBase | Folder = playerDataFolder:FindFirstChild(key)
```

---

## Common Idioms

### Service declarations at top of file

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
```

### Require chains

```lua
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local Configs = ReplicatedStorage.configs
local CraftingRecipes = require(Configs.CraftingRecipes)
```

### Debounce pattern

```lua
local debounce = {}
function onAction(player: Player)
    if debounce[player] then return end
    debounce[player] = true
    -- do work
    task.delay(cooldown, function()
        debounce[player] = nil
    end)
end
```

### Asset references

```lua
-- Animations
local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://ASSET_ID_HERE"

-- Images (in configs)
imageId = "ASSET_ID_HERE"  -- Just the numeric ID, without rbxassetid:// prefix
```

### Iterating children

```lua
for _, child in pairs(parent:GetChildren()) do
    if child:IsA("ModuleScript") then
        -- handle
    end
end
```

### Using Attributes for instance configuration

```lua
local reward = instance:GetAttribute("Reward")
instance:SetAttribute("Reward", 5)
local populationSize = instance:GetAttribute("PopulationSize")
```

---

## Anti-Patterns to Avoid

- **Do not use Knit, Flamework, or other frameworks** — use the custom APIService pattern
- **Do not use Wally** — bundle dependencies directly in `services/`
- **Do not store dictionaries in player data** — use `{name, value}` entry arrays for replication compatibility
- **Do not create RemoteEvents/Functions directly** — always go through APIService
- **Do not put server modules in ReplicatedStorage** — server-only code goes in `ServerScriptService/modules/`
- **Do not use `game.X` shorthand for services** — always use `game:GetService("X")`
  - Exception: `game.Players.LocalPlayer` and `game.Workspace` are acceptable in client scripts
- **Do not skip type annotations on function signatures**
