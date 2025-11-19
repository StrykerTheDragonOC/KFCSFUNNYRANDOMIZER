--[[
	Scope Controller
	T key to toggle between 3D scope and UI scope (Phantom Forces style)
	- 3D Scope: Uses actual 3D model with viewport frame
	- UI Scope: Black overlay with scope reticle
	- Weapon sway when scoped
	- Shift to hold breath and stabilize (limited duration)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local ScopeController = {}

-- Scope settings
local SCOPE_MODE = "UI"  -- "3D" or "UI" (toggleable with T)
local SWAY_INTENSITY = 0.5  -- Weapon sway amount when scoped
local BREATH_DURATION = 5  -- Seconds can hold breath
local BREATH_RECOVERY = 3  -- Seconds to fully recover breath

-- State
local isScoped = false
local currentWeapon = nil
local scopeGui = nil
local breathRemaining = BREATH_DURATION
local isHoldingBreath = false
local breathRecovering = false

-- Sway variables
local swayOffset = Vector3.new(0, 0, 0)
local swayTime = 0

function ScopeController:Initialize()
	-- Create scope UI
	self:CreateScopeGUI()

	-- Listen for T key (toggle scope mode)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.T and isScoped then
			self:ToggleScopeMode()
		elseif input.KeyCode == Enum.KeyCode.LeftShift and isScoped then
			self:StartHoldingBreath()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			self:StopHoldingBreath()
		end
	end)

	-- Listen for right mouse button (scope)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:EnableScope()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:DisableScope()
		end
	end)

	-- Update sway and breath every frame
	RunService.RenderStepped:Connect(function(delta)
		self:UpdateSway(delta)
		self:UpdateBreath(delta)
	end)

	-- Listen for tool unequipped to disable scope
	player.CharacterAdded:Connect(function(character)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child == currentWeapon then
				self:DisableScope()
			end
		end)
	end)

	-- Setup for current character if already exists
	if player.Character then
		player.Character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child == currentWeapon then
				self:DisableScope()
			end
		end)
	end

	print("ScopeController initialized - Default mode:", SCOPE_MODE)
end

function ScopeController:CreateScopeGUI()
	scopeGui = Instance.new("ScreenGui")
	scopeGui.Name = "ScopeUI"
	scopeGui.Enabled = false
	scopeGui.ResetOnSpawn = false
	scopeGui.DisplayOrder = 200
	scopeGui.IgnoreGuiInset = true
	scopeGui.Parent = playerGui

	-- Black overlay (for UI scope mode)
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = scopeGui

	-- Scope hole (circular)
	local scopeHole = Instance.new("Frame")
	scopeHole.Name = "ScopeHole"
	scopeHole.Size = UDim2.new(0, 400, 0, 400)
	scopeHole.Position = UDim2.new(0.5, -200, 0.5, -200)
	scopeHole.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	scopeHole.BackgroundTransparency = 1
	scopeHole.BorderSizePixel = 0
	scopeHole.ClipsDescendants = true
	scopeHole.ZIndex = 2
	scopeHole.Parent = overlay

	local holeCorner = Instance.new("UICorner")
	holeCorner.CornerRadius = UDim.new(1, 0)  -- Circular
	holeCorner.Parent = scopeHole

	-- Make hole transparent (cut out center)
	local holeMask = Instance.new("ImageLabel")
	holeMask.Name = "HoleMask"
	holeMask.Size = UDim2.new(1, 0, 1, 0)
	holeMask.BackgroundTransparency = 1
	holeMask.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	holeMask.ImageTransparency = 1
	holeMask.Parent = scopeHole

	-- Scope reticle
	local reticle = Instance.new("ImageLabel")
	reticle.Name = "Reticle"
	reticle.Size = UDim2.new(1, 0, 1, 0)
	reticle.BackgroundTransparency = 1
	reticle.Image = "rbxassetid://7733955511"  -- Placeholder crosshair
	reticle.ImageColor3 = Color3.fromRGB(255, 255, 255)
	reticle.ZIndex = 3
	reticle.Parent = scopeHole

	-- Scope ring (border)
	local scopeRing = Instance.new("UIStroke")
	scopeRing.Color = Color3.fromRGB(0, 0, 0)
	scopeRing.Thickness = 4
	scopeRing.Parent = scopeHole

	-- Breath indicator
	local breathBar = Instance.new("Frame")
	breathBar.Name = "BreathBar"
	breathBar.Size = UDim2.new(0, 200, 0, 8)
	breathBar.Position = UDim2.new(0.5, -100, 1, -50)
	breathBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	breathBar.BorderSizePixel = 0
	breathBar.ZIndex = 3
	breathBar.Parent = scopeGui

	local breathFill = Instance.new("Frame")
	breathFill.Name = "Fill"
	breathFill.Size = UDim2.new(1, 0, 1, 0)
	breathFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	breathFill.BorderSizePixel = 0
	breathFill.Parent = breathBar

	local breathLabel = Instance.new("TextLabel")
	breathLabel.Name = "Label"
	breathLabel.Size = UDim2.new(1, 0, 1, -10)
	breathLabel.Position = UDim2.new(0, 0, 0, -20)
	breathLabel.BackgroundTransparency = 1
	breathLabel.Text = "HOLD SHIFT TO STABILIZE"
	breathLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	breathLabel.Font = Enum.Font.GothamBold
	breathLabel.TextSize = 12
	breathLabel.TextStrokeTransparency = 0.5
	breathLabel.ZIndex = 3
	breathLabel.Parent = breathBar

	-- Mode indicator
	local modeLabel = Instance.new("TextLabel")
	modeLabel.Name = "ModeLabel"
	modeLabel.Size = UDim2.new(0, 200, 0, 30)
	modeLabel.Position = UDim2.new(0.5, -100, 0, 30)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = "Press T to switch scope mode"
	modeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	modeLabel.Font = Enum.Font.Gotham
	modeLabel.TextSize = 14
	modeLabel.TextStrokeTransparency = 0.5
	modeLabel.ZIndex = 3
	modeLabel.Parent = scopeGui
