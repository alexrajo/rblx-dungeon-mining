local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local Services = ReplicatedStorage.services
local CraftingRecipeService = require(Services.CraftingRecipeService)

local endpoint = {}

function endpoint.Call(player: Player, recipeName: string)
	if type(recipeName) ~= "string" then return false end

	local recipe = CraftingRecipeService.GetRecipeByName(recipeName)
	if recipe == nil then return false end

	-- Check if player has all required ingredients
	if not PlayerDataHandler.HasItems(player, recipe.ingredients) then
		return false
	end

	-- Consume ingredients
	PlayerDataHandler.TakeItems(player, recipe.ingredients)

	-- Give the crafted item
	PlayerDataHandler.GiveItems(player, { [recipe.name] = 1 })

	return true
end

return endpoint
