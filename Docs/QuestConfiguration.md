# Quest Configuration

Quests are configured in `src/ReplicatedStorage/configs/QuestConfig.lua`.

Quest IDs are stable references used by code, prerequisites, and activation bricks. The title is display text and can be changed without breaking quest references.

## Quest Fields

Each quest entry is keyed by its quest ID and should include:

```lua
some_quest_id = {
	id = "some_quest_id",
	title = "Quest Title",
	description = "Full quest description shown in the quest log.",
	repeatable = false,
	requirements = {},
	objectives = {},
	rewards = {},
}
```

- `id`: Stable string ID. Keep this in sync with the table key.
- `title`: Player-facing quest name.
- `description`: Full quest log description.
- `repeatable`: `true` allows the quest to be started again after claiming. `false` makes it one-time.
- `requirements`: Optional activation requirements.
- `objectives`: List of objective tables.
- `rewards`: Coins, XP, and items granted when the player claims the completed quest.

## Requirements

Use `completedQuests` to require quest completions by quest ID:

```lua
requirements = {
	completedQuests = { "mine_stone_01" },
}
```

This checks completion history, not the title.

## Objective Types

Use `QuestConfig.objectiveTypes` constants when possible.

### collectItem

Tracks item collection for a specific item.

```lua
{
	id = "collect_stone",
	type = QuestConfig.objectiveTypes.COLLECT_ITEM,
	targetName = "Stone",
	targetAmount = 10,
	text = "Collect 10 Stone",
}
```

Fields:

- `id`: Stable objective ID unique within the quest.
- `type`: `QuestConfig.objectiveTypes.COLLECT_ITEM`.
- `targetName`: Item name as stored in inventory.
- `targetAmount`: Required amount.
- `text`: Player-facing objective text.
- `countMode`: Optional collection counting behavior.

Collection count modes:

```lua
countMode = QuestConfig.collectCountModes.GAINED_SINCE_START
```

`GAINED_SINCE_START` is the default. Existing items do not count when the quest starts. Only positive inventory gains after quest activation increase progress. Spending or selling items later does not reduce progress.

```lua
countMode = QuestConfig.collectCountModes.CURRENT_TOTAL
```

`CURRENT_TOTAL` uses the player's current inventory count. Existing items can complete the quest immediately, and progress follows current possession.

### killEnemy

Tracks enemy kills by enemy type.

```lua
{
	id = "kill_slimes",
	type = QuestConfig.objectiveTypes.KILL_ENEMY,
	targetName = "Cave Slime",
	targetAmount = 3,
	text = "Defeat 3 Cave Slimes",
}
```

### reachFloor

Tracks the maximum mine floor reached.

```lua
{
	id = "reach_floor_5",
	type = QuestConfig.objectiveTypes.REACH_FLOOR,
	targetAmount = 5,
	text = "Reach Floor 5",
}
```

## Rewards

Rewards are granted only when the player claims a completed quest in the quest UI.

```lua
rewards = {
	coins = 50,
	xp = 35,
	items = {
		["Mini Bomb"] = 2,
		Copper = 5,
	},
}
```

- `coins`: Number of coins to grant.
- `xp`: Amount of XP to grant.
- `items`: Map of item name to amount.

## Activation

Quests can be started from server code through:

```lua
QuestService.StartQuest(player, "mine_stone_01")
```

They can also be started from a tagged brick:

1. Add the `QuestActivationBrick` tag to a part or model.
2. Set its `questId` attribute to a configured quest ID.
3. The tag handler inserts a `ProximityPrompt` that starts the quest for the activating player.

## Runtime Behavior

- Starting a quest makes it active and tracks it by default.
- Players can track, untrack, abandon, or claim from the quest UI.
- Completed quests remain in the Active tab until their reward is claimed.
- Completed but unclaimed quests cannot be abandoned.
- Claimed one-time quests cannot be started again.
- Claimed repeatable quests can be started again.
