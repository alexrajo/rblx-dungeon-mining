local NOTIFICATION_DURATION = 5

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.services.Roact)

local Services = ReplicatedStorage.services
local APIService = require(Services.APIService)
local notificationEvent = APIService.GetEvent("SendNotification")

local createElement = Roact.createElement
local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local NotificationPanel = require(ModuleIndex.NotificationPanel)

local NotificationManager = Roact.Component:extend("NotificationManager")

function NotificationManager:displayNewNotification(notification)
	local folder = self.ref:getValue()
	if folder == nil then
		return
	end

	if notification.Type == "levelup" then
		-- Play level up sound
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://112485797063762"
		sound.Name = "LevelUpSound"
		sound.Volume = 5
		sound.Parent = game.Players.LocalPlayer.PlayerGui
		sound:Play()
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end

	local panel = createElement(
		NotificationPanel,
		{
			notification = notification,
			duration = NOTIFICATION_DURATION,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.05),
		}
	)
	local handle = Roact.mount(panel, folder, notification.Title)

	task.delay(NOTIFICATION_DURATION, function()
		Roact.unmount(handle)
	end)
end

function NotificationManager:init()
	self.ref = Roact.createRef()
end

function NotificationManager:didMount()
	local panel = self.ref:getValue()
	if panel == nil then
		return
	end

	notificationEvent.OnClientEvent:Connect(function(notification)
		self:displayNewNotification(notification)
	end)
end

function NotificationManager:render()
	return createElement("Folder", { [Roact.Ref] = self.ref })
end

return NotificationManager

