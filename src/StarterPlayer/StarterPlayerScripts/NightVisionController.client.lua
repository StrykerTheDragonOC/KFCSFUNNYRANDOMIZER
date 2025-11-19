--[[
	Night Vision Controller
	Press N to toggle night vision goggles
	Only works if player has picked up NVG item
	Enhances visibility during night time
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local TimeOfDayChanged = RemoteEvents:FindFirstChild("TimeOfDayChanged") or Instance.new("RemoteEvent", RemoteEvents)
TimeOfDayChanged.Name = "TimeOfDayChanged"

local NightVisionController = {}

-- Settings
local hasNVG = false  -- Does player have night vision goggles?
local nvgActive = false
local isNightTime = false

-- Original lighting values
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalColorShift = Lighting.ColorShift_Top

-- NVG effect values
local NVG_BRIGHTNESS = 3
local NVG_COLOR = Color3.fromRGB(100, 255, 100)  -- Green tint
local NVG_AMBIENT = Color3.fromRGB(80, 150, 80)

function NightVisionController:Initialize()
	-- Listen for N key to toggle NVG
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.N then
			self:ToggleNVG()
		end
	end)

	-- Listen for time of day changes
	TimeOfDayChanged.OnClientEvent:Connect(function(timeOfDay)
		isNightTime = (timeOfDay == "Night")
		print("Time of day changed to:", timeOfDay)

		-- Auto-disable NVG during day (optional)
		if not isNightTime and nvgActive then
			-- Could auto-disable or leave on
		end
	end)

	-- Listen for NVG pickup
	player.CharacterAdded:Connect(function(character)
		self:OnCharacterSpawned(character)
	end)

	print("NightVisionController initialized - Press N to toggle")
end

function NightVisionController:OnCharacterSpawned(character)
	-- Reset NVG on respawn (would normally persist)
	-- hasNVG = false
	-- nvgActive = false
end

function NightVisionController:GiveNVG()
	hasNVG = true
	print("Night Vision Goggles acquired! Press N to toggle")

	-- Show notification
	self:ShowNotification("NIGHT VISION GOGGLES ACQUIRED\nPress N to toggle")
end

function NightVisionController:ToggleNVG()
	if not hasNVG then
		print("No night vision goggles available")
		self:ShowNotification("NIGHT VISION GOGGLES REQUIRED")
		return
	end

	nvgActive = not nvgActive

	if nvgActive then
		self:EnableNVG()
	else
		self:DisableNVG()
	end
end

function NightVisionController:EnableNVG()
	print("Night Vision: ON")

	-- Store original values
	originalBrightness = Lighting.Brightness
	originalAmbient = Lighting.Ambient
	originalColorShift = Lighting.ColorShift_Top

	-- Apply NVG effects
	TweenService:Create(Lighting, TweenInfo.new(0.3), {
		Brightness = NVG_BRIGHTNESS,
		Ambient = NVG_AMBIENT,
		ColorShift_Top = NVG_COLOR
	}):Play()

	-- Add green tint overlay
	self:CreateNVGOverlay()

	-- Play activation sound
	local activateSound = Instance.new("Sound")
	activateSound.SoundId = "rbxassetid://3581127385"  -- Tech sound
	activateSound.Volume = 0.3
	activateSound.Parent = workspace.CurrentCamera
	activateSound:Play()
	game:GetService("Debris"):AddItem(activateSound, 1)
end

function NightVisionController:DisableNVG()
	print("Night Vision: OFF")

	-- Restore original lighting
	TweenService:Create(Lighting, TweenInfo.new(0.3), {
		Brightness = originalBrightness,
		Ambient = originalAmbient,
		ColorShift_Top = originalColorShift
	}):Play()

	-- Remove overlay
	local overlay = playerGui:FindFirstChild("NVGOverlay")
	if overlay then
		overlay:Destroy()
	end

	-- Play deactivation sound
	local deactivateSound = Instance.new("Sound")
	deactivateSound.SoundId = "rbxassetid://3581127385"
	deactivateSound.Volume = 0.2
	deactivateSound.PlaybackSpeed = 0.8
	deactivateSound.Parent = workspace.CurrentCamera
	deactivateSound:Play()
	game:GetService("Debris"):AddItem(deactivateSound, 1)
end

function NightVisionController:CreateNVGOverlay()
	-- Remove existing overlay
	local existingOverlay = playerGui:FindFirstChild("NVGOverlay")
	if existingOverlay then
		existingOverlay:Destroy()
	end

	-- Create new overlay
	local overlay = Instance.new("ScreenGui")
	overlay.Name = "NVGOverlay"
	overlay.DisplayOrder = 1
	overlay.IgnoreGuiInset = true
	overlay.Parent = playerGui

	-- Green tint
	local tint = Instance.new("Frame")
	tint.Name = "Tint"
	tint.Size = UDim2.new(1, 0, 1, 0)
	tint.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	tint.BackgroundTransparency = 0.9
	tint.BorderSizePixel = 0
	tint.Parent = overlay

	-- Vignette effect (darker edges)
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxasset://textures/ui/VignetteOverlay.png"
	vignette.ImageColor3 = Color3.fromRGB(0, 100, 0)
	vignette.ImageTransparency = 0.3
	vignette.ScaleType = Enum.ScaleType.Slice
	vignette.SliceCenter = Rect.new(0, 0, 0, 0)
	vignette.Parent = overlay

	-- NVG status indicator
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(0, 200, 0, 30)
	status.Position = UDim2.new(1, -220, 0, 20)
	status.BackgroundTransparency = 1
	status.Text = "NVG: ACTIVE"
	status.TextColor3 = Color3.fromRGB(100, 255, 100)
	status.Font = Enum.Font.GothamBold
	status.TextSize = 14
	status.TextStrokeTransparency = 0.5
	status.Parent = overlay

	-- Pulsing effect
	spawn(function()
		while overlay.Parent do
			status.TextTransparency = 0
			task.wait(0.5)
			status.TextTransparency = 0.5
			task.wait(0.5)
		end
	end)
end

function NightVisionController:ShowNotification(text)
	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(0, 400, 0, 60)
	notification.Position = UDim2.new(0.5, -200, 0.3, 0)
	notification.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	notification.BackgroundTransparency = 0.2
	notification.Text = text
	notification.TextColor3 = Color3.fromRGB(100, 255, 100)
	notification.Font = Enum.Font.GothamBold
	notification.TextSize = 18
	notification.TextWrapped = true
	notification.Parent = playerGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification

	-- Fade out
	TweenService:Create(notification, TweenInfo.new(2), {
		BackgroundTransparency = 1,
		TextTransparency = 1
	}):Play()

	game:GetService("Debris"):AddItem(notification, 2.5)
end

-- Expose methods for pickup system
function NightVisionController:HasNVG()
	return hasNVG
end

function NightVisionController:IsNVGActive()
	return nvgActive
end

-- Auto-give NVG for testing (remove in production)
-- REMOVED: Night vision should only be obtained through pickups

-- Initialize
NightVisionController:Initialize()

-- Make globally accessible
_G.NightVisionController = NightVisionController

return NightVisionController
