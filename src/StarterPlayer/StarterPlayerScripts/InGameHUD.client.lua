--[[
	In-Game HUD Controller
	Handles all HUD elements during gameplay (health, radar, killfeeds, match info, etc.)
	Separate from weapon UI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for FPS System
repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

-- UI state
local hudScreenGui = nil
local isInitialized = false

-- HUD elements
local elements = {
	container = nil,
	healthBar = nil,
	healthText = nil,
	armorBar = nil,
	armorText = nil,
	radar = nil,
	radarDots = {},
	killFeed = nil,
	matchInfo = nil,
	matchTimer = nil,
	matchScore = nil,
	gamemodeName = nil,
	playerCount = nil,
	statusEffects = nil
}

-- HUD Controller
local InGameHUD = {}

-- Create the in-game HUD
function InGameHUD:CreateHUD()
	-- Reuse existing HUD if present to prevent duplication
	local existing = playerGui:FindFirstChild("InGameHUD")
	if existing and existing:IsA("ScreenGui") then
		hudScreenGui = existing
		hudScreenGui.ResetOnSpawn = false
		hudScreenGui.DisplayOrder = 5
		hudScreenGui.IgnoreGuiInset = true
		hudScreenGui.Enabled = false  -- Start hidden until deployed
		print("✓ Reusing existing InGameHUD (hidden by default)")
	else
		-- Create ScreenGui
		hudScreenGui = Instance.new("ScreenGui")
		hudScreenGui.Name = "InGameHUD"
		hudScreenGui.ResetOnSpawn = false
		hudScreenGui.DisplayOrder = 5
		hudScreenGui.IgnoreGuiInset = true
		hudScreenGui.Enabled = false  -- Start hidden until deployed
		hudScreenGui.Parent = playerGui
		print("✓ Created new InGameHUD (hidden by default)")
	end

	-- Main container
	local container = hudScreenGui:FindFirstChild("HUDContainer")
	if not container then
		container = Instance.new("Frame")
		container.Name = "HUDContainer"
		container.Size = UDim2.new(1, 0, 1, 0)
		container.Position = UDim2.new(0, 0, 0, 0)
		container.BackgroundTransparency = 1
		container.Parent = hudScreenGui
	end
	elements.container = container

	-- Create sub-elements
	self:CreateHealthBar(container)
	self:CreateAmmoDisplay(container)
	self:CreateCrosshair(container)
	self:CreateRadar(container)
	self:CreateKillFeed(container)
	self:CreateMatchInfo(container)
	self:CreateStatusEffects(container)

	print("✓ InGameHUD created successfully")
end

-- Create health and armor bars
function InGameHUD:CreateHealthBar(parent)
	-- Health container (Bottom Left)
	local healthContainer = Instance.new("Frame")
	healthContainer.Name = "HealthContainer"
	healthContainer.Size = UDim2.new(0, 300, 0, 80)
	healthContainer.Position = UDim2.new(0, 20, 1, -100)
	healthContainer.BackgroundTransparency = 1
	healthContainer.Parent = parent

	-- Health bar background
	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBackground"
	healthBg.Size = UDim2.new(1, 0, 0, 30)
	healthBg.Position = UDim2.new(0, 0, 0, 0)
	healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	healthBg.BackgroundTransparency = 0.3
	healthBg.BorderSizePixel = 0
	healthBg.Parent = healthContainer

	local healthCorner = Instance.new("UICorner")
	healthCorner.CornerRadius = UDim.new(0, 6)
	healthCorner.Parent = healthBg

	-- Health bar
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.Position = UDim2.new(0, 0, 0, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthBg
	elements.healthBar = healthBar

	local healthBarCorner = Instance.new("UICorner")
	healthBarCorner.CornerRadius = UDim.new(0, 6)
	healthBarCorner.Parent = healthBar

	-- Health text
	local healthText = Instance.new("TextLabel")
	healthText.Name = "HealthText"
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.Position = UDim2.new(0, 0, 0, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = "100"
	healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthText.Font = Enum.Font.GothamBold
	healthText.TextSize = 18
	healthText.Parent = healthBg
	elements.healthText = healthText

	-- Armor bar background
	local armorBg = Instance.new("Frame")
	armorBg.Name = "ArmorBackground"
	armorBg.Size = UDim2.new(1, 0, 0, 20)
	armorBg.Position = UDim2.new(0, 0, 0, 40)
	armorBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	armorBg.BackgroundTransparency = 0.3
	armorBg.BorderSizePixel = 0
	armorBg.Parent = healthContainer

	local armorCorner = Instance.new("UICorner")
	armorCorner.CornerRadius = UDim.new(0, 4)
	armorCorner.Parent = armorBg

	-- Armor bar
	local armorBar = Instance.new("Frame")
	armorBar.Name = "ArmorBar"
	armorBar.Size = UDim2.new(0, 0, 1, 0)
	armorBar.Position = UDim2.new(0, 0, 0, 0)
	armorBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	armorBar.BorderSizePixel = 0
	armorBar.Parent = armorBg
	elements.armorBar = armorBar

	local armorBarCorner = Instance.new("UICorner")
	armorBarCorner.CornerRadius = UDim.new(0, 4)
	armorBarCorner.Parent = armorBar

	-- Armor text
	local armorText = Instance.new("TextLabel")
	armorText.Name = "ArmorText"
	armorText.Size = UDim2.new(1, 0, 1, 0)
	armorText.Position = UDim2.new(0, 0, 0, 0)
	armorText.BackgroundTransparency = 1
	armorText.Text = "0"
	armorText.TextColor3 = Color3.fromRGB(255, 255, 255)
	armorText.Font = Enum.Font.Gotham
	armorText.TextSize = 14
	armorText.Parent = armorBg
	elements.armorText = armorText
end

-- Create ammo display
function InGameHUD:CreateAmmoDisplay(parent)
	-- Ammo container (Bottom Right)
	local ammoContainer = Instance.new("Frame")
	ammoContainer.Name = "AmmoContainer"
	ammoContainer.Size = UDim2.new(0, 250, 0, 80)
	ammoContainer.Position = UDim2.new(1, -270, 1, -100)
	ammoContainer.BackgroundTransparency = 1
	ammoContainer.Parent = parent

	-- Current ammo (large text)
	local currentAmmo = Instance.new("TextLabel")
	currentAmmo.Name = "CurrentAmmo"
	currentAmmo.Size = UDim2.new(0.5, 0, 1, 0)
	currentAmmo.Position = UDim2.new(0, 0, 0, 0)
	currentAmmo.BackgroundTransparency = 1
	currentAmmo.Text = "30"
	currentAmmo.TextColor3 = Color3.fromRGB(255, 255, 255)
	currentAmmo.Font = Enum.Font.GothamBold
	currentAmmo.TextSize = 48
	currentAmmo.TextXAlignment = Enum.TextXAlignment.Right
	currentAmmo.Parent = ammoContainer
	elements.currentAmmo = currentAmmo

	-- Separator
	local separator = Instance.new("TextLabel")
	separator.Name = "Separator"
	separator.Size = UDim2.new(0, 20, 1, 0)
	separator.Position = UDim2.new(0.5, 0, 0, 0)
	separator.BackgroundTransparency = 1
	separator.Text = "/"
	separator.TextColor3 = Color3.fromRGB(150, 150, 150)
	separator.Font = Enum.Font.GothamBold
	separator.TextSize = 36
	separator.Parent = ammoContainer

	-- Reserve ammo (smaller text)
	local reserveAmmo = Instance.new("TextLabel")
	reserveAmmo.Name = "ReserveAmmo"
	reserveAmmo.Size = UDim2.new(0.5, -20, 1, 0)
	reserveAmmo.Position = UDim2.new(0.5, 20, 0, 0)
	reserveAmmo.BackgroundTransparency = 1
	reserveAmmo.Text = "120"
	reserveAmmo.TextColor3 = Color3.fromRGB(200, 200, 200)
	reserveAmmo.Font = Enum.Font.Gotham
	reserveAmmo.TextSize = 24
	reserveAmmo.TextXAlignment = Enum.TextXAlignment.Left
	reserveAmmo.TextYAlignment = Enum.TextYAlignment.Bottom
	reserveAmmo.Parent = ammoContainer
	elements.reserveAmmo = reserveAmmo

	-- Weapon name (below ammo)
	local weaponName = Instance.new("TextLabel")
	weaponName.Name = "WeaponName"
	weaponName.Size = UDim2.new(1, 0, 0, 20)
	weaponName.Position = UDim2.new(0, 0, 1, 5)
	weaponName.BackgroundTransparency = 1
	weaponName.Text = "G36"
	weaponName.TextColor3 = Color3.fromRGB(180, 180, 180)
	weaponName.Font = Enum.Font.GothamBold
	weaponName.TextSize = 14
	weaponName.TextXAlignment = Enum.TextXAlignment.Right
	weaponName.Parent = ammoContainer
	elements.weaponName = weaponName
end

-- Create crosshair
function InGameHUD:CreateCrosshair(parent)
	-- Crosshair container (Screen center)
	local crosshairContainer = Instance.new("Frame")
	crosshairContainer.Name = "CrosshairContainer"
	crosshairContainer.Size = UDim2.new(0, 40, 0, 40)
	crosshairContainer.Position = UDim2.new(0.5, -20, 0.5, -20)
	crosshairContainer.BackgroundTransparency = 1
	crosshairContainer.Parent = parent
	elements.crosshair = crosshairContainer

	-- Crosshair lines
	local lineSize = 12
	local lineThickness = 2
	local gap = 4

	-- Top line
	local top = Instance.new("Frame")
	top.Size = UDim2.new(0, lineThickness, 0, lineSize)
	top.Position = UDim2.new(0.5, -lineThickness/2, 0, 0)
	top.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	top.BorderSizePixel = 0
	top.Parent = crosshairContainer

	-- Bottom line
	local bottom = Instance.new("Frame")
	bottom.Size = UDim2.new(0, lineThickness, 0, lineSize)
	bottom.Position = UDim2.new(0.5, -lineThickness/2, 1, -lineSize)
	bottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bottom.BorderSizePixel = 0
	bottom.Parent = crosshairContainer

	-- Left line
	local left = Instance.new("Frame")
	left.Size = UDim2.new(0, lineSize, 0, lineThickness)
	left.Position = UDim2.new(0, 0, 0.5, -lineThickness/2)
	left.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	left.BorderSizePixel = 0
	left.Parent = crosshairContainer

	-- Right line
	local right = Instance.new("Frame")
	right.Size = UDim2.new(0, lineSize, 0, lineThickness)
	right.Position = UDim2.new(1, -lineSize, 0.5, -lineThickness/2)
	right.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	right.BorderSizePixel = 0
	right.Parent = crosshairContainer

	-- Center dot
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 2, 0, 2)
	dot.Position = UDim2.new(0.5, -1, 0.5, -1)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BorderSizePixel = 0
	dot.Parent = crosshairContainer

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot
end

-- Create radar
function InGameHUD:CreateRadar(parent)
	-- Radar container (Top Left)
	local radarContainer = Instance.new("Frame")
	radarContainer.Name = "RadarContainer"
	radarContainer.Size = UDim2.new(0, 200, 0, 200)
	radarContainer.Position = UDim2.new(0, 20, 0, 20)
	radarContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	radarContainer.BackgroundTransparency = 0.5
	radarContainer.BorderSizePixel = 0
	radarContainer.Parent = parent
	elements.radar = radarContainer

	local radarCorner = Instance.new("UICorner")
	radarCorner.CornerRadius = UDim.new(0, 8)
	radarCorner.Parent = radarContainer

	-- Radar grid lines
	local gridH = Instance.new("Frame")
	gridH.Name = "GridH"
	gridH.Size = UDim2.new(1, 0, 0, 1)
	gridH.Position = UDim2.new(0, 0, 0.5, 0)
	gridH.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	gridH.BorderSizePixel = 0
	gridH.Parent = radarContainer

	local gridV = Instance.new("Frame")
	gridV.Name = "GridV"
	gridV.Size = UDim2.new(0, 1, 1, 0)
	gridV.Position = UDim2.new(0.5, 0, 0, 0)
	gridV.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	gridV.BorderSizePixel = 0
	gridV.Parent = radarContainer

	-- Player indicator (center)
	local playerDot = Instance.new("Frame")
	playerDot.Name = "PlayerDot"
	playerDot.Size = UDim2.new(0, 8, 0, 8)
	playerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
	playerDot.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	playerDot.BorderSizePixel = 0
	playerDot.Parent = radarContainer

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = playerDot

	-- Gamemode name (below radar)
	local gamemodeName = Instance.new("TextLabel")
	gamemodeName.Name = "GamemodeName"
	gamemodeName.Size = UDim2.new(1, 0, 0, 20)
	gamemodeName.Position = UDim2.new(0, 0, 1, 5)
	gamemodeName.BackgroundTransparency = 1
	gamemodeName.Text = "TEAM DEATHMATCH"
	gamemodeName.TextColor3 = Color3.fromRGB(255, 255, 255)
	gamemodeName.Font = Enum.Font.GothamBold
	gamemodeName.TextSize = 12
	gamemodeName.Parent = radarContainer
	elements.gamemodeName = gamemodeName

	-- Match score (below gamemode)
	local matchScore = Instance.new("TextLabel")
	matchScore.Name = "MatchScore"
	matchScore.Size = UDim2.new(1, 0, 0, 18)
	matchScore.Position = UDim2.new(0, 0, 1, 28)
	matchScore.BackgroundTransparency = 1
	matchScore.Text = "KFC: 0 | FBI: 0"
	matchScore.TextColor3 = Color3.fromRGB(220, 220, 220)
	matchScore.Font = Enum.Font.Gotham
	matchScore.TextSize = 11
	matchScore.Parent = radarContainer
	elements.matchScore = matchScore
end

-- Create killfeed
function InGameHUD:CreateKillFeed(parent)
	-- Killfeed container (Top Right)
	local killFeedContainer = Instance.new("Frame")
	killFeedContainer.Name = "KillFeedContainer"
	killFeedContainer.Size = UDim2.new(0, 350, 0, 200)
	killFeedContainer.Position = UDim2.new(1, -370, 0, 20)
	killFeedContainer.BackgroundTransparency = 1
	killFeedContainer.Parent = parent
	elements.killFeed = killFeedContainer

	-- UIListLayout for killfeed entries
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = killFeedContainer
end

-- Create match info
function InGameHUD:CreateMatchInfo(parent)
	-- Match info container (Top Center)
	local matchInfoContainer = Instance.new("Frame")
	matchInfoContainer.Name = "MatchInfoContainer"
	matchInfoContainer.Size = UDim2.new(0, 300, 0, 50)
	matchInfoContainer.Position = UDim2.new(0.5, -150, 0, 10)
	matchInfoContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	matchInfoContainer.BackgroundTransparency = 0.4
	matchInfoContainer.BorderSizePixel = 0
	matchInfoContainer.Parent = parent
	elements.matchInfo = matchInfoContainer

	local matchCorner = Instance.new("UICorner")
	matchCorner.CornerRadius = UDim.new(0, 8)
	matchCorner.Parent = matchInfoContainer

	-- Match timer
	local matchTimer = Instance.new("TextLabel")
	matchTimer.Name = "MatchTimer"
	matchTimer.Size = UDim2.new(1, 0, 0.5, 0)
	matchTimer.Position = UDim2.new(0, 0, 0, 5)
	matchTimer.BackgroundTransparency = 1
	matchTimer.Text = "05:00"
	matchTimer.TextColor3 = Color3.fromRGB(255, 255, 255)
	matchTimer.Font = Enum.Font.GothamBold
	matchTimer.TextSize = 18
	matchTimer.Parent = matchInfoContainer
	elements.matchTimer = matchTimer

	-- Player count
	local playerCount = Instance.new("TextLabel")
	playerCount.Name = "PlayerCount"
	playerCount.Size = UDim2.new(1, 0, 0.5, 0)
	playerCount.Position = UDim2.new(0, 0, 0.5, -5)
	playerCount.BackgroundTransparency = 1
	playerCount.Text = "16/32 Players"
	playerCount.TextColor3 = Color3.fromRGB(200, 200, 200)
	playerCount.Font = Enum.Font.Gotham
	playerCount.TextSize = 12
	playerCount.Parent = matchInfoContainer
	elements.playerCount = playerCount
end

-- Create status effects
function InGameHUD:CreateStatusEffects(parent)
	-- Status effects container (Right side of screen)
	local statusContainer = Instance.new("Frame")
	statusContainer.Name = "StatusEffectsContainer"
	statusContainer.Size = UDim2.new(0, 60, 0, 300)
	statusContainer.Position = UDim2.new(1, -80, 0.5, -150)
	statusContainer.BackgroundTransparency = 1
	statusContainer.Parent = parent
	elements.statusEffects = statusContainer

	-- UIListLayout for status effects
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = statusContainer
end

-- Update health
function InGameHUD:UpdateHealth(health, maxHealth)
	if not elements.healthBar or not elements.healthText then return end

	local healthPercent = math.clamp(health / maxHealth, 0, 1)

	-- Tween health bar
	local tween = TweenService:Create(elements.healthBar,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		{Size = UDim2.new(healthPercent, 0, 1, 0)}
	)
	tween:Play()

	-- Update text
	elements.healthText.Text = tostring(math.floor(health))

	-- Change color based on health
	if healthPercent <= 0.25 then
		elements.healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	elseif healthPercent <= 0.5 then
		elements.healthBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	else
		elements.healthBar.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	end
end

-- Update armor
function InGameHUD:UpdateArmor(armor, maxArmor)
	if not elements.armorBar or not elements.armorText then return end

	local armorPercent = math.clamp(armor / maxArmor, 0, 1)

	-- Tween armor bar
	local tween = TweenService:Create(elements.armorBar,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		{Size = UDim2.new(armorPercent, 0, 1, 0)}
	)
	tween:Play()

	-- Update text
	elements.armorText.Text = tostring(math.floor(armor))
end

-- Update ammo display
function InGameHUD:UpdateAmmo(current, reserve, weaponName)
	if elements.currentAmmo then
		elements.currentAmmo.Text = tostring(current or 0)

		-- Warning color when low ammo
		if current and current <= 5 then
			elements.currentAmmo.TextColor3 = Color3.fromRGB(255, 100, 100)
		else
			elements.currentAmmo.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	if elements.reserveAmmo then
		elements.reserveAmmo.Text = tostring(reserve or 0)
	end

	if elements.weaponName and weaponName then
		elements.weaponName.Text = weaponName:upper()
	end
end

-- Show/hide crosshair
function InGameHUD:SetCrosshairVisible(visible)
	if elements.crosshair then
		elements.crosshair.Visible = visible
	end
end

-- Track weapon equipped/unequipped
function InGameHUD:SetupWeaponTracking()
	local currentWeapon = nil

	local function onWeaponEquipped(tool)
		currentWeapon = tool

		-- Get ammo values from tool
		local ammo = tool:FindFirstChild("Ammo")
		local reserveAmmo = tool:FindFirstChild("ReserveAmmo")

		local currentAmmo = ammo and ammo.Value or 0
		local reserve = reserveAmmo and reserveAmmo.Value or 0

		-- Update display
		self:UpdateAmmo(currentAmmo, reserve, tool.Name)
		self:SetCrosshairVisible(true)

		-- Track ammo changes
		if ammo then
			ammo.Changed:Connect(function()
				local reserve = reserveAmmo and reserveAmmo.Value or 0
				self:UpdateAmmo(ammo.Value, reserve, tool.Name)
			end)
		end

		if reserveAmmo then
			reserveAmmo.Changed:Connect(function()
				local current = ammo and ammo.Value or 0
				self:UpdateAmmo(current, reserveAmmo.Value, tool.Name)
			end)
		end
	end

	local function onWeaponUnequipped()
		currentWeapon = nil
		self:UpdateAmmo(0, 0, "")
		self:SetCrosshairVisible(false)
	end

	-- Track character tool changes
	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				onWeaponEquipped(child)
			end
		end)

		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child == currentWeapon then
				onWeaponUnequipped()
			end
		end)
	end)

	-- If character already exists
	if player.Character then
		player.Character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				onWeaponEquipped(child)
			end
		end)

		player.Character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child == currentWeapon then
				onWeaponUnequipped()
			end
		end)

		-- Check for existing equipped tool
		for _, child in pairs(player.Character:GetChildren()) do
			if child:IsA("Tool") then
				onWeaponEquipped(child)
				break
			end
		end
	end
