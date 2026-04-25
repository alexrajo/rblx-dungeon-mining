---
name: game
description: Explains the game idea and the design decisions for Dungeon Mining, a Roblox mining/crafting/combat game inspired by Stardew Valley's mines. This is the authoritative reference for what to build.
---

# Dungeon Mining — Game Design Reference

This document defines the game design for **Dungeon Mining**, a Roblox mining/crafting/combat game inspired by Stardew Valley's mines. Use this as the authoritative reference for what to build. For code patterns and architecture, see `skills/codebase/SKILL.md`.

> **Legacy note:** This project was cloned from a burping simulator. All existing burp, drink, and ingredient systems are **scaffolding to be replaced** — do not extend them. The underlying architecture (APIService, tag handlers, ProfileService, Roact UI, CollectionService patterns) is valid and should be reused.

---

## Game Overview

- **Title:** Dungeon Mining
- **Platforms:** PC, Mobile, Tablet, Console (via Roblox)
- **Core Fantasy:** The player is a bold explorer descending into increasingly dangerous mines, becoming more powerful with each expedition.
- **Inspiration:** Stardew Valley mines — layered dungeon with escalating difficulty, ore collection, monster combat, and gear progression.

---

## Core Game Loop

1. Player starts in the **Hub Area** (surface camp/town).
2. Player enters the mine and descends to a **mine layer**.
3. Player **mines ore nodes** to collect resources using pickaxes with explicit mining power.
4. Player **fights monsters** that guard deeper areas or spawn over time.
5. Player discovers **hidden ladders** to descend to the next floor.
6. Player returns to the Hub Area to **craft** upgraded tools, weapons, and armor.
7. Player uses better equipment to survive deeper layers.
8. **Repeat** — each layer is harder but yields better ore and rewards.

**Checkpoints** are placed every **5 floors** within a layer, allowing players to resume from that depth.

---

## Mine Layers & Progression

The mine is divided into 6 distinct layers. Each layer spans multiple floors, with escalating enemy danger and richer resources.

| Layer | Name            | Theme                                   | Floors | Primary Ore | Secondary Ore |
| ----- | --------------- | --------------------------------------- | ------ | ----------- | ------------- |
| 1     | Shallow Mines   | Rocky caves, dim torchlight             | 1–15   | Copper      | Stone         |
| 2     | Copper Caves    | Orange-tinted tunnels, dripping water   | 16–30  | Iron        | Copper        |
| 3     | Iron Depths     | Dark narrow tunnels, rusted supports    | 31–50  | Gold        | Iron          |
| 4     | Golden Caverns  | Glittering walls, underground rivers    | 51–70  | Diamond     | Gold          |
| 5     | Crystal Hollows | Bioluminescent crystals, open chambers  | 71–90  | Obsidian    | Diamond       |
| 6     | Obsidian Core   | Lava flows, volcanic rock, intense heat | 91–120 | Mythril     | Obsidian      |

Each layer is **procedurally generated** — floor layouts, ore placement, enemy spawns, and ladder locations are randomized each run.

---

## Ore & Resource System

### Ore Table

| Ore      | Layer Found | Rarity    | Base Value (Coins) |
| -------- | ----------- | --------- | ------------------ |
| Stone    | All layers  | Common    | 1                  |
| Copper   | Layer 1+    | Common    | 5                  |
| Iron     | Layer 2+    | Common    | 12                 |
| Gold     | Layer 3+    | Uncommon  | 25                 |
| Diamond  | Layer 4+    | Rare      | 60                 |
| Obsidian | Layer 5+    | Rare      | 120                |
| Mythril  | Layer 6     | Very Rare | 250                |

### Other Resources

