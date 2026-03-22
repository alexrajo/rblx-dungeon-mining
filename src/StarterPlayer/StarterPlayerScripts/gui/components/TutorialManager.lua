local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local nextTutorialStepEvent = APIService.GetEvent("SendNextTutorialStep")

local createElement = Roact.createElement
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Panel = require(ModuleIndex.Panel)
local TextLabel = require(ModuleIndex.TextLabel)

local utils = ReplicatedStorage.utils
local ModuleLoader = require(utils.ModuleLoader)
local tutorialSteps = ModuleLoader.deepLoad(ModuleIndex.TutorialSteps)

local TutorialManager = Roact.Component:extend("TutorialManager")

function TutorialManager:init()
	self.ref = Roact.createRef()
	self:setState({
		currentTutorial = nil,
		currentStep = nil,
	})
end

function TutorialManager:_moveToStep(step, tutorialName)
	warn("TutorialManager _moveToStep: Not implemented!")

	self:setState(function(currentState)
		-- 1: Unload current step if it exists
		-- 2: Update currentStep state
        return {
            currentTutorial = tutorialName,
            currentStep = step
        }
		-- 3: Load new step
	end)
end

function TutorialManager:didMount()
	local panel = self.ref:getValue()
	if panel == nil then
		return
	end

	nextTutorialStepEvent.OnClientEvent:Connect(function(...)
		self:_moveToStep(...)
	end)
end

function TutorialManager:render()
    local descriptionText = ""
    if self.state.currentStep ~= nil then
        descriptionText = self.state.currentStep.description
    end

	return createElement("Frame", { [Roact.Ref] = self.ref, Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 0), BackgroundTransparency = 1, ZIndex = 200 }, {
        TutorialTextBox = createElement(Panel, {Size = UDim2.new(0.3, 0, 0.15, 0), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05)}, {
            Title = createElement(TextLabel, {Text = "Tutorial", Size = UDim2.new(1, -16, 0, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), textSize = 24}),
            Description = createElement(TextLabel, {Text = descriptionText, Size = UDim2.new(1, -16, 1, -20), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), textSize = 16, textProps = {TextWrapped = true}})
        })
    })
end

return TutorialManager

