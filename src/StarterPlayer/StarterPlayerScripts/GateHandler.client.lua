local plr = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local myPlayerData = PlayerData:WaitForChild(plr.Name)
local levelValue = myPlayerData:WaitForChild("Level")

function openGate(gate: BasePart)
	gate:Destroy()
end

function update(level)
	local areaGates = CollectionService:GetTagged("AreaGate")
	for _, gate in pairs(areaGates) do
		--if not gate:IsA("BasePart") then continue end
		
		local levelRequirement = gate:GetAttribute("LevelRequirement")
		if level >= levelRequirement then
			-- Gate should be open
			openGate(gate)
		--else
			-- Gate should be closed (is closed by default)
			--closeGate()
		end
	end
end

levelValue.Changed:Connect(update)
update(levelValue.Value)

CollectionService:GetInstanceAddedSignal("AreaGate"):Connect(function()
	task.wait(0.5) -- Allow server to set parent
	update(levelValue.Value)
end)