end

-- Add killfeed entry
function InGameHUD:AddKillFeedEntry(killerName, victimName, weaponName, isHeadshot)
	if not elements.killFeed then return end

	local entry = Instance.new("Frame")
	entry.Name = "KillEntry"
	entry.Size = UDim2.new(1, 0, 0, 30)
	entry.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	entry.BackgroundTransparency = 0.3
	entry.BorderSizePixel = 0
	entry.Parent = elements.killFeed

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 4)
	entryCorner.Parent = entry

	-- Killer name
	local killer = Instance.new("TextLabel")
	killer.Name = "Killer"
	killer.Size = UDim2.new(0.4, 0, 1, 0)
	killer.Position = UDim2.new(0, 5, 0, 0)
	killer.BackgroundTransparency = 1
	killer.Text = killerName
	killer.TextColor3 = Color3.fromRGB(255, 100, 100)
	killer.Font = Enum.Font.GothamBold
	killer.TextSize = 12
	killer.TextXAlignment = Enum.TextXAlignment.Right
	killer.Parent = entry

	-- Weapon icon/text
	local weapon = Instance.new("TextLabel")
	weapon.Name = "Weapon"
	weapon.Size = UDim2.new(0.2, 0, 1, 0)
	weapon.Position = UDim2.new(0.4, 0, 0, 0)
	weapon.BackgroundTransparency = 1
	weapon.Text = isHeadshot and "☠" or "✕"
	weapon.TextColor3 = Color3.fromRGB(220, 220, 220)
	weapon.Font = Enum.Font.GothamBold
	weapon.TextSize = 14
	weapon.Parent = entry

	-- Victim name
	local victim = Instance.new("TextLabel")
	victim.Name = "Victim"
	victim.Size = UDim2.new(0.4, -5, 1, 0)
	victim.Position = UDim2.new(0.6, 0, 0, 0)
	victim.BackgroundTransparency = 1
	victim.Text = victimName
	victim.TextColor3 = Color3.fromRGB(200, 200, 200)
	victim.Font = Enum.Font.Gotham
	victim.TextSize = 12
	victim.TextXAlignment = Enum.TextXAlignment.Left
	victim.Parent = entry

	-- Fade out and remove after 5 seconds
	delay(5, function()
		local fadeTween = TweenService:Create(entry,
			TweenInfo.new(0.5, Enum.EasingStyle.Linear),
			{BackgroundTransparency = 1}
		)
		fadeTween:Play()

		for _, child in pairs(entry:GetChildren()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child,
					TweenInfo.new(0.5, Enum.EasingStyle.Linear),
					{TextTransparency = 1}
				):Play()
			end
		end

		fadeTween.Completed:Connect(function()
			entry:Destroy()
		end)
	end)
