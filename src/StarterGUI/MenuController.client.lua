-- MenuController.client.lua
-- Complete Menu System with Loadout, Settings, Shop, and Leaderboard

local MenuController = {}
local player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Wait for systems
repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local playerGui = player:WaitForChild("PlayerGui")

-- STRICT: Use only the RBXM-provided FPSMainMenu that StarterGui inserts.
-- Do NOT generate or clone a separate menu; if it's missing, warn and abort initialization.
local mainMenu = playerGui:WaitForChild("FPSMainMenu", 5)
if not mainMenu then
    warn("FPSMainMenu ScreenGui not found in PlayerGui. Ensure the RBXM exists in StarterGui.")
    return MenuController
end

local menuFrame = mainMenu and mainMenu:FindFirstChild("MainContainer")

-- Track deployment state
local isDeployed = false
local currentSection = "Deploy" -- Deploy, Loadout, Settings, Shop, Leaderboard

-- Current player loadout
local playerLoadout = {
	Primary = "G36",
	Secondary = "M9",
	Melee = "PocketKnife",
	Grenade = "M67",
	Special = nil
}

local playerSettings = {
	Sensitivity = 0.5,
	FOV = 90,
	RagdollFactor = 1.0
}

-- Initialize event listeners
function MenuController:SetupDeploymentEventListeners()
	-- Listen for deployment success from server
	local deploySuccessEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("DeploymentSuccessful")
	if deploySuccessEvent then
		deploySuccessEvent.OnClientEvent:Connect(function(data)
			print("✓ Deployment successful! Team:", data.Team)
			isDeployed = true
			self:HideMenu()

			-- Show HUD when deployed
			if _G.HUDController then
				_G.HUDController:ShowHUD()
			end
		end)
	else
		warn("DeploymentSuccessful event not found")
	end

	-- Listen for deployment errors
	local deployErrorEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("DeploymentError")
	if deployErrorEvent then
		deployErrorEvent.OnClientEvent:Connect(function(errorMessage)
			warn("Deployment error:", errorMessage)
		end)
	end

	print("✓ Deployment event listeners set up")
end

-- Deploy player to team
function MenuController:DeployPlayer(teamName)
	print("Requesting deployment to team:", teamName)

	-- Request deployment from server
	local deployEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PlayerDeploy")
	if deployEvent then
		deployEvent:FireServer({Team = teamName})
		print("✓ Deployment request sent to server")
	else
		warn("PlayerDeploy event not found")
	end
end