| Resource      | Source                 | Use                     |
| ------------- | ---------------------- | ----------------------- |
| Wood          | Hub Area (trees, shop) | Crafting handles/shafts |
| Slime Gel     | Slime drops            | Crafting potions        |
| Bat Wing      | Bat drops              | Crafting potions        |
| Bone Fragment | Skeleton drops         | Crafting weapons        |
| Fire Essence  | Layer 6 enemies        | Crafting late-game gear |
| Healing Herb  | Found on mine floors   | Crafting health potions |

---

## Gear Progression

### Gear Stats Overview

Gear progression comes from explicit per-item stats in `GearConfig`, not from shared material-wide stat tables.

| Material | Pickaxe Power | Weapon Damage | Armor Defense |
| -------- | ------------- | ------------- | ------------- |
| Wood     | 1             | 5             | 2             |
| Copper   | 2             | 10            | 5             |
| Iron     | 3             | 18            | 10            |
| Gold     | 4             | 28            | 16            |
| Diamond  | 5             | 40            | 24            |
| Obsidian | 6             | 55            | 34            |

### Equipment Slots

- **Pickaxe** — determines mining damage and mining speed
- **Weapon** (Sword) — determines melee damage
- **Helmet** — defense contribution
- **Chestplate** — defense contribution (largest)
- **Boots** — defense contribution + movement speed bonus

---

## Mining Mechanics

- **Click/tap** an ore node to swing the pickaxe.
- Ore nodes have an **HP bar** that decreases with each hit. HP scales by ore type.
- **Mining power** from the equipped pickaxe item determines damage per swing to the ore node.
- Mined ore goes directly into the player's **inventory**.
- Ore nodes **respawn** after a configurable timer (server-side).
- **Hold to auto-mine** on mobile/controller for accessibility.

### Ore Node HP by Ore Type

| Ore      | Node HP | Hits with Matching Pickaxe |
| -------- | ------- | -------------------------- |
| Stone    | 2       | 2                          |
| Copper   | 4       | 2                          |
| Iron     | 6       | 2                          |
| Gold     | 8       | 2                          |
| Diamond  | 12      | 3                          |
| Obsidian | 15      | 3                          |
| Mythril  | 18      | 3                          |

---

## Crafting System

### Crafting Location

Crafting is done at a **Workbench** in the Hub Area. Players cannot craft inside the mines.

### Craftable Categories

1. **Tools** — Pickaxes (required for mining progression)
2. **Weapons** — Swords (melee combat damage)
3. **Armor** — Helmet, Chestplate, Boots (defense)
4. **Consumables** — Health Potions, Buff Potions

### Example Recipes

| Item              | Ingredients                    | Result              |
| ----------------- | ------------------------------ | ------------------- |
| Copper Pickaxe    | 8x Copper, 3x Wood             | Copper Pickaxe      |
| Copper Sword      | 6x Copper, 2x Wood             | Copper Weapon       |
| Copper Helmet     | 5x Copper                      | Copper Helmet       |
| Copper Chestplate | 10x Copper                     | Copper Chestplate   |
| Copper Boots      | 6x Copper                      | Copper Boots        |
| Iron Pickaxe      | 10x Iron, 3x Wood              | Iron Pickaxe        |
| Iron Sword        | 8x Iron, 2x Wood               | Iron Weapon         |
| Iron Helmet       | 7x Iron                        | Iron Helmet         |
| Iron Chestplate   | 14x Iron                       | Iron Chestplate     |
| Iron Boots        | 8x Iron                        | Iron Boots          |
| Health Potion     | 3x Healing Herb, 1x Slime Gel  | Restores 30 HP      |
| Speed Potion      | 2x Healing Herb, 2x Bat Wing   | +20% speed for 30s  |
| Strength Potion   | 2x Bone Fragment, 1x Slime Gel | +25% damage for 30s |

_Pattern: Each material family follows the same recipe structure with its ore. Quantities increase slightly for later materials._

---

## Combat System

### Combat Mechanics

