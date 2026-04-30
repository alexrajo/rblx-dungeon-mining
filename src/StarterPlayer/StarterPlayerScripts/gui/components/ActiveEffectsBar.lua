local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local StatsContext = require(ModuleIndex.StatsContext)

local ICON_SIZE = 28

local function getSortedEffects(activeEffects)
	local effectEntries = {}

	for _, effectEntry in ipairs(activeEffects or {}) do
		table.insert(effectEntries, effectEntry)
	end

	table.sort(effectEntries, function(a, b)
		local expiresA = type(a.ExpiresAt) == "number" and a.ExpiresAt or math.huge
		local expiresB = type(b.ExpiresAt) == "number" and b.ExpiresAt or math.huge

		if expiresA == expiresB then
			return (a.id or "") < (b.id or "")
		end

		return expiresA < expiresB
	end)

	return effectEntries
end

local ActiveEffectsBar = Roact.Component:extend("ActiveEffectsBar")

function ActiveEffectsBar:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local activeEffects = getSortedEffects(data.ActiveEffects)

			if #activeEffects == 0 then
				return nil
			end

			local children = {
				ListLayout = createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}),
			}

			for index, effectEntry in ipairs(activeEffects) do
				children["Effect_" .. (effectEntry.id or tostring(index))] = createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(31, 31, 31),
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
					Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
					LayoutOrder = index,
				}, {
					UICorner = createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
					UIStroke = createElement("UIStroke", {
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
					}),
					Icon = createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Image = "rbxassetid://" .. tostring(effectEntry.ImageId or ""),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.new(1, -8, 1, -8),
					}),
				})
			end

			return createElement("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = self.props.LayoutOrder,
				Size = UDim2.new(0, 200, 0, ICON_SIZE),
			}, children)
		end,
	})
end

return ActiveEffectsBar