-- Create sidebar navigation buttons
function MenuController:CreateSidebarNavigation()
	if not mainMenu then return end

	local sidebar = mainMenu.MainContainer:FindFirstChild("Sidebar")
	if not sidebar then return end

	-- Clear any existing buttons (except title frame)
	for _, child in pairs(sidebar:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local sections = {"Deploy", "Loadout", "Settings", "Shop", "Leaderboard"}
	local yOffset = 70 -- Start below title

	for _, sectionName in ipairs(sections) do
		local button = Instance.new("TextButton")
		button.Name = sectionName .. "Button"
		button.Size = UDim2.new(1, -20, 0, 50)
		button.Position = UDim2.new(0, 10, 0, yOffset)
		button.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
		button.BorderSizePixel = 0
		button.Text = sectionName
		button.TextColor3 = Color3.fromRGB(200, 200, 200)
		button.TextSize = 18
		button.Font = Enum.Font.GothamBold
		button.AutoButtonColor = false

		-- Add corner radius
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button

		-- Click handler
		button.MouseButton1Click:Connect(function()
			self:ShowSection(sectionName)
		end)

		button.Parent = sidebar
		yOffset = yOffset + 60
	end

	print("✓ Sidebar navigation created")
end

-- Show specific section
function MenuController:ShowSection(sectionName)
	currentSection = sectionName

	-- Update sidebar button highlights
	local sidebar = mainMenu.MainContainer.Sidebar
	for _, child in pairs(sidebar:GetChildren()) do
		if child:IsA("TextButton") then
			if child.Name == sectionName .. "Button" then
				child.BackgroundColor3 = Color3.fromRGB(50, 128, 100)
				child.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				child.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
				child.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		end
	end

	-- Clear content area
	local contentArea = mainMenu.MainContainer.ContentArea
	for _, child in pairs(contentArea:GetChildren()) do
		child.Visible = false
	end

	-- Show appropriate content
	if sectionName == "Deploy" then
		self:ShowDeploySection()
	elseif sectionName == "Loadout" then
		self:ShowLoadoutSection()
	elseif sectionName == "Settings" then
		self:ShowSettingsSection()
	elseif sectionName == "Shop" then
		self:ShowShopSection()
	elseif sectionName == "Leaderboard" then
		self:ShowLeaderboardSection()
	end

	print("Showing section:", sectionName)
end

-- Show Deploy section (default)
function MenuController:ShowDeploySection()
	local contentArea = mainMenu.MainContainer.ContentArea
	local deploySection = contentArea:FindFirstChild("DeploySection")

	if deploySection then
		deploySection.Visible = true
	end
end

-- Show Loadout section
function MenuController:ShowLoadoutSection()
	local contentArea = mainMenu.MainContainer.ContentArea
	local loadoutSection = contentArea:FindFirstChild("LoadoutSection")

	if not loadoutSection then
		loadoutSection = self:CreateLoadoutSection()
	end

	loadoutSection.Visible = true
	self:PopulateLoadoutSection(loadoutSection)
end

-- Create Loadout section
function MenuController:CreateLoadoutSection()
	local contentArea = mainMenu.MainContainer.ContentArea

	-- Check if it already exists
	local existing = contentArea:FindFirstChild("LoadoutSection")
	if existing then
		print("✓ Using existing LoadoutSection from RBXM")
		return existing
	end

	print("⚠ Creating new LoadoutSection")
	local loadoutSection = Instance.new("Frame")
	loadoutSection.Name = "LoadoutSection"
	loadoutSection.Size = UDim2.new(1, 0, 1, 0)
	loadoutSection.Position = UDim2.new(0, 0, 0, 0)
	loadoutSection.BackgroundTransparency = 1
	loadoutSection.Visible = false
	loadoutSection.Parent = contentArea

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "LOADOUT CUSTOMIZATION"
	title.TextColor3 = Color3.fromRGB(50, 200, 255)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = loadoutSection

	-- Weapon categories
	local categories = {"Primary", "Secondary", "Melee", "Grenade", "Special"}
	local yOffset = 100

	for _, category in ipairs(categories) do
		-- Category frame
		local categoryFrame = Instance.new("Frame")
		categoryFrame.Name = category .. "Frame"
		categoryFrame.Size = UDim2.new(1, -40, 0, 120)
		categoryFrame.Position = UDim2.new(0, 20, 0, yOffset)
		categoryFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
		categoryFrame.BorderSizePixel = 0
		categoryFrame.Parent = loadoutSection

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = categoryFrame

		-- Category label
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(0, 150, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = category:upper()
		label.TextColor3 = Color3.fromRGB(50, 200, 255)
		label.TextSize = 20
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = categoryFrame

		-- Weapon scroll frame
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Name = "WeaponList"
		scrollFrame.Size = UDim2.new(1, -170, 1, -10)
		scrollFrame.Position = UDim2.new(0, 160, 0, 5)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.BorderSizePixel = 0
		scrollFrame.ScrollBarThickness = 6
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		scrollFrame.Parent = categoryFrame

		local listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Horizontal
		listLayout.Padding = UDim.new(0, 10)
		listLayout.Parent = scrollFrame

		yOffset = yOffset + 130
	end

	return loadoutSection
end

-- Populate Loadout section with weapons
function MenuController:PopulateLoadoutSection(loadoutSection)
	local allWeapons = WeaponConfig:GetAllConfigs()

	local categorizedWeapons = {
		Primary = {},
		Secondary = {},
		Melee = {},
		Grenade = {},
		Special = {}
	}

	-- Categorize all weapons
	for weaponName, config in pairs(allWeapons) do
		local category = config.Category
		if categorizedWeapons[category] then
			table.insert(categorizedWeapons[category], {Name = weaponName, Config = config})
		end
	end

	-- Populate each category
	for category, weapons in pairs(categorizedWeapons) do
		local categoryFrame = loadoutSection:FindFirstChild(category .. "Frame")
		if categoryFrame then
			local weaponList = categoryFrame:FindFirstChild("WeaponList")
			if weaponList then
				-- Clear existing weapons
				for _, child in pairs(weaponList:GetChildren()) do
					if not child:IsA("UIListLayout") then
						child:Destroy()
					end
				end

				-- Add weapon buttons
				for _, weaponData in ipairs(weapons) do
					local weaponButton = self:CreateWeaponButton(weaponData.Name, weaponData.Config, category)
					weaponButton.Parent = weaponList
				end

				-- Update canvas size
				wait(0.1)
				local listLayout = weaponList:FindFirstChildOfClass("UIListLayout")
				if listLayout then
					weaponList.CanvasSize = UDim2.new(0, listLayout.AbsoluteContentSize.X, 0, 0)
				end
			end
		end
	end

	print("✓ Loadout section populated with weapons")
end

-- Create weapon button
function MenuController:CreateWeaponButton(weaponName, config, category)
	local button = Instance.new("TextButton")
	button.Name = weaponName
	button.Size = UDim2.new(0, 100, 1, -10)
	button.BackgroundColor3 = playerLoadout[category] == weaponName and Color3.fromRGB(50, 128, 100) or Color3.fromRGB(40, 45, 50)
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	-- Weapon icon (placeholder for now)
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, -10, 0.6, 0)
	icon.Position = UDim2.new(0, 5, 0, 5)
	icon.BackgroundColor3 = Color3.fromRGB(60, 65, 70)
	icon.BorderSizePixel = 0
	icon.Image = "" -- Will be set with actual weapon preview
	icon.Parent = button

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 4)
	iconCorner.Parent = icon

	-- Weapon name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0.35, 0)
	nameLabel.Position = UDim2.new(0, 5, 0.65, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = weaponName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = button

	-- Click handler
	button.MouseButton1Click:Connect(function()
		self:SelectWeapon(weaponName, category)
	end)

	return button
end

-- Select weapon for loadout
function MenuController:SelectWeapon(weaponName, category)
	playerLoadout[category] = weaponName
	print("Selected", weaponName, "for", category)

	-- Update UI
	local loadoutSection = mainMenu.MainContainer.ContentArea:FindFirstChild("LoadoutSection")
	if loadoutSection then
		self:PopulateLoadoutSection(loadoutSection)
	end

	-- Automatically update loadout on server
	local loadoutChangedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("LoadoutChanged")
	if loadoutChangedEvent then
		-- Send updated loadout to server
		loadoutChangedEvent:FireServer(playerLoadout)
		print("✓ Loadout auto-updated on server:", category, "=", weaponName)
	else
		warn("LoadoutChanged event not found - loadout not saved to server")
	end
end

-- Show Settings section
function MenuController:ShowSettingsSection()
	local contentArea = mainMenu.MainContainer.ContentArea
	local settingsSection = contentArea:FindFirstChild("SettingsSection")

	if not settingsSection then
		settingsSection = self:CreateSettingsSection()
	end

	settingsSection.Visible = true
end

-- Create Settings section
function MenuController:CreateSettingsSection()
	local contentArea = mainMenu.MainContainer.ContentArea

	-- Check if it already exists
	local existing = contentArea:FindFirstChild("SettingsSection")
	if existing then
		print("✓ Using existing SettingsSection from RBXM")
		return existing
	end

	print("⚠ Creating new SettingsSection")
	local settingsSection = Instance.new("Frame")
	settingsSection.Name = "SettingsSection"
	settingsSection.Size = UDim2.new(1, 0, 1, 0)
	settingsSection.Position = UDim2.new(0, 0, 0, 0)
	settingsSection.BackgroundTransparency = 1
	settingsSection.Visible = false
	settingsSection.Parent = contentArea

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "SETTINGS"
	title.TextColor3 = Color3.fromRGB(50, 200, 255)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = settingsSection

	-- Settings
	local settings = {
		{Name = "Sensitivity", Min = 0.1, Max = 2.0, Default = 0.5},
		{Name = "FOV", Min = 70, Max = 120, Default = 90},
		{Name = "Ragdoll Factor", Min = 0.0, Max = 3.0, Default = 1.0}
	}

	local yOffset = 100

	for _, setting in ipairs(settings) do
		-- Setting frame
		local settingFrame = Instance.new("Frame")
		settingFrame.Name = setting.Name .. "Frame"
		settingFrame.Size = UDim2.new(1, -40, 0, 80)
		settingFrame.Position = UDim2.new(0, 20, 0, yOffset)
		settingFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
		settingFrame.BorderSizePixel = 0
		settingFrame.Parent = settingsSection

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = settingFrame

		-- Setting label
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(0.3, 0, 0, 30)
		label.Position = UDim2.new(0, 20, 0, 10)
		label.BackgroundTransparency = 1
		label.Text = setting.Name:upper()
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 18
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = settingFrame

		-- Value label
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "ValueLabel"
		valueLabel.Size = UDim2.new(0.2, 0, 0, 30)
		valueLabel.Position = UDim2.new(0.75, 0, 0, 10)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(setting.Default)
		valueLabel.TextColor3 = Color3.fromRGB(50, 200, 255)
		valueLabel.TextSize = 18
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = settingFrame

		-- Slider (simplified for now)
		local sliderBG = Instance.new("Frame")
		sliderBG.Name = "SliderBG"
		sliderBG.Size = UDim2.new(0.8, -40, 0, 10)
		sliderBG.Position = UDim2.new(0.1, 20, 0, 50)
		sliderBG.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
		sliderBG.BorderSizePixel = 0
		sliderBG.Parent = settingFrame

		local sliderCorner = Instance.new("UICorner")
		sliderCorner.CornerRadius = UDim.new(1, 0)
		sliderCorner.Parent = sliderBG

		-- TODO: Implement functional slider

		yOffset = yOffset + 90
	end

	return settingsSection
end

-- Show Shop section
function MenuController:ShowShopSection()
	local contentArea = mainMenu.MainContainer.ContentArea
	local shopSection = contentArea:FindFirstChild("ShopSection")

	if not shopSection then
		shopSection = self:CreateShopSection()
	end

	shopSection.Visible = true
end

-- Create Shop section (placeholder)
function MenuController:CreateShopSection()
	local contentArea = mainMenu.MainContainer.ContentArea

	-- Check if it already exists
	local existing = contentArea:FindFirstChild("ShopSection")
	if existing then
		print("✓ Using existing ShopSection from RBXM")
		return existing
	end

	print("⚠ Creating new ShopSection")
	local shopSection = Instance.new("Frame")
	shopSection.Name = "ShopSection"
	shopSection.Size = UDim2.new(1, 0, 1, 0)
	shopSection.Position = UDim2.new(0, 0, 0, 0)
	shopSection.BackgroundTransparency = 1
	shopSection.Visible = false
	shopSection.Parent = contentArea

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "WEAPON SKINS SHOP"
	title.TextColor3 = Color3.fromRGB(50, 200, 255)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = shopSection

	-- Placeholder message
	local placeholder = Instance.new("TextLabel")
	placeholder.Name = "Placeholder"
	placeholder.Size = UDim2.new(1, -40, 0, 100)
	placeholder.Position = UDim2.new(0, 20, 0.5, -50)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "SHOP COMING SOON\nWeapon skins will be available for purchase"
	placeholder.TextColor3 = Color3.fromRGB(150, 150, 150)
	placeholder.TextSize = 24
	placeholder.Font = Enum.Font.Gotham
	placeholder.TextWrapped = true
	placeholder.Parent = shopSection

	return shopSection
end

-- Show Leaderboard section
function MenuController:ShowLeaderboardSection()
	local contentArea = mainMenu.MainContainer.ContentArea
	local leaderboardSection = contentArea:FindFirstChild("LeaderboardSection")

	if not leaderboardSection then
		leaderboardSection = self:CreateLeaderboardSection()
	end

	leaderboardSection.Visible = true
end

-- Create Leaderboard section
function MenuController:CreateLeaderboardSection()
	local contentArea = mainMenu.MainContainer.ContentArea

	-- Check if it already exists
	local existing = contentArea:FindFirstChild("LeaderboardSection")
	if existing then
		print("✓ Using existing LeaderboardSection from RBXM")
		return existing
	end

	print("⚠ Creating new LeaderboardSection")
	local leaderboardSection = Instance.new("Frame")
	leaderboardSection.Name = "LeaderboardSection"
	leaderboardSection.Size = UDim2.new(1, 0, 1, 0)
	leaderboardSection.Position = UDim2.new(0, 0, 0, 0)
	leaderboardSection.BackgroundTransparency = 1
	leaderboardSection.Visible = false
	leaderboardSection.Parent = contentArea

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "LEADERBOARD"
	title.TextColor3 = Color3.fromRGB(50, 200, 255)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = leaderboardSection

	-- Placeholder for actual leaderboard
	local placeholder = Instance.new("TextLabel")
	placeholder.Name = "Placeholder"
	placeholder.Size = UDim2.new(1, -40, 0, 100)
	placeholder.Position = UDim2.new(0, 20, 0.5, -50)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "TOP PLAYERS\nLeaderboard data will be displayed here"
	placeholder.TextColor3 = Color3.fromRGB(150, 150, 150)
	placeholder.TextSize = 24
	placeholder.Font = Enum.Font.Gotham
	placeholder.TextWrapped = true
	placeholder.Parent = leaderboardSection

	return leaderboardSection
end

-- Show menu
function MenuController:ShowMenu()
	if mainMenu then
		mainMenu.Enabled = true

		-- Lock player input
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true

		-- Lock player in menu
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
			end
		end

		print("Menu shown - MouseBehavior:", UserInputService.MouseBehavior)
	end
end

-- Hide menu
function MenuController:HideMenu()
	if mainMenu then
		mainMenu.Enabled = false

		-- Unlock player input
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false

		-- Unlock player movement
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16 -- Default walkspeed
				humanoid.JumpPower = 50 -- Default jump
			end
		end

		print("Menu hidden - MouseBehavior:", UserInputService.MouseBehavior)
	end
end

-- Setup deploy button
function MenuController:SetupDeployButton()
	if not mainMenu then return end

	-- New structure: MainContainer -> ContentArea -> DeploySection -> DeployButton
	local contentArea = mainMenu.MainContainer:FindFirstChild("ContentArea")
	if not contentArea then
		warn("ContentArea not found")
		return
	end

	local deploySection = contentArea:FindFirstChild("DeploySection")
	if not deploySection then
		warn("DeploySection not found")
		return
	end

	local deployButton = deploySection:FindFirstChild("DeployButton")
	if deployButton and deployButton:IsA("TextButton") then
		deployButton.MouseButton1Click:Connect(function()
			-- Deploy to random team (KFC or FBI)
			local teams = {"KFC", "FBI"}
			local randomTeam = teams[math.random(1, #teams)]
			self:DeployPlayer(randomTeam)
		end)
		print("✓ Deploy button connected")
	else
		warn("DeployButton not found in DeploySection")
	end
end

-- Listen for Space key to deploy
function MenuController:SetupSpaceKeyDeploy()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Space and mainMenu and mainMenu.Enabled then
			-- Deploy to random team
			local teams = {"KFC", "FBI"}
			local randomTeam = teams[math.random(1, #teams)]
			self:DeployPlayer(randomTeam)
		end
	end)
	print("✓ Space key deploy enabled")
end

-- Setup respawn handling
function MenuController:SetupRespawnHandling()
	-- Handle respawns
	player.CharacterAdded:Connect(function(character)
		print("Character respawned - checking deployment state")

		-- Wait for character to fully load
		wait(0.5)

		-- If player is not deployed, show menu again
		if not isDeployed then
			self:ShowMenu()
			print("Showing menu after respawn (not deployed)")
		else
			print("Player is deployed, keeping menu hidden")
		end
	end)

	-- Track when player dies
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				print("Player died")
				-- Don't change deployment state, will be handled by respawn
			end)
		end
	end
end

-- Initialize the controller
function MenuController:Initialize()
	print("MenuController: Initializing...")

	-- Hide default Roblox UI
	local StarterGui = game:GetService("StarterGui")
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)

	-- Setup deployment event listeners (CRITICAL!)
	self:SetupDeploymentEventListeners()

	-- NOTE: Sidebar navigation is now created by MenuUIGenerator.client.lua
	-- We just connect to the existing buttons instead of creating new ones
	-- self:CreateSidebarNavigation()  -- DISABLED - MenuUIGenerator creates buttons

	-- Setup deploy functionality
	self:SetupDeployButton()
	self:SetupSpaceKeyDeploy()

	-- Setup character respawn handling
	self:SetupRespawnHandling()

	-- NOTE: Default section (Deploy) is already shown by MenuUIGenerator
	-- No need to call ShowSection here as MenuUIGenerator handles it
	-- self:ShowSection("Deploy")  -- DISABLED - MenuUIGenerator handles default section

	-- Show menu on start
	self:ShowMenu()

	print("MenuController: Initialization Complete!")
end

-- Initialize
MenuController:Initialize()

return MenuController