- **Click/tap** to swing weapon (melee attack).
- Weapons have a **swing animation** and **cooldown** between attacks (approx 0.5s).
- Damage dealt = **Weapon Damage + Base Damage − Enemy Defense**.
- Damage taken = **Enemy Damage − Player Defense** (minimum 1).
- Players have a brief **invulnerability window** (0.5s) after being hit.
- **No stamina system** — players can always attack and mine.
- On death, player respawns at the **last checkpoint** (loses no items, but must re-traverse floors).

### Player Stats

| Stat         | Base Value | Scaling           |
| ------------ | ---------- | ----------------- |
| Health       | 100        | +5 per level      |
| Base Damage  | 2          | +1 per level      |
| Defense      | 0          | From armor only   |
| Mining Power | 1          | From pickaxe only |
| Move Speed   | 16         | From boots bonus  |

### Enemies by Layer

| Enemy           | Layer | HP  | Damage | Defense | Behavior                                    | Drops                        |
| --------------- | ----- | --- | ------ | ------- | ------------------------------------------- | ---------------------------- |
| Cave Slime      | 1     | 15  | 5      | 0       | Wanders, aggros on proximity                | Slime Gel, Coins             |
| Cave Bat        | 1     | 10  | 8      | 0       | Flies, swoops at player                     | Bat Wing, Coins              |
| Goblin          | 2     | 30  | 12     | 3       | Patrols, charges when aggro'd               | Coins, Iron Ore              |
| Shadow Bat      | 2     | 20  | 15     | 2       | Fast, swoops in darkness                    | Bat Wing, Coins              |
| Skeleton        | 3     | 50  | 18     | 5       | Ranged bone throw + melee                   | Bone Fragment, Coins         |
| Rock Golem      | 3     | 80  | 15     | 12      | Slow, high defense, slam attack             | Stone, Gold Ore, Coins       |
| Gold Guardian   | 4     | 100 | 25     | 10      | Defends gold nodes, enrages at low HP       | Gold Ore, Coins              |
| Crystal Spider  | 4     | 60  | 30     | 5       | Fast, web slows player                      | Diamond, Coins               |
| Lava Slime      | 5     | 90  | 28     | 8       | Leaves fire trail, splits on death          | Slime Gel, Obsidian, Coins   |
| Obsidian Knight | 5     | 150 | 35     | 20      | Shield blocks frontal attacks, sword combos | Obsidian, Coins              |
| Fire Elemental  | 6     | 120 | 40     | 10      | Ranged fireballs, area denial               | Fire Essence, Coins          |
| Magma Wyrm      | 6     | 200 | 45     | 15      | Burrows, emerges for surprise attacks       | Fire Essence, Mythril, Coins |

### Enemy AI Behaviors

- **Wander:** Moves randomly until player enters aggro range.
- **Patrol:** Follows a set path, aggros on sight.
- **Aggro:** Moves toward player and attacks when in range.
- **Enrage:** Increased speed/damage when below 25% HP.
- **Ranged:** Attacks from distance, retreats if player gets close.

---

## Economy & Rewards

### Currency

**Coins** — the single in-game currency.

### Sources of Income

| Source                 | Amount                                  |
| ---------------------- | --------------------------------------- |
| Selling ores           | Varies by ore type (see ore table)      |
| Monster drops          | 2–15 coins per kill (scales with layer) |
| Floor completion bonus | 10 coins per floor                      |
| Layer boss reward      | 100–500 coins (scales with layer)       |

### Spending (Sinks)

| Sink                                     | Cost Range     |
| ---------------------------------------- | -------------- |
| Crafting blueprints (unlock new recipes) | 50–500 coins   |
| Health Potions (from shop)               | 15 coins       |
| Buff Potions (from shop)                 | 30 coins       |
| Checkpoint teleport (skip floors)        | 20 coins       |
| Cosmetics (hats, trail effects)          | 100–1000 coins |

---

## World & Hub Area

### Hub Area Layout

The Hub Area is the surface safe zone. It contains:

- **Spawn Point** — where players arrive and respawn
- **Workbench** — crafting station for tools, weapons, armor, consumables
- **Shop NPC** — sells basic consumables, crafting blueprints, cosmetics
- **Sell NPC / Crate** — sell ores and items for coins
- **Mine Entrance** — portal/elevator to enter the mines
- **Checkpoint Board** — select which checkpoint floor to start from
- **Storage Chest** — overflow item storage

### Mine Entrance

Players enter the mine through a central entrance. They can choose to start from floor 1 or any unlocked checkpoint.

---

## UI & HUD

### In-Mine HUD

- **Health bar** — top-left, shows current/max HP
- **Depth indicator** — shows current floor number and layer name (e.g. "Floor 23 — Iron Depths")
- **Hotbar** — bottom-center, shows equipped pickaxe, weapon, and consumable slots
- **Minimap** — top-right, shows explored areas of current floor, ore nodes, ladder position (once discovered)
- **Enemy health bar** — appears above enemies when damaged

### Hub Area UI

- **Inventory screen** — grid display of all items, quantities, and equip options
- **Crafting UI** — recipe list filtered by category, shows required ingredients and whether player has them
- **Shop UI** — buy/sell interface with item previews
- **Checkpoint selector** — list of unlocked floors with teleport option

---

## Player Data Schema

These fields replace the existing burp-related ProfileTemplate. Use the same `{name, value}` entry array pattern for tables (per codebase SKILL.md conventions).

```
Coins = 0,
XP = 0,
Level = 1,
MaxFloorReached = 0,
UnlockedCheckpoints = {},         -- array of floor numbers
Inventory = {},                   -- {name = "Copper", amount = 5}
EquippedPickaxe = "Wood Pickaxe",
EquippedWeapon = "Wood Sword",
EquippedHelmet = "",
EquippedChestplate = "",
EquippedBoots = "",
UnlockedRecipes = {},             -- array of recipe names
TutorialStates = {{name = "Intro", value = false}},
```

---

## XP & Leveling

- **XP sources:** Mining ore (+5–25 XP by ore type), killing enemies (+10–50 XP by layer), completing floors (+20 XP)
- **Level-up formula:** `requiredXP = 100 * level * (1.2 ^ (level - 1))`
- **Level rewards:** +5 Max HP, +1 Base Damage per level
- **Max level:** 50 (soft cap — XP continues but rewards diminish)

---

## Open Design Questions

These decisions are not yet finalized. Flag them when relevant during implementation:

- [ ] Should mine floors be fully procedural or use hand-designed templates with procedural variation?
- [ ] How many floors per layer at launch? (Current default: 15–30 per layer, 120 total)
- [ ] Should there be **layer bosses** at the end of each layer?
- [ ] Should items drop on death or only progress be lost?
- [ ] Is there a **backpack capacity limit** or unlimited inventory?
- [ ] Should crafting require unlocking blueprints first or are all recipes available?
- [ ] Multiplayer: should players share mine instances or each get their own?
- [ ] Mobile controls: virtual joystick + tap targets, or different scheme?
- [ ] Should there be a **pet/companion** system?
- [ ] Gamepass/monetization: what premium features (2x XP, extra inventory, cosmetics)?

---

## Out of Scope (v0.1)

These features are intentionally excluded from the first version:

- Trading between players
- Guilds/clans
- PvP combat
- Fishing or farming side-activities
- Housing/base building
- Leaderboards
- Daily quests/battle pass
- Pet/companion system
- Enchanting/gem socketing

---

## Inspiration Reference

**Stardew Valley Mines** — the primary inspiration. Key elements to capture:

- Descending floor-by-floor through a mine
- Finding ladders (sometimes hidden under rocks) to go deeper
- Each floor has ores to mine and enemies to fight
- Distinct visual themes as you go deeper (earth → ice → lava)
- Checkpoints at milestone floors (every 5)
- Returning to surface to craft and upgrade before going deeper
- Escalating difficulty creating a satisfying progression loop
