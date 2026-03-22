local TagHandler = {}

function TagHandler.Apply(instance: Instance)
	local leaf: MeshPart = instance:FindFirstChild("Tree1.001")
	if not leaf then
		warn("Leaf not found in tree!")
		return
	end
	
	leaf.Material = Enum.Material.Fabric
	leaf.TextureID = "http://www.roblox.com/asset/?id=2482047623"
end

return TagHandler
