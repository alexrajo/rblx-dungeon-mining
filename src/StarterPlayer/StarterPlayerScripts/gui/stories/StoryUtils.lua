local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local StoryUtils = {}

function StoryUtils.noop() end

function StoryUtils.mount(target: Frame, element)
	local root = Roact.mount(element, target)

	return function()
		Roact.unmount(root)
	end
end

function StoryUtils.makeCanvas(children, props)
	props = props or {}

	local canvasChildren = {
		Padding = createElement("UIPadding", {
			PaddingTop = UDim.new(0, props.padding or 24),
			PaddingRight = UDim.new(0, props.padding or 24),
			PaddingBottom = UDim.new(0, props.padding or 24),
			PaddingLeft = UDim.new(0, props.padding or 24),
		}),
		Layout = createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, props.spacing or 24),
		}),
	}

	for key, child in pairs(children) do
		canvasChildren[key] = child
	end

	return createElement("Frame", {
		BackgroundColor3 = props.backgroundColor or Color3.fromRGB(8, 20, 36),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, canvasChildren)
end

function StoryUtils.makeRow(children, props)
	props = props or {}

	local rowChildren = {
		Layout = createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = props.horizontalAlignment or Enum.HorizontalAlignment.Left,
			VerticalAlignment = props.verticalAlignment or Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, props.spacing or 14),
		}),
	}

	for key, child in pairs(children) do
		rowChildren[key] = child
	end

	return createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
		Size = props.size or UDim2.new(1, 0, 0, 90),
	}, rowChildren)
end

function StoryUtils.makeLabel(text: string, layoutOrder: number?)
	return createElement("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, 0, 0, 22),
		Text = text,
		TextColor3 = Color3.fromRGB(220, 235, 255),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

function StoryUtils.makeCell(child, props)
	props = props or {}

	return createElement("Frame", {
		BackgroundColor3 = props.backgroundColor or Color3.fromRGB(13, 35, 59),
		BackgroundTransparency = props.backgroundTransparency or 0,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = props.size or UDim2.fromOffset(150, 90),
	}, {
		Corner = createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Content = child,
	})
end

return StoryUtils
