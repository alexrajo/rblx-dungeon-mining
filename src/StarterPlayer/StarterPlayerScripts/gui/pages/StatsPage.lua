local plr = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local PageWrapper = require(ModuleIndex.PageWrapper)
local Window = require(ModuleIndex.Window)
local TextLabel = require(ModuleIndex.TextLabel)

local StatsContext = require(ModuleIndex.StatsContext)

local configs = ReplicatedStorage.configs
local GearConfig = require(configs.GearConfig)
local HotbarConfig = require(configs.HotbarConfig)

local utils = ReplicatedStorage.utils
local StatCalculation = require(utils.StatCalculation)

local StatsPage = Roact.Component:extend("StatsPage")

local function createStatRow(label: string, value: string, layoutOrder: number)
	return createElement("Frame", {
		Size = UDim2.new(1, -20, 0, 35),
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
	}, {
		Label = createElement(TextLabel, {
			Text = label,
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.fromScale(0, 0),
			textSize = 16,
		}),
		Value = createElement(TextLabel, {
			Text = value,
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.fromScale(0.5, 0),
			textSize = 18,
		}),
	})
end

function StatsPage:render()
	local closeAllPages = self.props.closeAllPages
	local currentPageBinding = self.props.currentPageBinding
	local currentPage = currentPageBinding:getValue()

	local function onExit()
		closeAllPages()
	end

	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local level = data.Level or 1

			local hotbarSlots = HotbarConfig.NormalizeStoredSlots(data.HotbarSlots or {})
			local selectedSlot = data.SelectedHotbarSlot or 0
			local selectedItemName = HotbarConfig.ResolveEntryItemName(hotbarSlots[selectedSlot], data)
			local selectedSlotName = GearConfig.GetSlotForItem(selectedItemName)
			local selectedPickaxe = selectedSlotName == "Pickaxe" and selectedItemName or ""
			local selectedWeapon = selectedSlotName == "Weapon" and selectedItemName or ""

			local helmetItemName = ""
			local chestplateItemName = ""
			local leggingsItemName = ""
			local bootsItemName = ""
			if data.EquippedHelmet ~= "" then
				helmetItemName = HotbarConfig.ResolveEntryItemName(data.EquippedHelmet, data)
			end
			if data.EquippedChestplate ~= "" then
				chestplateItemName = HotbarConfig.ResolveEntryItemName(data.EquippedChestplate, data)
			end
			if data.EquippedLeggings ~= "" then
				leggingsItemName = HotbarConfig.ResolveEntryItemName(data.EquippedLeggings, data)
			end
			if data.EquippedBoots ~= "" then
				bootsItemName = HotbarConfig.ResolveEntryItemName(data.EquippedBoots, data)
			end

			local miningPower = selectedPickaxe ~= "" and StatCalculation.GetMiningDamage(selectedPickaxe) or 0
			local combatDamage = StatCalculation.GetCombatDamage(selectedWeapon ~= "" and selectedWeapon or nil, level)
			local defense = StatCalculation.GetPlayerDefense(helmetItemName, chestplateItemName, leggingsItemName, bootsItemName)
			local moveSpeed = StatCalculation.GetPlayerMoveSpeed(bootsItemName ~= "" and bootsItemName or nil)
			local maxHP = StatCalculation.GetPlayerMaxHealth(level)
			local maxFloor = data.MaxFloorReached or 0

			return createElement(PageWrapper, {isOpen = (currentPage == "Stats")}, {
				Window = createElement(Window, {title = "Stats", Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), onExit = onExit}, {
					Content = createElement("Frame", {
						Size = UDim2.new(1, -20, 1, -20),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
					}, {
						UIListLayout = createElement("UIListLayout", {
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 5),
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
						}),
						Level = createStatRow("Level", tostring(level), 1),
						MaxHP = createStatRow("Max HP", tostring(maxHP), 2),
						MiningPower = createStatRow("Mining Power", tostring(miningPower), 3),
						CombatDamage = createStatRow("Combat Damage", tostring(combatDamage), 4),
						Defense = createStatRow("Defense", tostring(defense), 5),
						MoveSpeed = createStatRow("Move Speed", tostring(moveSpeed), 6),
						Pickaxe = createStatRow("Pickaxe", selectedPickaxe ~= "" and selectedPickaxe or "None wielded", 7),
						Weapon = createStatRow("Weapon", selectedWeapon ~= "" and selectedWeapon or "None wielded", 8),
						MaxFloor = createStatRow("Deepest Floor", tostring(maxFloor), 9),
					})
				})
			})
		end
	})
end

return StatsPage
