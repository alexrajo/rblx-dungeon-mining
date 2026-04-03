local CollectionService = game:GetService("CollectionService")

local function getInstancePosition(instance: Instance): Vector3?
	if instance:IsA("Model") then
		local model = instance :: Model
		local primaryPart = model.PrimaryPart
		if primaryPart ~= nil then
			return primaryPart.Position
		end

		return model:GetPivot().Position
	end

	if instance:IsA("BasePart") then
		return (instance :: BasePart).Position
	end

	return nil
end

local function getPlayerPosition(player: Player): Vector3?
	local character = player.Character
	if character == nil then
		return nil
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart == nil or not humanoidRootPart:IsA("BasePart") then
		return nil
	end

	return humanoidRootPart.Position
end

local function getClosestTaggedPosition(player: Player, tagName: string): Vector3?
	local playerPosition = getPlayerPosition(player)
	if playerPosition == nil then
		return nil
	end

	local closestPosition = nil
	local closestDistance = math.huge

	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
		if instance.Parent == nil or not instance:IsDescendantOf(workspace) then
			continue
		end

		local instancePosition = getInstancePosition(instance)
		if instancePosition == nil then
			continue
		end

		local distance = (instancePosition - playerPosition).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestPosition = instancePosition
		end
	end

	return closestPosition
end

local function getClosestDescendLadderPosition(player: Player): Vector3?
	local playerPosition = getPlayerPosition(player)
	if playerPosition == nil then
		return nil
	end

	local closestPosition = nil
	local closestDistance = math.huge

	for _, instance in ipairs(CollectionService:GetTagged("MineLadder")) do
		if instance.Parent == nil or not instance:IsDescendantOf(workspace) then
			continue
		end

		if instance:GetAttribute("LadderAction") ~= "descend" then
			continue
		end

		local instancePosition = getInstancePosition(instance)
		if instancePosition == nil then
			continue
		end

		local distance = (instancePosition - playerPosition).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestPosition = instancePosition
		end
	end

	return closestPosition
end

local function getClosestMineEntrancePosition(player: Player): Vector3?
	return getClosestTaggedPosition(player, "MineEntrance")
end

local function getClosestOreNodePosition(player: Player): Vector3?
	return getClosestTaggedPosition(player, "OreNode")
end

local function getClosestLadderOrOrePosition(player: Player): Vector3?
	local ladderPosition = getClosestDescendLadderPosition(player)
	if ladderPosition ~= nil then
		return ladderPosition
	end

	return getClosestOreNodePosition(player)
end

local IntroTutorial = {
	rewards = {
		Coins = 25,
	},
	steps = {
		{
			id = "Welcome",
			description = "Welcome to Dungeon Mining! This tutorial will teach you the basics to get you started.",
			completeOn = "click"
		},
		{
			id = "OpenInventory",
			description = "Open your inventory to see the items and gear you collect.",
			completeOn = "openPage_Inventory",
			outlineTags = {"TutorialInventoryButton"},
		},
		{
			id = "MineEntrance",
			description = "Head to the cave entrance and enter the mine to begin your adventure!",
			completeOn = "enterMine",
			pointToPositionFunction = getClosestMineEntrancePosition,
			pointToTags = {"MineEntrance"},
		},
		{
			id = "MineOre",
			description = "Click on an ore node to mine it with your pickaxe. Press 'Mine' or the key shown on screen.",
			completeOn = "mine",
			pointToPositionFunction = getClosestOreNodePosition,
			pointToTags = {"OreNode"},
		},
		{
			id = "CollectOre",
			description = "Great job! Break an ore node to collect its drop and add it to your inventory.",
			completeOn = "getItem",
			pointToPositionFunction = getClosestOreNodePosition,
			pointToTags = {"OreNode"},
		},
		{
			id = "FindLadder",
			description = "Mine ore until you reveal a ladder, then use its prompt to descend deeper into the mine!",
			completeOn = "descend",
			pointToPositionFunction = getClosestLadderOrOrePosition,
			pointToTags = {"MineLadder", "OreNode"},
		},
		{
			id = "IntroEnd",
			description = "You're all set! Mine ores, fight monsters, and craft better gear to go deeper. Good luck, miner!",
			completeOn = "click"
		},
	}
}

return IntroTutorial
