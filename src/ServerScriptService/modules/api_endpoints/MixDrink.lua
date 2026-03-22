local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local DrinkRecipeService = require(Services.DrinkRecipeService)

local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local endpoint = {}

function endpoint.Call(player: Player, recipeName: string)
	print(player, "wants to mix drink with recipe: "..recipeName.."!")
	local ingredients = PlayerDataHandler.GetOwnedIngredients(player)
	local recipe = DrinkRecipeService.GetRecipeFromName(recipeName)
	if recipe == nil then return end
	
	local requiredIngredients = recipe.ingredients
	
	local canMix = true
	for name, amount in pairs(requiredIngredients) do
		local amountOwned = 0
		for _, owned in ipairs(ingredients) do
			if owned.name == name then
				amountOwned = owned.value
				break
			end
		end
		if amountOwned < amount then
			canMix = false
			break
		end
	end
	
	if not canMix then
		return false
	end
	
	print("Do mixing")
	-- Do mixing
	-- Subtract ingredients required
	PlayerDataHandler.TakeIngredients(player, requiredIngredients)
	PlayerDataHandler.GiveDrink(player, recipeName)
	
	return true
end

return endpoint
