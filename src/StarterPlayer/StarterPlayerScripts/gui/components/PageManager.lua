local player = game.Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Services = ReplicatedStorage.services
local Roact = require(Services.Roact)
local APIService = require(Services.APIService)

-- Use collection service to do tag specific operations
local CollectionService = game:GetService("CollectionService")

local createElement = Roact.createElement

local ModuleIndex = require(script.Parent.Parent.ModuleIndex)
local Sidebar = require(ModuleIndex.Sidebar)

local blurInstance = game.Lighting:WaitForChild("Blur")
local camera = game.Workspace.CurrentCamera
local openTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local closeTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local currentBlurTween: Tween = nil
local currentFOVTween: Tween = nil

local openMineElevatorEvent = APIService.GetEvent("OpenMineElevator")
local signalTutorialEvent = APIService.GetEvent("SignalTutorial")

local PageManager = Roact.Component:extend("PageManager")

PageManager.connections = {}
PageManager.currentlyActivePageCircle = nil

function beginBlurTween(tweenInfo: TweenInfo, size: number)
	if currentBlurTween ~= nil then
		currentBlurTween:Cancel()
	end
	local tween = TweenService:Create(blurInstance, tweenInfo, {Size = size})
	currentBlurTween = tween
	tween:Play()
end

function beginFOVTween(tweenInfo: TweenInfo, fov: number)
	if currentFOVTween ~= nil then
		currentFOVTween:Cancel()
	end
	local tween = TweenService:Create(camera, tweenInfo, {FieldOfView = fov})
	currentFOVTween = tween
	tween:Play()
end

function PagesFragment(props)
	return Roact.createFragment(props.pageComponents)
end

function PageManager:closeAllPages()
	self:setState({
		currentPage = "",
		currentShopId = Roact.None,
	})
end

function PageManager:openPage(pageName: string, shopId: string?)
	if self.state.currentPage == pageName then return end

    signalTutorialEvent:FireServer("openPage_"..pageName)

	self:setState({
		currentPage = pageName,
		currentShopId = shopId or Roact.None,
	})
end

function PageManager:closePage(pageName: string)
	self:closeAllPages() -- TODO: Might want to change this to close specific page in the future
end

function PageManager:togglePage(pageName: string)
	if self.state.currentPage == pageName then
		self:closePage(pageName)
	else
		self:openPage(pageName)
	end
end

function PageManager:init()
	self:setState({
		currentPage = "None",
		currentShopId = Roact.None,
	})
end

function PageManager:render()
	local pages: {ModuleScript} = self.props.pages
	local pageComponents = {}
	
	local currentPageBinding = Roact.createBinding(self.state.currentPage)
	
	-- Retrieve the component from all pages provided in props
	for _, pageModule in pairs(pages) do
		local success, res = pcall(function()
			local page = require(pageModule)
			return createElement(page, {
				closeAllPages = function()
					self:closeAllPages()
				end,
				currentPageBinding = currentPageBinding,
				currentShopId = self.state.currentShopId,
			})
		end)
		if success then
			table.insert(pageComponents, res)
		else
			warn("Could not render page: ", pageModule)
			warn("Reason: ", res)
		end
	end
	
	return createElement("Frame", {Position = self.props.Position, Size = self.props.Size, BackgroundTransparency = 1, ZIndex = 99}, {
		Sidebar = createElement(Sidebar, {
			togglePage = function(pageName: string) 
				self:togglePage(pageName)
			end
		}),
		Pages = createElement(PagesFragment, {pageComponents = pageComponents})
	})
end

function PageManager:didMount()
	self.connections["openMineElevator"] = openMineElevatorEvent.OnClientEvent:Connect(function()
		self:openPage("MineElevator")
	end)

	self.connections["checkActivationCircles"] = game:GetService("RunService").Heartbeat:Connect(function()
		
		local char = player.Character
		if char == nil then return end
		local charRoot: BasePart? = char.PrimaryPart
		if charRoot == nil then return end
		
		for _, activationCircle: BasePart in pairs(CollectionService:GetTagged("PageActivationCircle")) do
			local pageName = activationCircle:GetAttribute("pageName")
			if pageName then
				local activationCirclePosWithoutY = Vector3.new(activationCircle.Position.X, 0, activationCircle.Position.Z)
				local charRootPosWithoutY = Vector3.new(charRoot.Position.X, 0, charRoot.Position.Z)
				
				local activationCirclePosY = activationCircle.Position.Y
				local charRootPosY = charRoot.Position.Y
				
				local lateralDistance = (activationCirclePosWithoutY - charRootPosWithoutY).Magnitude
				local verticalDiff = charRootPosY - activationCirclePosY
				
				if lateralDistance <= activationCircle.Size.Z/2 and verticalDiff < 20 and verticalDiff > -1 then
					if self.currentlyActivePageCircle == activationCircle then break end
					
					self.currentlyActivePageCircle = activationCircle
					local shopId = activationCircle:GetAttribute("shopId")
					self:openPage(pageName, shopId)
					break
				elseif self.currentlyActivePageCircle == activationCircle then
					self:closePage(pageName)
					self.currentlyActivePageCircle = nil
				end
			end
		end
	end)
end

function PageManager:willUnmount()
	
	-- Make sure to disconnect all connections when the component is unmounted to avoid memory leaks
	
	for _, connection in pairs(self.connections) do
		if connection == nil then continue end
		connection:Disconnect()
	end
end

function PageManager:didUpdate(previousProps, previousState)
	local currentPage = self.state.currentPage
	local previousPage = previousState.currentPage
	
	if currentPage ~= previousPage then
		if currentPage == "" then
			beginBlurTween(closeTweenInfo, 0)
			beginFOVTween(closeTweenInfo, 70)
		else
			beginBlurTween(openTweenInfo, 24)
			beginFOVTween(openTweenInfo, 65)
		end
	end
end

return PageManager
