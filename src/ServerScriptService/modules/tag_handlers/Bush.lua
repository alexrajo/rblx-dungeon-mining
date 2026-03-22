local TagHandler = {}

function TagHandler.Apply(instance: Instance)
	local leaf: MeshPart = instance:FindFirstChild("Leaf")
	if not leaf then
		warn("Leaf not found in bush!")
		return
	end
	
	leaf.Material = Enum.Material.Fabric
	leaf.TextureID = "http://www.roblox.com/asset/?id=2482047623"
end

return TagHandler
