local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.Parent.ModuleIndex)
local StatsContext = require(ModuleIndex.StatsContext)
local GearGridView = require(script.Parent.GearGridView)
local GearUtils = require(script.Parent.GearUtils)

local GearView = Roact.Component:extend("GearView")

function GearView:render()
	return createElement(StatsContext.context.Consumer, {
		render = function(data)
			local gearEntries = GearUtils.GetOwnedGearEntries(data)
			return createElement(GearGridView, {
				Visible = self.props.Visible,
				gearEntries = gearEntries,
				itemsPerRow = 8,
			})
		end,
	})
end

return GearView
