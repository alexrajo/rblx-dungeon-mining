local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

function onDescendantAdded(descendant)
	if descendant:IsA("BasePart") then
		descendant.CollisionGroup = "Players"
	end
end

Players.PlayerAdded:Connect(function(plr: Player)
	plr.CharacterAdded:Connect(function(char: Model)
		for _, descendant in char:GetDescendants() do
			onDescendantAdded(descendant)
		end
		local descendantConnection = char.DescendantAdded:Connect(onDescendantAdded)
		local ancestryConnection
		
		ancestryConnection = char.AncestryChanged:Connect(function()
			if char.Parent == nil then
				if descendantConnection ~= nil then
					descendantConnection:Disconnect()
					descendantConnection = nil
				end
				if ancestryConnection ~= nil then
					ancestryConnection:Disconnect()
					ancestryConnection = nil
				end
			end
		end)
	end)
end)