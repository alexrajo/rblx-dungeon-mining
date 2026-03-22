local plr = game.Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local dropCoinsEvent = APIService.GetEvent("DropCoins")
local dropItemsEvent = APIService.GetEvent("DropItems")
local refs = ReplicatedStorage:WaitForChild("refs")
local coinRef = refs:WaitForChild("Coin")
local itemRef = refs:WaitForChild("ItemDrop")

local character = script.Parent
local hrp = character:WaitForChild("HumanoidRootPart")

local movingDrops = {}

local DROP_MAX_AGE = 2

function addNewMovingDrop(drop: BasePart)
	drop.Anchored = true
	table.insert(movingDrops, drop)
	
	task.delay(DROP_MAX_AGE, function()
		drop:Destroy()
	end)
end

function updatePositions(deltaTime: number)
	for i, drop in pairs(movingDrops) do
		if drop.Parent == nil then
			table.remove(movingDrops, i)
			continue
		end
		-- Check if coin is close enough, and if so destroy it
		if (drop.Position - hrp.Position).Magnitude < 3 then
			drop:Destroy()
			table.remove(movingDrops, i)
			continue
		end
		
		-- Lerp position
		drop.CFrame = drop.CFrame:Lerp(hrp.CFrame, deltaTime * 10)
	end
end

function drop(amount: number, origin: Vector3, ref: Instance, imageId: string)
	for i = 1, amount do
		if i % 10000 == 0 then
			task.wait() -- Prevent freezing
		end
		local dropped = ref:Clone()
		dropped.Position = origin
		dropped.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), math.random(50, 80), math.random(-10, 10))
		
		if imageId ~= nil then
			local billboardGui = dropped:FindFirstChild("BillboardGui")
			if billboardGui then
				local itemImageLabel = billboardGui:FindFirstChild("Item")
				if itemImageLabel then
					itemImageLabel.Image = "rbxassetid://"..imageId
				end
			end
		end
		
		dropped.Parent = workspace

		task.delay(math.random(800, 1500)/1000, function()
			addNewMovingDrop(dropped)
		end)
	end
end

-- Spew coins from origin position
function dropCoins(amount: number, origin: Vector3)
	drop(amount, origin, coinRef)
end

function dropItems(amount: number, origin: Vector3, itemDefinition)
	local imageId = itemDefinition and itemDefinition.imageId or nil
	drop(amount, origin, itemRef, imageId)
end

dropCoinsEvent.OnClientEvent:Connect(dropCoins)
dropItemsEvent.OnClientEvent:Connect(dropItems)
RunService.RenderStepped:Connect(updatePositions)