end

-- Update match timer
function InGameHUD:UpdateMatchTimer(timeRemaining)
	if not elements.matchTimer then return end

	local minutes = math.floor(timeRemaining / 60)
	local seconds = timeRemaining % 60
	elements.matchTimer.Text = string.format("%02d:%02d", minutes, seconds)
end

-- Update match score
function InGameHUD:UpdateMatchScore(team1Score, team2Score)
	if not elements.matchScore then return end
	elements.matchScore.Text = string.format("KFC: %d | FBI: %d", team1Score, team2Score)
end

-- Update gamemode name
function InGameHUD:UpdateGamemode(gamemodeName)
	if not elements.gamemodeName then return end
	elements.gamemodeName.Text = gamemodeName:upper()
end

-- Update player count
function InGameHUD:UpdatePlayerCount(current, max)
	if not elements.playerCount then return end
	elements.playerCount.Text = string.format("%d/%d Players", current, max)
end

-- Show HUD
function InGameHUD:Show()
	if hudScreenGui then
		hudScreenGui.Enabled = true
	end
end

-- Hide HUD
function InGameHUD:Hide()
	if hudScreenGui then
		hudScreenGui.Enabled = false
	end
end

-- Initialize
function InGameHUD:Initialize()
	if isInitialized then return end

	self:CreateHUD()

	-- Connect to character spawn
	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Update health when changed
		humanoid.HealthChanged:Connect(function(health)
			self:UpdateHealth(health, humanoid.MaxHealth)
		end)

		-- Initial health update
		self:UpdateHealth(humanoid.Health, humanoid.MaxHealth)

		-- Track armor attribute changes
		player:GetAttributeChangedSignal("Armor"):Connect(function()
			local armor = player:GetAttribute("Armor") or 0
			self:UpdateArmor(armor, 100)
		end)

		-- Initial armor update
		local armor = player:GetAttribute("Armor") or 0
		self:UpdateArmor(armor, 100)

		-- DON'T auto-show HUD here - wait for deployment event
		-- HUD will be shown by DeploymentSuccessful event
	end

	if player.Character then
		onCharacterAdded(player.Character)
	end

	player.CharacterAdded:Connect(onCharacterAdded)

	-- Setup weapon tracking
	self:SetupWeaponTracking()

	-- Connect remote events for HUD updates
	-- Show HUD on deployment success, hide on lobby return
	local deploySuccessEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("DeploymentSuccessful")
	if deploySuccessEvent then
		deploySuccessEvent.OnClientEvent:Connect(function()
			self:Show()
		end)
	end

	local returnLobbyEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("ReturnToLobby")
	if returnLobbyEvent then
		returnLobbyEvent.OnClientEvent:Connect(function()
			self:Hide()
		end)
	end
	local killFeedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("KillFeedUpdate")
	if killFeedEvent then
		killFeedEvent.OnClientEvent:Connect(function(data)
			self:AddKillFeedEntry(data.Killer, data.Victim, data.Weapon, data.IsHeadshot)
		end)
	end

	local matchUpdateEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("MatchUpdate")
	if matchUpdateEvent then
		matchUpdateEvent.OnClientEvent:Connect(function(data)
			if data.Time then
				self:UpdateMatchTimer(data.Time)
			end
			if data.Team1Score and data.Team2Score then
				self:UpdateMatchScore(data.Team1Score, data.Team2Score)
			end
			if data.Gamemode then
				self:UpdateGamemode(data.Gamemode)
			end
		end)
	end

	-- Update player count periodically
	spawn(function()
		while true do
			wait(5)
			local playerCount = #Players:GetPlayers()
			self:UpdatePlayerCount(playerCount, 32)
		end
	end)

	isInitialized = true
	print("✓ InGameHUD initialized")
end

-- Initialize on script load
InGameHUD:Initialize()

return InGameHUD