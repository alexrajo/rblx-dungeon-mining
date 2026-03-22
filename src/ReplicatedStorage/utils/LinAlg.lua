local LinAlg = {}

function LinAlg.RotateVectorAround(vector, angle, axis)
	return CFrame.fromAxisAngle(axis, angle):VectorToWorldSpace(vector)
end

return LinAlg
