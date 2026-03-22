local ServerScriptService = game.ServerScriptService
local modules = ServerScriptService.modules
local PlayerDataHandler = require(modules.PlayerDataHandler)

local ReplicatedStorage = game.ReplicatedStorage
local drinks = ReplicatedStorage.drinks

local Players = game.Players

function playerAdded(plr: Player)
	local function updateDrink(drinkName: string)
		local char = plr.Character
		if char == nil then return end
		
		local backpack = plr.Backpack
		local drinkTool = backpack:FindFirstChild("Drink")
		if drinkTool == nil then
			drinkTool = char:FindFirstChildOfClass("Tool")
		end

		if drinkTool ~= nil then
			drinkTool:Destroy()
		end

		local drinkRef = drinks:FindFirstChild(drinkName)
		if drinkRef == nil then
			drinkRef = drinks.Soda
			warn("Could not find drink ref with name:", drinkName)
		end

		drinkTool = drinkRef:Clone()
		drinkTool.Name = "Drink"
		drinkTool.Parent = backpack

		local localScript = drinkTool:FindFirstChild("DrinkLocalControl")
		if localScript then
			localScript.Enabled = true
		end
	end
	
	local function characterAdded(char: Model)
		local equippedDrink = PlayerDataHandler.GetEquippedDrink(plr)
		updateDrink(equippedDrink)
	end
	
	PlayerDataHandler.ListenToStatUpdate("EquippedDrink", plr, function(value)
		if value == nil then
			return
		end
		updateDrink(value)
	end)
	
	plr.CharacterAdded:Connect(characterAdded)
	if plr.Character ~= nil then
		characterAdded(plr.Character)
	end
end

Players.PlayerAdded:Connect(playerAdded)

for _, plr in ipairs(Players:GetChildren()) do
	playerAdded(plr)
end