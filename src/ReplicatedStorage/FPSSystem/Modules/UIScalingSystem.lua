-- UIScalingSystem.lua
-- Handles UI scaling and sizing for different screen resolutions

local UIScalingSystem = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Scaling configuration
local UI_SCALE_CONFIG = {
	MinScale = 0.5,
	MaxScale = 2.0,
	BaseResolution = Vector2.new(1920, 1080),
	ScaleMode = "ScaleWithScreenSize" -- or "FixedSize"
}

-- Current UI scale
local currentUIScale = 1.0

function UIScalingSystem:Initialize()
	print("UIScalingSystem: Initializing...")

	-- Calculate initial UI scale
	self:UpdateUIScale()

	-- Listen for viewport size changes (camera viewport, not PlayerGui)
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:UpdateUIScale()
		end)
	end

	print("✓ UIScalingSystem initialized - Scale:", currentUIScale)
end

function UIScalingSystem:UpdateUIScale()
	-- Use ViewportSize from workspace camera instead of UserInputService
	local camera = workspace.CurrentCamera
	local screenSize = camera.ViewportSize
	local baseSize = UI_SCALE_CONFIG.BaseResolution
	
	-- Calculate scale based on screen size
	local scaleX = screenSize.X / baseSize.X
	local scaleY = screenSize.Y / baseSize.Y
	local scale = math.min(scaleX, scaleY)
	
	-- Clamp scale to reasonable bounds
	scale = math.clamp(scale, UI_SCALE_CONFIG.MinScale, UI_SCALE_CONFIG.MaxScale)
	
	if scale ~= currentUIScale then
		currentUIScale = scale
		
		-- Apply scaling to all ScreenGuis
		self:ApplyScalingToAllGuis()
	end
end

function UIScalingSystem:ApplyScalingToAllGuis()
	for _, gui in pairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			self:ApplyScalingToGui(gui)
		end
	end
end

function UIScalingSystem:ApplyScalingToGui(screenGui)
	-- ScreenGui doesn't have ScaleType property
	-- Set other properties instead
	screenGui.ResetOnSpawn = false
	
	-- Don't scale certain UI elements that should maintain their size
	local skipScaling = {
		"FPSMainMenu", -- Main menu should use its own scaling
		"BattlefieldHUD", -- HUD should maintain consistent size
		"ScopeOverlay" -- Scope should maintain consistent size
	}
	
	for _, skipName in ipairs(skipScaling) do
		if screenGui.Name == skipName then
			return -- Skip scaling for these elements
		end
	end
	
	-- Apply scaling to frames and other UI elements
	self:ScaleUIElement(screenGui, currentUIScale)
end

function UIScalingSystem:ScaleUIElement(element, scale)
	if element:IsA("GuiObject") then
		-- Scale size and position
		if element.Size then
			element.Size = UDim2.new(
				element.Size.X.Scale,
				element.Size.X.Offset * scale,
				element.Size.Y.Scale,
				element.Size.Y.Offset * scale
			)
		end
		
		if element.Position then
			element.Position = UDim2.new(
				element.Position.X.Scale,
				element.Position.X.Offset * scale,
				element.Position.Y.Scale,
				element.Position.Y.Offset * scale
			)
		end
		
		-- Scale text size
		if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
			element.TextSize = math.floor(element.TextSize * scale)
		end
	end
	
	-- Recursively scale children
	for _, child in pairs(element:GetChildren()) do
		self:ScaleUIElement(child, scale)
	end
end

function UIScalingSystem:GetUIScale()
	return currentUIScale
end

function UIScalingSystem:SetUIScale(scale)
	scale = math.clamp(scale, UI_SCALE_CONFIG.MinScale, UI_SCALE_CONFIG.MaxScale)
	currentUIScale = scale
	self:ApplyScalingToAllGuis()
	print("UI Scale manually set to:", currentUIScale)
end

-- Console commands for testing
_G.UIScalingCommands = {
	getScale = function()
		print("Current UI Scale:", UIScalingSystem:GetUIScale())
	end,
	
	setScale = function(scale)
		UIScalingSystem:SetUIScale(tonumber(scale) or 1.0)
	end,
	
	refresh = function()
		UIScalingSystem:UpdateUIScale()
		UIScalingSystem:ApplyScalingToAllGuis()
		print("UI scaling refreshed")
	end
}

return UIScalingSystem
