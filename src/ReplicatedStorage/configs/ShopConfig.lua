local ShopConfig = {
	ResourceShop = {
		displayName = "General Store",
		type = "resource",
		items = {
			["Health Potion"] = 20,
			["Speed Potion"] = 25,
			["Strength Potion"] = 30,
			Wood = 3,
			["Healing Herb"] = 5,
		},
	},
	GearShop = {
		displayName = "Blacksmith",
		type = "gear",
		items = {
			["Mini Bomb"] = 5,
            ["Big Bomb"] = 15,
            ["Mega Bomb"] = 20,
		},
	},
}

return ShopConfig
