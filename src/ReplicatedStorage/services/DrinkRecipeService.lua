local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configs = ReplicatedStorage.configs
local DrinkRecipesConfig = require(Configs.DrinkRecipes)

local DrinkRecipeService = {}

function DrinkRecipeService.GetRecipeFromName(name)
	for _, recipe in pairs(DrinkRecipesConfig) do
		if recipe.drinkName == name then
			return recipe
		end
	end
end

function DrinkRecipeService.GetAllRecipes()
	return DrinkRecipesConfig
end

return DrinkRecipeService
