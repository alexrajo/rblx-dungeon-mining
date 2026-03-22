local baseColor = Color3.fromRGB(214, 191, 151)

local colors = {
	["Windows"] = Color3.fromRGB(204, 221, 246),
	["Frames"] = Color3.fromRGB(94, 94, 94),
	["Frames2"] = Color3.fromRGB(133, 133, 133),
}

local CollectionService = game:GetService("CollectionService")
local instances = CollectionService:GetTagged("AutoColorBuilding")

for _, v in ipairs(instances) do
	for _, child: BasePart in ipairs(v:GetChildren()) do
		if not child:IsA("BasePart") then continue end
		
		local name = child.Name
		local colored = false
		for matchName, colorValue in pairs(colors) do
			if name == matchName then
				child.Color = colorValue
				colored = true
				break
			end
		end
		if not colored then
			child.Color = baseColor
		end
	end
end