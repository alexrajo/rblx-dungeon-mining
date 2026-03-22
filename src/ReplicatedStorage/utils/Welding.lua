local module = {}

function module.WeldAllDescendantsInPlace(parent: Instance)
	local descendants = parent:GetDescendants()
	local parts = {}
	for _, child in ipairs(descendants) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	for i = 1, #parts do
		for j = i + 1, #parts do
			local part0 = parts[i]
			local part1 = parts[j]
			module.WeldTwoPartsInPlace(part0, part1)
		end
	end
end

function module.WeldTwoPartsInPlace(part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0
end

return module