end

function ScopeController:EnableScope()
	local character = player.Character
	if not character then return end

	-- Check if player has scoped weapon equipped
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then return end

	local weaponConfig = WeaponConfig:GetWeaponConfig(tool.Name)
	if not weaponConfig or not weaponConfig.HasScope then return end

	isScoped = true
	currentWeapon = tool

	-- Show scope UI (if UI mode)
	if SCOPE_MODE == "UI" then
		scopeGui.Enabled = true

		-- Zoom in camera FOV
		local targetFOV = weaponConfig.ScopeFOV or 20
		TweenService:Create(Camera, TweenInfo.new(0.2), {FieldOfView = targetFOV}):Play()
	else
		-- 3D scope mode (would need ViewportFrame implementation)
		-- For now, just zoom
		local targetFOV = weaponConfig.ScopeFOV or 20
		TweenService:Create(Camera, TweenInfo.new(0.2), {FieldOfView = targetFOV}):Play()
	end

	print("Scope enabled -", SCOPE_MODE, "mode")
end

function ScopeController:DisableScope()
	if not isScoped then return end

	isScoped = false
	currentWeapon = nil

	-- Hide scope UI
	scopeGui.Enabled = false

	-- Reset camera FOV
	TweenService:Create(Camera, TweenInfo.new(0.2), {FieldOfView = 70}):Play()

	-- Stop holding breath
	self:StopHoldingBreath()

	print("Scope disabled")
end

function ScopeController:ToggleScopeMode()
	-- Toggle between 3D and UI mode
	if SCOPE_MODE == "UI" then
		SCOPE_MODE = "3D"
	else
		SCOPE_MODE = "UI"
	end

	-- Update mode label
	local modeLabel = scopeGui:FindFirstChild("ModeLabel")
	if modeLabel then
		modeLabel.Text = "Scope Mode: " .. SCOPE_MODE .. " (Press T to switch)"
	end

	-- Reapply scope with new mode
	if isScoped then
		self:DisableScope()
		task.wait(0.1)
		self:EnableScope()
	end

	print("Switched to", SCOPE_MODE, "scope mode")
end

function ScopeController:StartHoldingBreath()
	if not isScoped or breathRemaining <= 0 or breathRecovering then return end

	isHoldingBreath = true
	print("Holding breath")
end

function ScopeController:StopHoldingBreath()
	if not isHoldingBreath then return end

	isHoldingBreath = false
	breathRecovering = true

	print("Stopped holding breath - recovering")
end

function ScopeController:UpdateSway(delta)
	if not isScoped then
		swayOffset = Vector3.new(0, 0, 0)
		return
	end

	swayTime = swayTime + delta

	-- Calculate sway based on whether holding breath
	local intensity = isHoldingBreath and (SWAY_INTENSITY * 0.1) or SWAY_INTENSITY

	-- Smooth sine wave sway
	local swayX = math.sin(swayTime * 2) * intensity * 0.005
	local swayY = math.cos(swayTime * 1.5) * intensity * 0.003

	swayOffset = Vector3.new(swayX, swayY, 0)

	-- Apply sway to camera
	Camera.CFrame = Camera.CFrame * CFrame.new(swayOffset)
end

function ScopeController:UpdateBreath(delta)
	-- Update breath meter
	if isHoldingBreath and breathRemaining > 0 then
		-- Depleting breath
		breathRemaining = math.max(0, breathRemaining - delta)

		if breathRemaining <= 0 then
			-- Out of breath
			self:StopHoldingBreath()
		end
	elseif breathRecovering or not isHoldingBreath then
		-- Recovering breath
		breathRemaining = math.min(BREATH_DURATION, breathRemaining + delta * (BREATH_DURATION / BREATH_RECOVERY))

		if breathRemaining >= BREATH_DURATION then
			breathRecovering = false
		end
	end

	-- Update breath bar UI
	if scopeGui and scopeGui.Enabled then
		local breathBar = scopeGui:FindFirstChild("BreathBar")
		if breathBar then
			local fill = breathBar:FindFirstChild("Fill")
			local label = breathBar:FindFirstChild("Label")

			if fill then
				fill.Size = UDim2.new(breathRemaining / BREATH_DURATION, 0, 1, 0)

				-- Color based on breath level
				if breathRemaining < 1 then
					fill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
				elseif breathRemaining < 2 then
					fill.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
				else
					fill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
				end
			end

			if label then
				if isHoldingBreath then
					label.Text = "HOLDING BREATH: " .. string.format("%.1f", breathRemaining) .. "s"
				elseif breathRecovering then
					label.Text = "RECOVERING..."
				else
					label.Text = "HOLD SHIFT TO STABILIZE"
				end
			end
		end
	end
end

-- Initialize
ScopeController:Initialize()

return ScopeController
