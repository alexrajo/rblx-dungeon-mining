local ItemConfig = {}

ItemConfig.DEFAULT_IMAGE_ID = "76280156712677"

ItemConfig.CATEGORY_GEAR = "Gear"
ItemConfig.CATEGORY_BOMB = "Bomb"
ItemConfig.CATEGORY_CONSUMABLE = "Consumable"

ItemConfig.items = {
	["Wood Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "114032635237765" },
	["Wood Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "76034922098744" },
	["Wood Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Wood Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Wood Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Wood Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Copper Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "114032635237765" },
	["Copper Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "89105765568068" },
	["Copper Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Copper Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Copper Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Copper Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Iron Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "108606581190884" },
	["Iron Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "111950185917024" },
	["Iron Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Iron Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Iron Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Iron Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Gold Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "103027523455339" },
	["Gold Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "91563305913237" },
	["Gold Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Gold Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Gold Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Gold Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Diamond Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "135622329861072" },
	["Diamond Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon", imageId = "108751817855245" },
	["Diamond Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Diamond Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Diamond Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Diamond Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

	["Obsidian Pickaxe"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Pickaxe", imageId = "70578331422402" },
	["Obsidian Sword"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Weapon" },
	["Obsidian Helmet"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Helmet" },
	["Obsidian Chestplate"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Chestplate" },
	["Obsidian Leggings"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Leggings" },
	["Obsidian Boots"] = { category = ItemConfig.CATEGORY_GEAR, slot = "Boots" },

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
