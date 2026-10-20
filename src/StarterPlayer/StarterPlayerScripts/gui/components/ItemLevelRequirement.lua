local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)

local createElement = Roact.createElement
local ItemLevelRequirement = Roact.PureComponent:extend("ItemLevelRequirement")

function ItemLevelRequirement:render()
	local itemName = self.props.itemName
	if ItemConfig.GetItemData(itemName) == nil then
		return nil
	end

	local requiredLevel = ItemConfig.GetRequiredLevel(itemName)
	local currentLevel = self.props.playerLevel or 1
	local locked = not ItemConfig.MeetsLevelRequirement(itemName, currentLevel)
	local badge = self.props.badge == true
	if badge and not locked then
		return nil
	end

	local text = badge and string.format("Lv. %d", requiredLevel)
		or string.format("Requires level %d — Your level: %d", requiredLevel, currentLevel)
	if not badge and locked and self.props.showAcquisitionHint then
		text ..= string.format("\nYou can obtain this now and use it at level %d.", requiredLevel)
	end

	return createElement("TextLabel", {
		Text = text,
		Font = Enum.Font.LuckiestGuy,
		TextSize = badge and 11 or 13,
		TextScaled = true,
		TextWrapped = true,
		TextColor3 = badge and Color3.new(1, 1, 1)
			or (locked and Color3.fromRGB(255, 125, 125) or Color3.fromRGB(130, 255, 155)),
		TextXAlignment = badge and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(166, 35, 49),
		BackgroundTransparency = badge and 0 or 1,
		BorderSizePixel = 0,
		Size = self.props.Size or (badge and UDim2.new(0.7, 0, 0, 16) or UDim2.new(1, 0, 0, 36)),
		Position = self.props.Position,
		AnchorPoint = self.props.AnchorPoint,
		LayoutOrder = self.props.LayoutOrder,
		ZIndex = self.props.ZIndex or 7,
	}, {
		Corner = badge and createElement("UICorner", { CornerRadius = UDim.new(0, 4) }) or nil,
		Stroke = createElement("UIStroke", { Color = Color3.fromRGB(35, 15, 20), Thickness = 1 }),
		TextSize = createElement("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = badge and 12 or 13 }),
	})
end

return ItemLevelRequirement
