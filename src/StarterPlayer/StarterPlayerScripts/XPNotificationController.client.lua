--[[
	XPNotificationController.client.lua
	Displays XP and Level-up notifications to the player
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

repeat
	task.wait()
until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents

local XPNotificationController = {}

-- Notification queue
local notificationQueue = {}
local isShowingNotification = false

-- Create ScreenGui
local function createNotificationGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "XPNotifications"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui

	return screenGui
end

local notificationGui = createNotificationGui()

-- XP Notification (small, bottom-right)
function XPNotificationController:ShowXPNotification(data)
	local amount = data.Amount or 0
	local reason = data.Reason or "XP Gained"

	-- Create notification frame
	local notification = Instance.new("Frame")
	notification.Name = "XPNotification"
	notification.Size = UDim2.fromOffset(250, 60)
	notification.Position = UDim2.new(1, -270, 1, 100) -- Start off-screen bottom
	notification.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	notification.BackgroundTransparency = 0.2
	notification.BorderSizePixel = 0
	notification.Parent = notificationGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = notification

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 200, 100)
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = notification

	-- XP Amount Label
	local xpLabel = Instance.new("TextLabel")
	xpLabel.Name = "XPAmount"
	xpLabel.Size = UDim2.fromScale(0.4, 1)
	xpLabel.Position = UDim2.fromScale(0, 0)
	xpLabel.BackgroundTransparency = 1
	xpLabel.Text = "+" .. tostring(amount) .. " XP"
	xpLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	xpLabel.TextScaled = true
	xpLabel.Font = Enum.Font.GothamBold
	xpLabel.Parent = notification

	-- Reason Label
	local reasonLabel = Instance.new("TextLabel")
	reasonLabel.Name = "Reason"
	reasonLabel.Size = UDim2.fromScale(0.55, 1)
	reasonLabel.Position = UDim2.fromScale(0.45, 0)
	reasonLabel.BackgroundTransparency = 1
	reasonLabel.Text = reason
	reasonLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	reasonLabel.TextScaled = true
	reasonLabel.Font = Enum.Font.Gotham
	reasonLabel.TextXAlignment = Enum.TextXAlignment.Left
	reasonLabel.Parent = notification

	-- Slide in animation
	local slideIn = TweenService:Create(
		notification,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -270, 1, -80)}
	)

	-- Fade out animation
	local fadeOut = TweenService:Create(
		notification,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	)

	local labelFade = TweenService:Create(
		xpLabel,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1}
	)

	local reasonFade = TweenService:Create(
		reasonLabel,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1}
	)

	local strokeFade = TweenService:Create(
		stroke,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Transparency = 1}
	)

	-- Play slide in
	slideIn:Play()

	-- Wait and fade out
	task.delay(2.5, function()
		fadeOut:Play()
		labelFade:Play()
		reasonFade:Play()
		strokeFade:Play()

		fadeOut.Completed:Wait()
		notification:Destroy()
	end)
end

-- Level-up Notification (large, center screen)
function XPNotificationController:ShowLevelUpNotification(data)
	local newLevel = data.NewLevel or 0
	local creditsEarned = data.CreditsEarned or 0

	-- Create notification frame
	local notification = Instance.new("Frame")
	notification.Name = "LevelUpNotification"
	notification.Size = UDim2.fromOffset(500, 200)
	notification.Position = UDim2.fromScale(0.5, 0.5)
	notification.AnchorPoint = Vector2.new(0.5, 0.5)
	notification.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	notification.BackgroundTransparency = 0.1
	notification.BorderSizePixel = 0
	notification.Parent = notificationGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = notification

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0) -- Gold
	stroke.Thickness = 4
	stroke.Transparency = 0
	stroke.Parent = notification

	-- Glow effect
	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.Size = UDim2.fromScale(1.2, 1.2)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://5028857472"
	glow.ImageColor3 = Color3.fromRGB(255, 215, 0)
	glow.ImageTransparency = 0.5
	glow.ZIndex = 0
	glow.Parent = notification

	-- "LEVEL UP!" Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Position = UDim2.fromScale(0, 0.1)
	title.BackgroundTransparency = 1
	title.Text = "LEVEL UP!"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = notification

	-- Level Number
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "Level"
	levelLabel.Size = UDim2.new(1, 0, 0, 50)
	levelLabel.Position = UDim2.fromScale(0, 0.45)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Rank " .. tostring(newLevel)
	levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	levelLabel.TextScaled = true
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.Parent = notification

	-- Credits Earned
	local creditsLabel = Instance.new("TextLabel")
	creditsLabel.Name = "Credits"
	creditsLabel.Size = UDim2.new(1, 0, 0, 40)
	creditsLabel.Position = UDim2.fromScale(0, 0.7)
	creditsLabel.BackgroundTransparency = 1
	creditsLabel.Text = "+" .. tostring(creditsEarned) .. " Credits"
	creditsLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	creditsLabel.TextScaled = true
	creditsLabel.Font = Enum.Font.Gotham
	creditsLabel.Parent = notification

	-- Scale in animation
	notification.Size = UDim2.fromOffset(0, 0)
	local scaleIn = TweenService:Create(
		notification,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.fromOffset(500, 200)}
	)

	-- Glow pulse animation
	local glowPulse = TweenService:Create(
		glow,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ImageTransparency = 0.8, Size = UDim2.fromScale(1.4, 1.4)}
	)

	-- Scale out animation
	local scaleOut = TweenService:Create(
		notification,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Size = UDim2.fromOffset(0, 0)}
	)

	-- Play animations
	scaleIn:Play()
	glowPulse:Play()

	-- Wait and scale out
	task.delay(3, function()
		glowPulse:Cancel()
		scaleOut:Play()

		scaleOut.Completed:Wait()
		notification:Destroy()
	end)
end

-- Listen for XP Awarded
local xpAwardedEvent = RemoteEvents:FindFirstChild("XPAwarded")
if xpAwardedEvent then
	xpAwardedEvent.OnClientEvent:Connect(function(data)
		XPNotificationController:ShowXPNotification(data)
	end)
end

-- Listen for Level Up
local levelUpEvent = RemoteEvents:FindFirstChild("LevelUp")
if levelUpEvent then
	levelUpEvent.OnClientEvent:Connect(function(data)
		XPNotificationController:ShowLevelUpNotification(data)
	end)
end

print("XPNotificationController initialized")

return XPNotificationController

