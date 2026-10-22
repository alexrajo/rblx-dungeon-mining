local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local Display = {}
local handle = nil
local createElement = Roact.createElement

function Display.Clear(): ()
	if handle then Roact.unmount(handle) handle = nil end
end

function Display.Show(node: Instance, hp: number, maxHP: number): ()
	local root = if node:IsA("Model") then node.PrimaryPart else node
	if not root or not root:IsA("BasePart") then Display.Clear() return end
	local view = createElement("BillboardGui", {
		Adornee = root, AlwaysOnTop = true, MaxDistance = 40,
		Size = UDim2.fromOffset(112, 34), StudsOffset = Vector3.new(0, 3, 0),
	}, {
		Name = createElement("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.5),
			Text = (node:GetAttribute("OreType") or "Ore") .. "  " .. hp .. "/" .. maxHP,
			TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.2,
			Font = Enum.Font.GothamBold, TextSize = 13,
		}),
		Bar = createElement("Frame", {
			Position = UDim2.fromScale(0, 0.6), Size = UDim2.fromScale(1, 0.3),
			BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(40, 35, 30),
		}, {
			Corner = createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),
			Fill = createElement("Frame", {
				Size = UDim2.fromScale(math.clamp(hp / math.max(1, maxHP), 0, 1), 1),
				BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(240, 180, 65),
			}, { Corner = createElement("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
		}),
	})
	if handle then Roact.update(handle, view)
	else handle = Roact.mount(view, Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"), "MiningHP") end
end

return Display
