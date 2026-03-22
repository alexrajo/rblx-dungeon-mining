local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configs = ReplicatedStorage.configs
local RunningNPCsConfig = require(Configs.RunningNPCs)

local Debris = game:GetService("Debris")
local weldingUtils = require(game.ReplicatedStorage.utils.Welding)

local RESPAWN_TIME = 10
local DEFAULT_REWARD = 5

local eatingAnimation = Instance.new("Animation")
eatingAnimation.AnimationId = "rbxassetid://98072708189618"

local clones = {}

local TagHandler = {}

function persistParent(parent: Model)
	if parent:IsA("Model") then
		if parent:FindFirstChild("PersistModel") then return end

		local p = Instance.new("Part")
		p.Name = "PersistModel"
		p.Anchored = true
		p.Transparency = 1
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Parent = parent
	end
end

function blowAway(instance: Instance, force: Vector3, player: Player)
	local originalParent = instance.Parent
	persistParent(originalParent)
	
	if instance:IsA("Model") then
		for i, v in pairs(instance:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Anchored = false
				v.CanCollide = false
				v.CanTouch = false
			elseif v:IsA("Seat") then
				v.Disabled = true
			end
		end
		
		for i, v in pairs(instance:GetDescendants()) do
			if v:IsA("BasePart") then
				v:ApplyImpulse(force*v.Mass)
				v:ApplyAngularImpulse(force.Unit*10*v.Mass)
			end
		end
	elseif instance:IsA("BasePart") then
		instance.Anchored = false
		instance.CanCollide = false
		instance.CanTouch = false
		instance:ApplyImpulse(force*instance.Mass)
		instance:ApplyAngularImpulse(force.Unit*10*instance.Mass)
	end
	
	local clone = clones[instance]
	Debris:AddItem(instance, 5)
	clones[instance] = nil
	
	-- Spawn running NPCs if PopulationSize is present and greater than 0
	local populationSize = instance:GetAttribute("PopulationSize")
	if populationSize and populationSize > 0 then
		local instanceCentroid = instance:GetPivot().Position
		
		-- Randomly spawn running NPCs around the instance's pivot point
		local npcs = game.ServerStorage:FindFirstChild("NPCs")
		if npcs then
			local runningNpcs = npcs:FindFirstChild("Running")
			if runningNpcs then
				local runningNPCTypeName = instance:GetAttribute("RunningNPCType") or "Default"
				local candidateNames = RunningNPCsConfig[runningNPCTypeName]
				for i = 1, populationSize do
					local refName = candidateNames[math.random(1, #candidateNames)]
					local ref = runningNpcs:FindFirstChild(refName)
					if ref == nil then
						warn("Could not find NPC ref with name:", refName)
						continue
					end
					local npc: Model = ref:Clone()
					
					-- Set up NoCollisionConstraint between every part in npc and every part in clone
					for _, part in pairs(npc:GetDescendants()) do
						if part:IsA("BasePart") then
							if clone:IsA("BasePart") then
								local noCollision = Instance.new("NoCollisionConstraint")
								noCollision.Part0 = clone
								noCollision.Part1 = part
								noCollision.Parent = clone
							else
								for _, cPart in pairs(clone:GetDescendants()) do
									if not cPart:IsA("BasePart") then continue end
									
									local noCollision = Instance.new("NoCollisionConstraint")
									noCollision.Part0 = cPart
									noCollision.Part1 = part
									noCollision.Parent = cPart
								end
							end
						end
					end
					
					npc:PivotTo(CFrame.new(instanceCentroid))
					npc.Parent = game.Workspace
				end
			end
		end
	end
	
	-- Move clone back to replace the original instance after a certain wait time
	delay(RESPAWN_TIME, function()
		clone.Parent = originalParent
	end)
end

function TagHandler.Apply(instance: Instance)
	clones[instance] = instance:Clone()
	
	weldingUtils.WeldAllDescendantsInPlace(instance)
	
	local reward = instance:GetAttribute("Reward")
	if reward == nil then
		instance:SetAttribute("Reward", DEFAULT_REWARD)
	end
	
	if instance:IsA("Model") then
		for _, v in ipairs(instance:GetDescendants()) do
			if v:IsA("Seat") then
				if math.random() < 0.5 then continue end
				
				-- Spawn a sitting NPC to sit on the seat
				local npcs = game.ServerStorage:FindFirstChild("NPCs")
				if npcs then
					local sittingNpcs = npcs:FindFirstChild("Sitting")
					if sittingNpcs then
						local candidates = sittingNpcs:GetChildren()
						if #candidates > 0 then
							local refNPC = candidates[math.random(1, #candidates)]
							local npc = refNPC:Clone()
							npc.Parent = instance -- Parent it early to start initialization

							local humanoid: Humanoid = npc:FindFirstChildOfClass("Humanoid")
							if humanoid then
								npc:PivotTo(v.CFrame * CFrame.new(0, 2, 0))

								-- Wait until Humanoid is initialized and alive
								task.spawn(function()
									-- Wait until NPC is alive and present in the workspace
									while not humanoid:IsDescendantOf(game) or humanoid.Health <= 0 do
										task.wait()
									end

									if v:IsDescendantOf(game) then
										v:Sit(humanoid)
									end

									local animator = humanoid:FindFirstChildOfClass("Animator")
									if animator then
										local success, track = pcall(function()
											return animator:LoadAnimation(eatingAnimation)
										end)
										if success and track then
											task.spawn(function()
												if game.Workspace.DistributedGameTime < 10 then
													task.wait(3) -- Prevent the animation from not looping in the start of the game
												end
												track.Looped = true
												track:Play(0, 1, 0.5)
											end)
										end

										-- Stop animation and clean up when NPC stops sitting
										humanoid:GetPropertyChangedSignal("Sit"):Once(function()
											if not humanoid.Sit then
												if track then
													track:Stop()
												end
												humanoid.Health = 0
											end
										end)
									end
								end)
							end
						end
					end
				end
			end

		end
	end
	
	local blowAwayConnection
	local blowAwayBindableEvent = Instance.new("BindableEvent")
	blowAwayBindableEvent.Name = "BlowAway"
	blowAwayConnection = blowAwayBindableEvent.Event:Connect(function(...)
		blowAway(instance, ...)
		
		if blowAwayConnection ~= nil then
			blowAwayConnection:Disconnect()
			blowAwayConnection = nil
		end
	end)
	
	blowAwayBindableEvent.Parent = instance
end

return TagHandler
