local IntroTutorial = {
	rewards = {},
	steps = {
		{
			id = "Welcome",
			description = "Welcome to Dungeon Mining! This tutorial will teach you the basics to get you started.",
			completeOn = "click"
		},
		{
			id = "MineEntrance",
			description = "Head to the mine entrance to begin your adventure!",
			completeOn = "enterMine"
		},
		{
			id = "MineOre",
			description = "Click on an ore node to mine it with your pickaxe. Press 'Mine' or the key shown on screen.",
			completeOn = "mine"
		},
		{
			id = "CollectOre",
			description = "Great job! Pick up the ore that dropped. You can find it in your inventory.",
			completeOn = "getItem"
		},
		{
			id = "FindLadder",
			description = "Now find the ladder on this floor and touch it to descend deeper into the mine!",
			completeOn = "descend"
		},
		{
			id = "IntroEnd",
			description = "You're all set! Mine ores, fight monsters, and craft better gear to go deeper. Good luck, miner!",
			completeOn = "click"
		},
	}
}

return IntroTutorial
