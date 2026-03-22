--[[

	Copyright © 2023, MapleMarvel (https://www.roblox.com/users/263710410/profile). All Rights Reserved.
	
	
	ExtendTextWithStrokeLocalScript:
	LocalScript that adds additional functionality.
	
--]]


-- Services
local Players = game:GetService("Players")

-- Modules
local SCRIPTS_FOLDER_NAME = "Epic UI Pack"
local ExtendTextLabelClass = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild(SCRIPTS_FOLDER_NAME):WaitForChild("ExtendTextLabelClass"))

-- GUI Variables
local guiObject = script.Parent.Parent

-- Configuration Variables
local configuration = guiObject:WaitForChild("Configuration")
local guiObjectTextLabelVar = configuration:WaitForChild("ObjectTextLabel")
local guiObjectTextLabelStrokeVar = configuration:WaitForChild("ObjectTextLabelStroke")

-- Local Variables
local attributesParent = guiObject


-- Validate
if guiObjectTextLabelVar and guiObjectTextLabelStrokeVar then

	-- Wait for the objects to load
	while not guiObjectTextLabelVar.Value do task.wait() end
	while not guiObjectTextLabelStrokeVar.Value do task.wait() end

	local guiObjectTextLabel = guiObjectTextLabelVar.Value
	local guiObjectTextLabelStroke = guiObjectTextLabelStrokeVar.Value


	-- Extend the TextLabels

	-- Extend both the main text and the stroke text
	local extendedTextLabel = ExtendTextLabelClass.new(guiObjectTextLabel)
	local extendedTextLabelStroke = ExtendTextLabelClass.new(guiObjectTextLabelStroke)

	-- Make the TextLabel text be settable via attributes
	extendedTextLabel:SetTextValueFromAttributes(attributesParent, "TextValueEnabled", "TextValue")
	extendedTextLabelStroke:SetTextValueFromAttributes(attributesParent, "TextValueEnabled", "TextValue")

	-- Make the TextLabel size be settable via attributes
	extendedTextLabel:SetTextSizeFromAttributes(attributesParent, "TextSizeEnabled", "TextSizeScale", guiObject)
	extendedTextLabelStroke:SetTextSizeFromAttributes(attributesParent, "TextSizeEnabled", "TextSizeScale", guiObject)

end