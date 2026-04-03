local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local TextLabel = Roact.Component:extend("TextLabel")

local function stripColorTags(richText: string): string
	-- Match both <font color="#RRGGBB"> and <font color="rgb(r,g,b)">
	local cleaned = richText:gsub('<font color="[^"]+">(.-)</font>', '%1')
	return cleaned
end

--[[
	@param Size
	@param Text
	@param textSize
	@param AnchorPoint
	@param Position
	@param ZIndex
	@param BackgroundTransparency
	@param textProps
	@param SizeConstraint
	@param RichText
]]
function TextLabel:render()
	local textSize = self.props.textSize
	local text = tostring(self.props.Text)
	-- This component layers two TextLabels for the white text + black shadow effect.
	-- They need to share the same RichText mode when exact wrapping parity matters.
	local useRichText = self.props.RichText ~= false
	
	local labelProps = {
		AnchorPoint = Vector2.new(0.5, 0.45),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Font = Enum.Font.LuckiestGuy,
		Text = text,
		TextSize = textSize,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		RichText = useRichText,
	}
	local labelStrokeProps = {
		AnchorPoint = Vector2.new(0.5, 0.45),
		Position = UDim2.new(0.5, 0, 0.5, 3),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 1,
		Font = Enum.Font.LuckiestGuy,
		-- Strip color tags only when RichText is enabled so the shadow keeps matching plain-text callers exactly.
		Text = useRichText and stripColorTags(text) or text,
		TextSize = textSize,
		TextColor3 = Color3.fromRGB(0, 0, 0),
		RichText = useRichText,
		--table.unpack(self.props.textProps or {})
	}
	
	if self.props.textProps ~= nil then
		local success, err = pcall(function()
			for k, v in pairs(self.props.textProps) do
				labelProps[k] = v
				labelStrokeProps[k] = v
			end
		end)
		if not success then
			warn("TextLabel - render: Error while applying textProps: ", err)
		end
	end

	return createElement("Frame", {
		BackgroundTransparency = self.props.BackgroundTransparency ~= nil and self.props.BackgroundTransparency or 1,
		Position = self.props.Position ~= nil and self.props.Position or UDim2.fromScale(0, 0),
		AnchorPoint = self.props.AnchorPoint ~= nil and self.props.AnchorPoint or Vector2.zero,
		Size = self.props.Size,
		ZIndex = self.props.ZIndex ~= nil and self.props.ZIndex or 0,
		SizeConstraint = self.props.SizeConstraint
	}, {
		TextLabel = createElement("TextLabel", labelProps, {
			UIStroke = createElement("UIStroke", {}),
			UITextSizeConstraint = createElement("UITextSizeConstraint", {
				MaxTextSize = 100,
				MinTextSize = 9,
			})
		}),
		["TextLabel - Stroke"] = createElement("TextLabel", labelStrokeProps, {
			UITextSizeConstraint = createElement("UITextSizeConstraint", {
				MaxTextSize = 100,
				MinTextSize = 9,
			})
		})
	})
end

return TextLabel
