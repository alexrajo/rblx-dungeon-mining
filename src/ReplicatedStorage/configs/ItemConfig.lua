local ItemConfig = {}

ItemConfig.DEFAULT_IMAGE_ID = "76280156712677"

ItemConfig.CATEGORY_GEAR = "Gear"
ItemConfig.CATEGORY_BOMB = "Bomb"
ItemConfig.CATEGORY_CONSUMABLE = "Consumable"

ItemConfig.items = {
	["Wood Pickaxe"] = { requiredLevel = 1, category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "114032635237765" },
	["Wood Sword"] = { requiredLevel = 1, category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "76034922098744" },
	["Wood Helmet"] = { requiredLevel = 1, category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Wood Chestplate"] = { requiredLevel = 1, category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Wood Leggings"] = { requiredLevel = 1, category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Wood Boots"] = { requiredLevel = 1, category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Copper Pickaxe"] = { requiredLevel = 3, category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "114032635237765" },
	["Copper Sword"] = { requiredLevel = 3, category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "89105765568068" },
	["Copper Helmet"] = { requiredLevel = 3, category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Copper Chestplate"] = { requiredLevel = 3, category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Copper Leggings"] = { requiredLevel = 3, category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Copper Boots"] = { requiredLevel = 3, category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Iron Pickaxe"] = { requiredLevel = 6, category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "108606581190884" },
	["Iron Sword"] = { requiredLevel = 6, category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "111950185917024" },
	["Iron Helmet"] = { requiredLevel = 6, category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Iron Chestplate"] = { requiredLevel = 6, category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Iron Leggings"] = { requiredLevel = 6, category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Iron Boots"] = { requiredLevel = 6, category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Gold Pickaxe"] = { requiredLevel = 10, category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "103027523455339" },
	["Gold Sword"] = { requiredLevel = 10, category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "91563305913237" },
	["Gold Helmet"] = { requiredLevel = 10, category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Gold Chestplate"] = { requiredLevel = 10, category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Gold Leggings"] = { requiredLevel = 10, category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Gold Boots"] = { requiredLevel = 10, category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Diamond Pickaxe"] = { requiredLevel = 15, category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "135622329861072" },
	["Diamond Sword"] = { requiredLevel = 15, category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "108751817855245" },
	["Diamond Helmet"] = { requiredLevel = 15, category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Diamond Chestplate"] = { requiredLevel = 15, category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Diamond Leggings"] = { requiredLevel = 15, category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Diamond Boots"] = { requiredLevel = 15, category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Obsidian Pickaxe"] = { requiredLevel = 20, category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "70578331422402" },
	["Obsidian Sword"] = { requiredLevel = 20, category = ItemConfig.CATEGORY_GEAR, slot = "Weapon" },
	["Obsidian Helmet"] = { requiredLevel = 20, category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Obsidian Chestplate"] = { requiredLevel = 20, category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Obsidian Leggings"] = { requiredLevel = 20, category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Obsidian Boots"] = { requiredLevel = 20, category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Mini Bomb"] = { requiredLevel = 1, category = ItemConfig.CATEGORY_BOMB, slot = "Bomb", stackable = true, imageId = "114615443431858" },
	["Big Bomb"] = { requiredLevel = 6, category = ItemConfig.CATEGORY_BOMB, slot = "Bomb", stackable = true, imageId = "88682277441307" },
	["Mega Bomb"] = { requiredLevel = 12, category = ItemConfig.CATEGORY_BOMB, slot = "Bomb", stackable = true, imageId = "114615443431858" },

	["Health Potion"] = { requiredLevel = 1, category = ItemConfig.CATEGORY_CONSUMABLE, slot = "Consumable", stackable = true, imageId = "88490528639781" },
	["Speed Potion"] = { requiredLevel = 5, category = ItemConfig.CATEGORY_CONSUMABLE, slot = "Consumable", stackable = true },
	["Strength Potion"] = { requiredLevel = 5, category = ItemConfig.CATEGORY_CONSUMABLE, slot = "Consumable", stackable = true },
}

function ItemConfig.GetItemData(itemName: string?)
	return ItemConfig.items[itemName]
end

function ItemConfig.GetRequiredLevel(itemName: string?): number
	local item = ItemConfig.GetItemData(itemName)
	return item and item.requiredLevel or 1
end

function ItemConfig.MeetsLevelRequirement(itemName: string?, playerLevel: number): boolean
	return playerLevel >= ItemConfig.GetRequiredLevel(itemName)
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
