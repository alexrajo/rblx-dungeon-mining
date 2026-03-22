local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configs = ReplicatedStorage.configs
local CraftingRecipesConfig = require(Configs.CraftingRecipes)

local CraftingRecipeService = {}

function CraftingRecipeService.GetRecipeByName(name: string)
	for _, recipe in pairs(CraftingRecipesConfig) do
		if recipe.name == name then
			return recipe
		end
	end
	return nil
end

function CraftingRecipeService.GetAllRecipes()
	return CraftingRecipesConfig
end

function CraftingRecipeService.GetRecipesByCategory(category: string)
	local filtered = {}
	for _, recipe in pairs(CraftingRecipesConfig) do
		if recipe.category == category then
			table.insert(filtered, recipe)
		end
	end
	return filtered
end

return CraftingRecipeService
