local RAGDOLL_CONSTRAINTS_FOLDER_NAME = "RagdollConstraints"

local RagdollUtils = {}

local function ConnectLimbs(char)
	if char:FindFirstChild(RAGDOLL_CONSTRAINTS_FOLDER_NAME) then return end
	
	local constraintsFolder = Instance.new("Folder")
	constraintsFolder.Name = RAGDOLL_CONSTRAINTS_FOLDER_NAME
	constraintsFolder.Parent = char
	
	for i, limb in pairs(char:GetChildren()) do
		if limb:IsA("BasePart") then
			local atch0, atch1, atch2, atch3, atch4, atch5

			if limb.Name == "Head" then
				atch0 = char.Head.NeckRigAttachment
				atch1 = char.UpperTorso.NeckRigAttachment
			elseif limb.Name == "UpperTorso" then
				atch0 = char.UpperTorso.WaistRigAttachment
				atch1 = char.LowerTorso.WaistRigAttachment

				atch2 = char.UpperTorso.LeftShoulderRigAttachment
				atch3 = char.LeftUpperArm.LeftShoulderRigAttachment

				atch4 = char.UpperTorso.RightShoulderRigAttachment
				atch5 = char.RightUpperArm.RightShoulderRigAttachment
			elseif limb.Name == "LowerTorso" then
				atch0 = char.LowerTorso.LeftHipRigAttachment
				atch1 = char.LeftUpperLeg.LeftHipRigAttachment

				atch2 = char.LowerTorso.RightHipRigAttachment
				atch3 = char.RightUpperLeg.RightHipRigAttachment
			elseif limb.Name == "LeftUpperLeg" then
				atch0 = char.LeftUpperLeg.LeftKneeRigAttachment
				atch1 = char.LeftLowerLeg.LeftKneeRigAttachment
			elseif limb.Name == "RightUpperLeg" then
				atch0 = char.RightUpperLeg.RightKneeRigAttachment
				atch1 = char.RightLowerLeg.RightKneeRigAttachment
			elseif limb.Name == "LeftLowerLeg" then
				atch0 = char.LeftLowerLeg.LeftAnkleRigAttachment
				atch1 = char.LeftFoot.LeftAnkleRigAttachment
			elseif limb.Name == "RightLowerLeg" then
				atch0 = char.RightLowerLeg.RightAnkleRigAttachment
				atch1 = char.RightFoot.RightAnkleRigAttachment
			elseif limb.Name == "LeftUpperArm" then
				atch0 = char.LeftUpperArm.LeftElbowRigAttachment
				atch1 = char.LeftLowerArm.LeftElbowRigAttachment
			elseif limb.Name == "RightUpperArm" then
				atch0 = char.RightUpperArm.RightElbowRigAttachment
				atch1 = char.RightLowerArm.RightElbowRigAttachment
			elseif limb.Name == "LeftLowerArm" then
				atch0 = char.LeftLowerArm.LeftWristRigAttachment
				atch1 = char.LeftHand.LeftWristRigAttachment
			elseif limb.Name == "RightLowerArm" then
				atch0 = char.RightLowerArm.RightWristRigAttachment
				atch1 = char.RightHand.RightWristRigAttachment
			end

			if atch0 and atch1 then
				local ballInSocket = Instance.new("BallSocketConstraint", limb)
				ballInSocket.Attachment0 = atch0
				ballInSocket.Attachment1 = atch1
			end

			if atch2 and atch3 then
				local ballInSocket = Instance.new("BallSocketConstraint", limb)
				ballInSocket.Attachment0 = atch2
				ballInSocket.Attachment1 = atch3
			end

			if atch4 and atch5 then
				local ballInSocket = Instance.new("BallSocketConstraint", limb)
				ballInSocket.Attachment0 = atch4
				ballInSocket.Attachment1 = atch5
			end

		elseif limb:IsA("Accessory") then
			local h = limb:FindFirstChild("Handle")
			if h then
				local part0 = char.Head
				local atch = h:FindFirstChildOfClass("Attachment")

				if atch.Name == "HatAttachment" or atch.Name == "FaceFrontAttachment" then
					part0 = char.Head
				end

				local ap = Instance.new("AlignPosition", part0)
				if part0 == char.Head then
					ap.Attachment1 = char.Head:FindFirstChild(atch.Name)
					ap.Attachment0 = atch
					ap.RigidityEnabled = true
					ap.Responsiveness = 200
				end

				local ao = Instance.new("AlignOrientation", part0)
				if part0 == char.Head then
					ao.Attachment1 = char.Head:FindFirstChild(atch.Name)
					ao.Attachment0 = atch
					ao.RigidityEnabled = true
					ao.Responsiveness = 200
				end
			end
		end
	end
	
	local humanoid: Humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
		-- Disable all constraints of a live character
		for _, c in pairs(char:GetDescendants()) do
			if c:IsA("Motor6D") then
				c:Destroy()
			end
		end
	end
end

function RagdollUtils.ActivateRagdoll(char: Model)
	ConnectLimbs(char)
end

-- TODO: fix this, it flings the character far away
function RagdollUtils.DeactivateRagdoll(char: Model)
	local constraintsFolder = char:FindFirstChild(RAGDOLL_CONSTRAINTS_FOLDER_NAME)
	if constraintsFolder ~= nil then
		constraintsFolder:Destroy()
	end
	
	-- Remove collision for all parts, then add it back
	--[[
	for _, part in pairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	]]
	local humanoid: Humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid:BuildRigFromAttachments()
	end
end

return RagdollUtils
