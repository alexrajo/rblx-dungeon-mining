local ItemConfig = {}

ItemConfig.DEFAULT_IMAGE_ID = "76280156712677"

ItemConfig.CATEGORY_GEAR = "Gear"
ItemConfig.CATEGORY_BOMB = "Bomb"
ItemConfig.CATEGORY_CONSUMABLE = "Consumable"

ItemConfig.items = {
	["Wood Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", tier = 1, imageId = "114032635237765" },
	["Wood Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", tier = 1, imageId = "76034922098744" },
	["Wood Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet", tier = 1 },
	["Wood Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate", tier = 1 },
	["Wood Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings", tier = 1 },
	["Wood Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots", tier = 1 },

	["Copper Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", tier = 2, imageId = "114032635237765" },
	["Copper Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", tier = 2, imageId = "89105765568068" },
	["Copper Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet", tier = 2 },
	["Copper Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate", tier = 2 },
	["Copper Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings", tier = 2 },
	["Copper Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots", tier = 2 },

	["Iron Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", tier = 3, imageId = "108606581190884" },
	["Iron Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", tier = 3, imageId = "111950185917024" },
	["Iron Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet", tier = 3 },
	["Iron Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate", tier = 3 },
	["Iron Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings", tier = 3 },
	["Iron Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots", tier = 3 },

	["Gold Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", tier = 4, imageId = "103027523455339" },
	["Gold Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", tier = 4, imageId = "91563305913237" },
	["Gold Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet", tier = 4 },
	["Gold Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate", tier = 4 },
	["Gold Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings", tier = 4 },
	["Gold Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots", tier = 4 },

	["Diamond Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", tier = 5, imageId = "135622329861072" },
	["Diamond Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", tier = 5, imageId = "108751817855245" },
	["Diamond Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet", tier = 5 },
	["Diamond Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate", tier = 5 },
	["Diamond Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings", tier = 5 },
	["Diamond Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots", tier = 5 },

	["Obsidian Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", tier = 6, imageId = "70578331422402" },
	["Obsidian Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", tier = 6 },
	["Obsidian Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet", tier = 6 },
	["Obsidian Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate", tier = 6 },
	["Obsidian Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings", tier = 6 },
	["Obsidian Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots", tier = 6 },

	["Mini Bomb"] = { category = ItemConfig.CATEGORY_BOMB, slot = "Bomb", stackable = true, imageId = "114615443431858" },
	["Big Bomb"] = { category = ItemConfig.CATEGORY_BOMB, slot = "Bomb", stackable = true, imageId = "88682277441307" },
	["Mega Bomb"] = { category = ItemConfig.CATEGORY_BOMB, slot = "Bomb", stackable = true, imageId = "114615443431858" },

	["Health Potion"] = { category = ItemConfig.CATEGORY_CONSUMABLE, slot = "Consumable", stackable = true, imageId = "88490528639781" },
	["Speed Potion"] = { category = ItemConfig.CATEGORY_CONSUMABLE, slot = "Consumable", stackable = true },
	["Strength Potion"] = { category = ItemConfig.CATEGORY_CONSUMABLE, slot = "Consumable", stackable = true },
}

function ItemConfig.GetItemData(itemName: string?)
	return ItemConfig.items[itemName]
end

function ItemConfig.GetSlotForItem(itemName: string?): string?
	local item = ItemConfig.items[itemName]
	if item ~= nil then
		return item.slot
	end

	return nil
end

function ItemConfig.GetImageIdForItem(itemName: string?): string
	local item = ItemConfig.items[itemName]
	if item and item.imageId ~= nil then
		return item.imageId
	end

	return ItemConfig.DEFAULT_IMAGE_ID
end

function ItemConfig.IsStackable(itemName: string?): boolean
	local item = ItemConfig.items[itemName]
	return item ~= nil and item.stackable == true
end

function ItemConfig.IsCategory(itemName: string?, category: string): boolean
	local item = ItemConfig.items[itemName]
	return item ~= nil and item.category == category
end

function ItemConfig.GetItemsForSlot(slotName: string): {string}
	local items = {}
	for itemName, itemData in pairs(ItemConfig.items) do
		if itemData.slot == slotName then
			table.insert(items, itemName)
		end
	end
	table.sort(items)
	return items
end

return ItemConfig
