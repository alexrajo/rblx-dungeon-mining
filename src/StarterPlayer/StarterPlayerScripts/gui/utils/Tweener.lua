local TweenService = game:GetService("TweenService")
local tweener = {}
tweener.__index = tweener

local function getInstanceTransparencyProperties(element: Instance)
	if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
		return {"TextTransparency"}
	elseif element:IsA("ImageLabel") or element:IsA("ImageButton") then
		return {"ImageTransparency"}
	elseif element:IsA("UIStroke") then
		return {"Transparency"}
	elseif element:IsA("Frame") or element:IsA("ScrollingFrame") then
		return {"BackgroundTransparency"}
	end
	return {}
end

function tweener.New(rootElement: GuiObject, initiallyVisible: boolean)
	local newTweener = {}
	newTweener.rootElement = rootElement
	newTweener.originalProperties = {}
	
	local function addOriginalProperties(element: Instance)
		local transparencyProperties = getInstanceTransparencyProperties(element)
		if #transparencyProperties == 0 then return end

		local originalProperties = {}
		for _, v in pairs(transparencyProperties) do
			originalProperties[v] = element[v]
			
			-- Set the initial visibility of the element
			if initiallyVisible == false or initiallyVisible == nil then
				element[v] = 1
			end
		end

		newTweener.originalProperties[element] = originalProperties
	end
	
	addOriginalProperties(rootElement)
	for _, child in pairs(rootElement:GetDescendants()) do
		addOriginalProperties(child)
	end
	setmetatable(newTweener, tweener)
	return newTweener
end

-- Fades a single GUI object based on its class
function tweener:_fadeSingleElement(element: Instance, tweenInfo: TweenInfo, visible: boolean)
	local transparencyProperties = getInstanceTransparencyProperties(element)
	local targetProperties = {}
	for _, v in pairs(transparencyProperties) do
		targetProperties[v] = visible and self.originalProperties[element][v] or 1
	end
	
	local tween = TweenService:Create(element, tweenInfo, targetProperties)
	tween:Play()
end

-- Fades the base UI element and all its relevant children
function tweener:_fade(duration: number, visible: boolean)
	local fadeTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	-- Fade the base element
	self:_fadeSingleElement(self.rootElement, fadeTweenInfo, visible)

	-- Fade all descendants
	for _, descendant in pairs(self.rootElement:GetDescendants()) do
		self:_fadeSingleElement(descendant, fadeTweenInfo, visible)
	end
end

function tweener:FadeIn(duration: number)
	self:_fade(duration, true)
end

function tweener:FadeOut(duration: number)
	self:_fade(duration, false)
end

return tweener
