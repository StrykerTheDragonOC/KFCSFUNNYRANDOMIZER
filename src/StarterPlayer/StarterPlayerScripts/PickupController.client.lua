--[[
	Pickup Controller (Client)
	Handles client-side pickup effects and notifications
	Integrates with NVG system and ammo refill
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local PickupCollectedEvent = RemoteEvents:WaitForChild("PickupCollected")

local PickupController = {}

-- Pickup visual configurations
local PICKUP_VISUALS = {
	Armor = {
		NotificationColor = Color3.fromRGB(100, 150, 255),
		Icon = "🛡️", -- Placeholder
		Message = "ARMOR RESTORED"
	},

	HeavyArmor = {
		NotificationColor = Color3.fromRGB(50, 100, 200),
		Icon = "🛡️",
		Message = "HEAVY ARMOR EQUIPPED"
	},

	MedKit = {
		NotificationColor = Color3.fromRGB(255, 100, 100),
		Icon = "❤️",
		Message = "HEALTH RESTORED"
	},

	Bandage = {
		NotificationColor = Color3.fromRGB(255, 200, 200),
		Icon = "🩹",
		Message = "BANDAGE APPLIED"
	},

	Tourniquet = {
		NotificationColor = Color3.fromRGB(200, 150, 100),
		Icon = "⚕️",
		Message = "FRACTURE TREATED"
	},

	AmmoBox = {
		NotificationColor = Color3.fromRGB(255, 200, 50),
		Icon = "📦",
		Message = "AMMO REFILLED"
	},

	NightVision = {
		NotificationColor = Color3.fromRGB(100, 255, 100),
		Icon = "🔭",
		Message = "NIGHT VISION ACQUIRED"
	}
}

function PickupController:Initialize()
	-- Listen for pickup collection events
	PickupCollectedEvent.OnClientEvent:Connect(function(pickupType, config)
		self:OnPickupCollected(pickupType, config)
	end)

	print("PickupController initialized")
end

function PickupController:OnPickupCollected(pickupType, config)
	local visuals = PICKUP_VISUALS[pickupType]
	if not visuals then return end

	-- Show notification
	self:ShowPickupNotification(visuals.Message, config.Description, visuals.NotificationColor)

	-- Apply client-side effects
	if config.GivesNVG then
		self:GiveNightVision()
	elseif config.AmmoPercent then
		self:RefillAmmo(config.AmmoPercent)
	end

	-- Play visual effect
	self:PlayPickupEffect(visuals.NotificationColor)
end

function PickupController:GiveNightVision()
	-- Access the global NightVisionController
	if _G.NightVisionController then
		_G.NightVisionController:GiveNVG()
		print("Night Vision Goggles granted!")
	else
		warn("NightVisionController not found")
	end
end

function PickupController:RefillAmmo(ammoPercent)
	-- Find currently equipped weapon tool
	local character = player.Character
	if not character then return end

	local equippedTool = character:FindFirstChildOfClass("Tool")
	if not equippedTool then
		-- Check backpack
		equippedTool = player.Backpack:FindFirstChildOfClass("Tool")
	end

	if equippedTool then
		-- Signal to weapon script to refill ammo
		local ammoRefillEvent = equippedTool:FindFirstChild("RefillAmmo")
		if ammoRefillEvent and ammoRefillEvent:IsA("BindableEvent") then
			ammoRefillEvent:Fire(ammoPercent)
			print("Refilled ammo for:", equippedTool.Name)
		else
			warn("Weapon doesn't support ammo refill:", equippedTool.Name)
		end
	else
		print("No weapon equipped to refill ammo")
	end
end

function PickupController:ShowPickupNotification(title, description, color)
	-- Create notification GUI
	local notification = Instance.new("Frame")
	notification.Name = "PickupNotification"
	notification.Size = UDim2.new(0, 350, 0, 80)
	notification.Position = UDim2.new(1, -370, 0.8, 0)
	notification.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	notification.BackgroundTransparency = 0.2
	notification.BorderSizePixel = 0
	notification.Parent = playerGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification

	-- Colored accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, 0)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = color
	accentBar.BorderSizePixel = 0
	accentBar.Parent = notification

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 8)
	accentCorner.Parent = accentBar

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -20, 0, 30)
	titleLabel.Position = UDim2.new(0, 15, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = color
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = notification

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, -20, 0, 30)
	descLabel.Position = UDim2.new(0, 15, 0, 40)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = notification

	-- Slide in animation
	notification.Position = UDim2.new(1, 0, 0.8, 0)
	local slideIn = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -370, 0.8, 0)
	})
	slideIn:Play()

	-- Wait and slide out
	task.delay(3, function()
		local slideOut = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 0, 0.8, 0),
			BackgroundTransparency = 1
		})
		slideOut:Play()

		-- Also fade text
		TweenService:Create(titleLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		TweenService:Create(descLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()

		task.wait(0.3)
		notification:Destroy()
	end)
end

function PickupController:PlayPickupEffect(color)
	-- Create screen flash effect
	local flash = Instance.new("Frame")
	flash.Name = "PickupFlash"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0.7
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = playerGui

	-- Fade out
	local tween = TweenService:Create(flash, TweenInfo.new(0.5), {
		BackgroundTransparency = 1
	})
	tween:Play()

	game:GetService("Debris"):AddItem(flash, 0.6)
end

-- Initialize
PickupController:Initialize()

return PickupController
