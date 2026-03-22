local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.modules
local RagdollUtils = require(modules.RagdollUtils)
local PlayerDataHandler = require(modules.PlayerDataHandler)
local ServerStorage = game:GetService("ServerStorage")

-- Cross script communication
local crossScriptCommunicationBindables = ServerStorage.CrossScriptCommunicationBindables
local signalTutorialEvent = crossScriptCommunicationBindables.SignalTutorial

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local RE_VisualizeBurp = APIService.GetEvent("VisualizeBurp")
local RE_CoinDrop = APIService.GetEvent("DropCoins")
local RE_ItemDrop = APIService.GetEvent("DropItems")

local utils = ReplicatedStorage.utils
local TableUtils = require(utils.TableUtils)
local LinAlg = require(utils.LinAlg)
local StatCalculation = require(utils.StatCalculation)
local StatRetrieval = require(utils.StatRetrieval)

local globalConfig = require(ReplicatedStorage.GlobalConfig)
local configs = ReplicatedStorage.configs
local dropsConfig = require(configs.DropsConfig)

local effects = ReplicatedStorage.effects
local burpEffects = effects.burp
local onHitParticles = burpEffects.OnHitParticles

local getPlayerStat = StatRetrieval.GetPlayerStat

local BURP_COOLDOWN = 3
local NETWORK_DELAY_LEEWAY = 0.2 -- How much leeway is added to hit detection to account for network delay

local BurpAction = {
	cooldowns = {} -- [player] = is on cooldown or not (boolean)
}

type DestructibleInstance = {
	instance: Instance,
	hitPosition: Vector3
}

type HitInformation = {
	humanoids: {Humanoid},
	characterParts: {BasePart},
	destructibleInstances: {DestructibleInstance}
}


