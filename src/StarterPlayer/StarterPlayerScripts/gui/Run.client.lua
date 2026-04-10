local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)
local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local createElement = Roact.createElement

local Root = require(script.Parent.Root)

local rootElement = createElement(Root)

Roact.mount(rootElement, game.Players.LocalPlayer.PlayerGui, "Root")