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
			local selectedItemName = hotbarSlots[selectedSlot] or ""
			local selectedSlotName = GearConfig.GetSlotForItem(selectedItemName)
			local selectedPickaxe = selectedSlotName == "Pickaxe" and selectedItemName or ""
			local selectedWeapon = selectedSlotName == "Weapon" and selectedItemName or ""
			local pickaxeTier = GearConfig.GetTierForItem(selectedPickaxe)

			local helmetTier = 0
			local chestplateTier = 0
			local leggingsTier = 0
			local bootsTier = 0
			if data.EquippedHelmet ~= "" then
				helmetTier = GearConfig.GetTierForItem(data.EquippedHelmet) or 0
			end
			if data.EquippedChestplate ~= "" then
				chestplateTier = GearConfig.GetTierForItem(data.EquippedChestplate) or 0
			end
			if data.EquippedLeggings ~= "" then
				leggingsTier = GearConfig.GetTierForItem(data.EquippedLeggings) or 0
			end
			if data.EquippedBoots ~= "" then
				bootsTier = GearConfig.GetTierForItem(data.EquippedBoots) or 0
			end

			local miningPower = pickaxeTier ~= nil and StatCalculation.GetMiningDamage(pickaxeTier) or 0
			local combatDamage = StatCalculation.GetCombatDamage(selectedWeapon ~= "" and selectedWeapon or nil, level)
			local defense = StatCalculation.GetPlayerDefense(helmetTier, chestplateTier, leggingsTier, bootsTier)
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
						Pickaxe = createStatRow("Pickaxe", selectedPickaxe ~= "" and selectedPickaxe or "None wielded", 6),
						Weapon = createStatRow("Weapon", selectedWeapon ~= "" and selectedWeapon or "None wielded", 7),
						MaxFloor = createStatRow("Deepest Floor", tostring(maxFloor), 8),
					})
				})
			})
		end
	})
end

return StatsPage