--[[
	Performs a burp if the criteria are met
	
	@param player: Player - The player that wishes to burp
	
	@returns number - The burp cooldown
]]
function BurpAction.Activate(player: Player, hitInformationLocal: HitInformation)
	if BurpAction.cooldowns[player] then return 0.5 end
	
	local burpCharge = PlayerDataHandler.GetBurpCharge(player)
	if burpCharge <= 0 then return 0.5 end -- If burp is not charged up yet
	
	local character = player.Character
	if character == nil then return 0.5 end -- Return a wait time of 0.5 if no character is found, mainly to prevent spamming the function trigger
	
	local head: BasePart = character:FindFirstChild("Head")
	local humanoidRootPart: BasePart = character:FindFirstChild("HumanoidRootPart")
	if head == nil or humanoidRootPart == nil then return 0.5 end
	
	BurpAction.cooldowns[player] = true
	PlayerDataHandler.ResetBurpCharge(player)
	
	local hitHumanoidsLocal = hitInformationLocal.humanoids
	local characterHitPartsLocal = hitInformationLocal.characterParts
	
	local level = getPlayerStat("Level", player)

    signalTutorialEvent:Fire(player, "burp")
	
	RE_VisualizeBurp:FireAllClients(character, level, burpCharge)
	
	-- Handle hitting players and NPCs
	for index, hitHumanoid in pairs(hitHumanoidsLocal) do
		local hitHumanoidRootPart: BasePart = hitHumanoid.RootPart
		local registeredHitPart = characterHitPartsLocal[index]
		
		if humanoidRootPart ~= nil and registeredHitPart ~= nil then
			
			-- Perform a check to see if the hit character is within range of the burp
			if (registeredHitPart.Position - head.Position).Magnitude > StatCalculation.GetBurpDistance(level, burpCharge)*(1+NETWORK_DELAY_LEEWAY) then continue end
			
			local rootRigAttachment: Attachment = hitHumanoidRootPart:FindFirstChild("RootRigAttachment")
			if rootRigAttachment ~= nil then
				local flingDirection = (hitHumanoidRootPart.Position - head.Position).Unit
				local flingForce = StatCalculation.GetBurpForce(level, burpCharge)
				
				hitHumanoid.PlatformStand = true
					
				-- The not smart way of doing it but this is the only way that works
				local force = Instance.new("VectorForce")
				force.ApplyAtCenterOfMass = true
				force.Force = flingDirection*flingForce
				force.RelativeTo = Enum.ActuatorRelativeTo.World
				force.Enabled = true
				force.Attachment0 = rootRigAttachment
				force.Parent = hitHumanoidRootPart
				
				local angularVelocity = Instance.new("AngularVelocity")
				angularVelocity.Attachment0 = rootRigAttachment
				angularVelocity.AngularVelocity = Vector3.new(1, math.random(-1, 1), math.random(-1, 1))*flingForce/20
				angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
				angularVelocity.MaxTorque = 35000
				angularVelocity.Enabled = true
				angularVelocity.Parent = hitHumanoidRootPart 
				
				for _, v in pairs(hitHumanoid.Parent:GetChildren()) do
					if v:IsA("BasePart") then
						local hitParticles = onHitParticles:Clone()
						hitParticles.Enabled = true
						hitParticles.Parent = v
						Debris:AddItem(hitParticles, 4+hitParticles.Lifetime.Max)
						delay(4, function()
							hitParticles.Enabled = false
						end)
					end
				end
				
				--RagdollUtils.ActivateRagdoll(hitCharacter)
				
				delay(0.2, function()
					force:Destroy()
					angularVelocity:Destroy()
				end)
				delay(1, function()
					hitHumanoid.PlatformStand = false
					hitHumanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
					--RagdollUtils.DeactivateRagdoll(hitCharacter)
				end)
			end
		end
		
		if hitHumanoid == nil then continue end
		hitHumanoid:TakeDamage(StatCalculation.GetBurpDamage(level, burpCharge) or 0)
	end
	
	-- Handle hitting destructible instances
	local destructibleInstances = hitInformationLocal.destructibleInstances
	local totalDestructionReward = 0
	local totalXPReward = 0
	local totalItemRewards = {}
	
	local burpPower = StatCalculation.GetBurpPower(level, burpCharge)

    if #destructibleInstances > 0 then
        signalTutorialEvent:Fire(player, "burpOnItem")
    end
	
	for _, v in pairs(destructibleInstances) do
		
		local instance = v.instance
		local hitPosition = v.hitPosition
		
		-- Get position of closest part
		local closestPart: BasePart = nil
		local closestDiff: Vector3 = nil
		
		-- Raycast from head of player to the hitPosition and beyond, to see if the instance is hit
		-- If raycast hits instance, destroy it
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = {instance}
		
		local rayDirection = (hitPosition - head.Position).Unit*(StatCalculation.GetBurpDistance(level, burpCharge)+2)
		local raycastResult = workspace:Raycast(head.Position, rayDirection, raycastParams)
		
		if raycastResult == nil then continue end
		if raycastResult.Instance ~= instance and not raycastResult.Instance:IsDescendantOf(instance) then continue end
		
		local powerRequirement = instance:GetAttribute("PowerRequirement")
		if powerRequirement == nil then
			powerRequirement = 0
		end
		if burpPower < powerRequirement then continue end -- Do not destroy instance if player has too low power
		
		local reward = instance:GetAttribute("Reward")
		if reward == nil then
			reward = 0
		end
		totalDestructionReward += reward
		instance:SetAttribute("Reward", 0)
		
		local xpReward = instance:GetAttribute("XPReward")
		if xpReward == nil then
			xpReward = globalConfig.DEFAULT_XP_REWARD
		end
		totalXPReward += xpReward
		instance:SetAttribute("XPReward", 0)
		
		-- Tell player to visualize coin drop
		if RE_CoinDrop then
			RE_CoinDrop:FireClient(player, reward, hitPosition)
		else
			warn("Burp - BurpAction.Activate: RE_CoinDrop not found")
		end
		
		local itemReward = {}
		local dropType: string = instance:GetAttribute("DropType")
		local drops = dropsConfig.types[dropType]
		if drops ~= nil then
			for dropName, dropChance in pairs(drops) do
				if math.random() < dropChance then
					local amount = 1
					table.insert(itemReward, {name = dropName, amount = amount})
					
					if totalItemRewards[dropName] ~= nil then
						totalItemRewards[dropName] += amount
					else
						totalItemRewards[dropName] = amount
					end
				end
			end
		end
		
		if RE_ItemDrop then
			for _, reward in pairs(itemReward) do
				local itemName = reward.name
				local amount = reward.amount
				if itemName == nil or amount == nil then continue end
				
				local itemDefinition = dropsConfig.itemDefinitions[itemName]
				if itemDefinition == nil then
					warn("No definition for item drop:", itemName)
					continue
				end
				
				RE_ItemDrop:FireClient(player, amount, hitPosition, itemDefinition)
			end
		else
			warn("Burp - BurpAction.Activate: RE_ItemDrop not found")
		end
		
		local bindableEvent = instance:FindFirstChild("BlowAway")  
		if bindableEvent == nil then continue end
		
		local unitDiff = (hitPosition - head.Position).Unit
		local dist = (hitPosition - head.Position).Magnitude
		local forceScale = StatCalculation.GetBurpForce(level, burpCharge) / dist
		local force = unitDiff * forceScale
		force = Vector3.new(force.X, 50, force.Z)
		bindableEvent:Fire(force)
	end

    -- Check if any items (ingredients) were dropped, and if so, signal to the tutorial manager
    for _, v in pairs(totalItemRewards) do
        if v > 0 then
            signalTutorialEvent:Fire(player, "getIngredient")
            break
        end
    end
	
	PlayerDataHandler.GiveCoins(player, totalDestructionReward)
	PlayerDataHandler.GiveXP(player, totalXPReward)
	PlayerDataHandler.GiveIngredients(player, totalItemRewards)
	
	--
	
	delay(BURP_COOLDOWN, function()
		BurpAction.cooldowns[player] = false
	end)
	
	return BURP_COOLDOWN
end

return BurpAction
