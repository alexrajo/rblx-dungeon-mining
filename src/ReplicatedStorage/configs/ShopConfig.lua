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
			["Copper Pickaxe"] = 50,
			["Copper Sword"] = 40,
			["Copper Helmet"] = 30,
			["Copper Chestplate"] = 60,
			["Copper Leggings"] = 40,
			["Copper Boots"] = 35,
		},
	},
}

return ShopConfig
