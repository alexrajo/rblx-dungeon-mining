local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TagHandler = {}

local surfaceGuiRef = script:WaitForChild("SurfaceGui")

function deny(gate: BasePart, character: Model, player: Player)
	-- Teleport player to the front of the gate
	character:PivotTo(gate.CFrame*CFrame.new(0, 0, -10))
end

function checkPass(gate: BasePart, character: Model)
	local levelRequirement = gate:GetAttribute("LevelRequirement")
	if levelRequirement == nil then return end
	
	local player = game.Players:GetPlayerFromCharacter(character)
	if player == nil then return end
	
	local PlayerData = ReplicatedStorage:FindFirstChild("PlayerData")
	if not PlayerData then return end
	
	local playerSpecificData = PlayerData:FindFirstChild(player.Name)
	if not playerSpecificData then
		deny(gate, character, player)
		return
	end
	
	local levelValue = playerSpecificData:FindFirstChild("Level")
	if not levelValue then
		deny(gate, character, player)
		return
	end
	
	local level = levelValue.Value
	if level < levelRequirement then
		deny(gate, character, player)
		return
	end
	
	-- Passed, do nothing
end

function onTouched(gate: BasePart, hitPart: BasePart)
	local frontDist = (hitPart.Position - (gate.Position + gate.CFrame.LookVector)).Magnitude
	local backDist = (hitPart.Position - (gate.Position - gate.CFrame.LookVector)).Magnitude
	if backDist > frontDist then return end
	
	-- Part has passed a little through the gate and is touched the other side
	local character = hitPart.Parent
	local plr = game.Players:GetPlayerFromCharacter(character)
	if not plr then
		character = hitPart.Parent.Parent
		plr = game.Players:GetPlayerFromCharacter(character)
		if not plr then return end
	end
	
	-- A player has passed mostly through the gate
	checkPass(gate, character)
end

function TagHandler.Apply(instance: BasePart)
	local sgui = surfaceGuiRef:Clone()
	sgui.Adornee = instance
	sgui.Enabled = true
	
	local container = sgui.Container
	local heading = container.Heading
	local requirementFrame = container.Requirement
	
	local areaNumber = instance:GetAttribute("AreaNumber")
	if areaNumber == nil then
		error("No AreaNumber set in", instance)
		return
	end
	
	local areaNumText = "AREA " .. areaNumber
	heading.TextLabel.Text = areaNumText
	heading.TextLabel_Stroke.Text = areaNumText
	
	local levelRequirement = instance:GetAttribute("LevelRequirement")
	if levelRequirement ~= nil then
		local text = "NEED LEVEL " .. levelRequirement
		requirementFrame.TextLabel.Text = text
		requirementFrame.TextLabel_Stroke.Text = text
	end
	
	sgui.Parent = instance
	
	instance.Touched:Connect(function(hit)
		onTouched(instance, hit)
	end)
end

return TagHandler
