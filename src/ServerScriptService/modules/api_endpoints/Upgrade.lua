local endpoint = {}

function endpoint.Call(player: Player)
	print(player, "wants to upgrade!")
	return true
end

return endpoint
