--[[
	Made in Heaven UI Controller
	Displays ability cooldowns and status
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Configuration
local ABILITIES = {
	{Key = "Q", Name = "Stand Toggle", Color = Color3.fromRGB(150, 200, 255)},
	{Key = "E", Name = "Barrage", Color = Color3.fromRGB(255, 200, 100)},
	{Key = "R", Name = "Heavy Punch", Color = Color3.fromRGB(255, 100, 100)},
	{Key = "T", Name = "Knife Throw", Color = Color3.fromRGB(200, 200, 200)},
	{Key = "F", Name = "Block", Color = Color3.fromRGB(100, 150, 255)},
	{Key = "G", Name = "Dash Combo", Color = Color3.fromRGB(255, 150, 200)},
	{Key = "H+", Name = "Universe Reset", Color = Color3.fromRGB(255, 255, 100)},
}

local UI_CONFIG = {
	Position = UDim2.new(0.02, 0, 0.4, 0),
	Size = UDim2.new(0, 60, 0, 60),
	Spacing = 70,
	CornerRadius = UDim.new(0.15, 0),
}

-- State
local AbilityFrames = {}
local MIHHandler = nil
local ToolEquipped = false
local UniverseResetUnlocked = false

-- Create UI
local function CreateAbilityUI()
	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MadeInHeavenUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Container
	local container = Instance.new("Frame")
	container.Name = "AbilitiesContainer"
	container.Position = UI_CONFIG.Position
	container.Size = UDim2.new(0, UI_CONFIG.Size.X.Offset, 0, (#ABILITIES * UI_CONFIG.Spacing) - 10)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	-- Create ability frames
	for i, ability in ipairs(ABILITIES) do
		local frame = Instance.new("Frame")
		frame.Name = ability.Key .. "Frame"
		frame.Size = UI_CONFIG.Size
		frame.Position = UDim2.new(0, 0, 0, (i - 1) * UI_CONFIG.Spacing)
		frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		frame.BorderSizePixel = 0
		frame.Parent = container

		-- Rounded corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UI_CONFIG.CornerRadius
		corner.Parent = frame

		-- Border
		local border = Instance.new("UIStroke")
		border.Color = ability.Color
		border.Thickness = 2
		border.Transparency = 0.3
		border.Parent = frame

		-- Key label
		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "KeyLabel"
		keyLabel.Size = UDim2.new(1, 0, 0.4, 0)
		keyLabel.Position = UDim2.new(0, 0, 0.3, 0)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.Text = ability.Key
		keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		keyLabel.TextScaled = true
		keyLabel.TextStrokeTransparency = 0.5
		keyLabel.Parent = frame

		-- Cooldown overlay
		local cooldownOverlay = Instance.new("Frame")
		cooldownOverlay.Name = "CooldownOverlay"
		cooldownOverlay.Size = UDim2.new(1, 0, 0, 0)
		cooldownOverlay.Position = UDim2.new(0, 0, 1, 0)
		cooldownOverlay.AnchorPoint = Vector2.new(0, 1)
		cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		cooldownOverlay.BackgroundTransparency = 0.5
		cooldownOverlay.BorderSizePixel = 0
		cooldownOverlay.ZIndex = 2
		cooldownOverlay.Parent = frame

		-- Cooldown text
		local cooldownText = Instance.new("TextLabel")
		cooldownText.Name = "CooldownText"
		cooldownText.Size = UDim2.new(1, 0, 0.3, 0)
		cooldownText.Position = UDim2.new(0, 0, 0.65, 0)
		cooldownText.BackgroundTransparency = 1
		cooldownText.Font = Enum.Font.Gotham
		cooldownText.Text = ""
		cooldownText.TextColor3 = Color3.fromRGB(255, 100, 100)
		cooldownText.TextScaled = true
		cooldownText.TextStrokeTransparency = 0.3
		cooldownText.ZIndex = 3
		cooldownText.Visible = false
		cooldownText.Parent = frame

		-- Ready indicator
		local readyIndicator = Instance.new("Frame")
		readyIndicator.Name = "ReadyIndicator"
		readyIndicator.Size = UDim2.new(0.2, 0, 0.2, 0)
		readyIndicator.Position = UDim2.new(0.8, 0, 0.05, 0)
		readyIndicator.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		readyIndicator.BorderSizePixel = 0
		readyIndicator.ZIndex = 3
		readyIndicator.Visible = false
		readyIndicator.Parent = frame

		local readyCorner = Instance.new("UICorner")
		readyCorner.CornerRadius = UDim.new(1, 0)
		readyCorner.Parent = readyIndicator

		-- Store reference
		AbilityFrames[ability.Key] = {
			Frame = frame,
			CooldownOverlay = cooldownOverlay,
			CooldownText = cooldownText,
			ReadyIndicator = readyIndicator,
			Border = border,
			Color = ability.Color,
		}
	end

	-- Status text (top of UI)
	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(2, 0, 0, 30)
	statusText.Position = UDim2.new(0, 0, 0, -40)
	statusText.BackgroundTransparency = 1
	statusText.Font = Enum.Font.GothamBold
	statusText.Text = "MADE IN HEAVEN"
	statusText.TextColor3 = Color3.fromRGB(255, 255, 200)
	statusText.TextScaled = false
	statusText.TextSize = 18
	statusText.TextStrokeTransparency = 0.5
	statusText.TextXAlignment = Enum.TextXAlignment.Left
	statusText.Parent = container

	return screenGui
end

-- Update cooldown display
local function UpdateCooldowns()
	if not MIHHandler or not ToolEquipped then return end

	for key, frame in pairs(AbilityFrames) do
		local cooldownRemaining = MIHHandler:GetRemainingCooldown(key)

		if cooldownRemaining > 0 then
			-- On cooldown
			local cooldownPercent = math.clamp(cooldownRemaining / 20, 0, 1) -- Assume max 20s cooldown for display
			frame.CooldownOverlay.Size = UDim2.new(1, 0, cooldownPercent, 0)
			frame.CooldownText.Text = string.format("%.1f", cooldownRemaining)
			frame.CooldownText.Visible = true
			frame.ReadyIndicator.Visible = false
			frame.Border.Color = Color3.fromRGB(100, 100, 100)
		else
			-- Ready
			frame.CooldownOverlay.Size = UDim2.new(1, 0, 0, 0)
			frame.CooldownText.Visible = false
			frame.ReadyIndicator.Visible = true
			frame.Border.Color = frame.Color
		end

		-- Special case for H+ (Universe Reset)
		if key == "H+" then
			if MIHHandler.UniverseResetAvailable then
				frame.Border.Color = Color3.fromRGB(255, 255, 100)
				frame.ReadyIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
				frame.ReadyIndicator.Visible = true
			else
				frame.ReadyIndicator.Visible = false
			end
		end

		-- Special case for Q (Stand Toggle)
		if key == "Q" then
			if MIHHandler.StandSummoned then
				frame.Border.Color = Color3.fromRGB(100, 255, 100)
				frame.Frame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
			else
				frame.Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
		end
	end
end

-- Tool equipped check
local function OnToolEquipped()
	ToolEquipped = true

	local character = Player.Character
	if character then
		-- Get MIH Handler
		local MadeInHeavenHandler = require(ReplicatedStorage.FPSSystem.Modules.MadeInHeavenHandler)
		MIHHandler = MadeInHeavenHandler.new(Player, character)
	end
end

local function OnToolUnequipped()
	ToolEquipped = false
	MIHHandler = nil
end

-- Listen for Bible tool
local function CheckForBibleTool()
	local character = Player.Character
	if not character then return end

	local tool = character:FindFirstChild("Bible")
	local backpack = Player:FindFirstChild("Backpack")

	if tool or (backpack and backpack:FindFirstChild("Bible")) then
		if not ToolEquipped then
			OnToolEquipped()
		end
	else
		if ToolEquipped then
			OnToolUnequipped()
		end
	end
end

-- Initialize
local ui = CreateAbilityUI()

-- Show/hide UI based on tool equipped
RunService.Heartbeat:Connect(function()
	CheckForBibleTool()

	if ui then
		ui.Enabled = ToolEquipped
	end

	if ToolEquipped and MIHHandler then
		UpdateCooldowns()
	end
end)

-- Cleanup on character respawn
Player.CharacterAdded:Connect(function(character)
	ToolEquipped = false
	MIHHandler = nil

	character:WaitForChild("Humanoid").Died:Connect(function()
		ToolEquipped = false
		MIHHandler = nil
	end)
end)
