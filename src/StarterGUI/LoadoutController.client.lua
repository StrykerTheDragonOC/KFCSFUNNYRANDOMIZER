--[[
	Loadout Controller (Client)
	Populates and manages the LoadoutSection in the main menu
	No longer creates overlay - uses pre-built UI in StarterGui
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local SaveLoadoutEvent = RemoteEvents:FindFirstChild("SaveLoadout") or Instance.new("RemoteEvent", RemoteEvents)
SaveLoadoutEvent.Name = "SaveLoadout"
local RequestLoadoutEvent = RemoteEvents:FindFirstChild("RequestLoadout") or Instance.new("RemoteEvent", RemoteEvents)
RequestLoadoutEvent.Name = "RequestLoadout"
local LoadoutUpdatedEvent = RemoteEvents:FindFirstChild("LoadoutUpdated") or Instance.new("RemoteEvent", RemoteEvents)
LoadoutUpdatedEvent.Name = "LoadoutUpdated"

local LoadoutController = {}

-- Current loadout state
local currentLoadout = {
	Primary = {Weapon = "G36", Attachments = {}, AmmoType = "Standard", Skin = nil},
	Secondary = {Weapon = "M9", Attachments = {}, AmmoType = "Standard", Skin = nil},
	Melee = {Weapon = "PocketKnife", Skin = nil},
	Grenade = {Weapon = "M67", Skin = nil},
	Special = {Weapon = "", Skin = nil}, -- Empty by default
	Perks = {Slot1 = "double_jump", Slot2 = "", Slot3 = ""} -- Only double jump free
}

local currentCategory = "Primary"
local selectedWeapon = nil
local isAdmin = false

-- Check if player is admin
function LoadoutController:CheckAdminStatus()
	-- Check using RemoteFunction
	local IsPlayerAdminFunction = RemoteEvents:FindFirstChild("IsPlayerAdmin")
	if IsPlayerAdminFunction then
		local success, result = pcall(function()
			return IsPlayerAdminFunction:InvokeServer()
		end)
		
		if success then
			isAdmin = result
			if isAdmin then
				print("✓ Admin status: TRUE - All weapons unlocked!")
			end
		end
	end
	
	return isAdmin
end

function LoadoutController:Initialize()
	-- Wait for menu to exist
	local mainMenu = playerGui:WaitForChild("FPSMainMenu", 10)
	if not mainMenu then
		warn("FPSMainMenu not found - LoadoutController cannot initialize")
		return
	end

	-- Find LoadoutSection
	local contentArea = mainMenu.MainContainer:FindFirstChild("ContentArea")
	if not contentArea then
		warn("ContentArea not found in menu")
		return
	end

	local loadoutSection = contentArea:WaitForChild("LoadoutSection", 5)
	if not loadoutSection then
		warn("LoadoutSection not found in menu - please create it in Studio")
		return
	end

	-- Check admin status
	self:CheckAdminStatus()

	-- Request loadout from server
	RequestLoadoutEvent:FireServer()

	-- Listen for loadout updates
	LoadoutUpdatedEvent.OnClientEvent:Connect(function(success, message, loadoutData)
		if success and loadoutData then
			currentLoadout = loadoutData
			print("✓ Loadout updated:", message)
			self:RefreshLoadoutUI(loadoutSection)
		end
	end)

	-- Connect category tabs
	self:ConnectCategoryTabs(loadoutSection)

	-- Populate initial weapons
	self:PopulateWeaponGrid(loadoutSection, currentCategory)

	print("✓ LoadoutController initialized (using menu section)")
end

function LoadoutController:ConnectCategoryTabs(loadoutSection)
	local tabsContainer = loadoutSection:FindFirstChild("CategoryTabs")
	if not tabsContainer then return end

	local categories = {"Primary", "Secondary", "Melee", "Grenade", "Perks", "Special"}
	for _, category in ipairs(categories) do
		local tab = tabsContainer:FindFirstChild(category .. "Tab")
		if tab and tab:IsA("TextButton") then
			tab.MouseButton1Click:Connect(function()
				self:SwitchCategory(loadoutSection, category)
			end)
		else
			-- Create missing tab (like Special)
			if not tab and tabsContainer:IsA("Frame") then
				tab = Instance.new("TextButton")
				tab.Name = category .. "Tab"
				tab.Size = UDim2.new(0, 100, 0, 40)
				tab.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
				tab.Text = category:upper()
				tab.TextColor3 = Color3.new(1, 1, 1)
				tab.Font = Enum.Font.GothamBold
				tab.TextSize = 14
				tab.BorderSizePixel = 0
				tab.Parent = tabsContainer

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 6)
				corner.Parent = tab

				tab.MouseButton1Click:Connect(function()
					self:SwitchCategory(loadoutSection, category)
				end)

				print("✓ Created", category, "tab")
			end
		end
	end
end

function LoadoutController:SwitchCategory(loadoutSection, category)
	currentCategory = category
	selectedWeapon = nil -- CLEAR selected weapon when switching categories

	-- Update tab visuals
	local tabsContainer = loadoutSection:FindFirstChild("CategoryTabs")
	if tabsContainer then
		for _, tab in ipairs(tabsContainer:GetChildren()) do
			if tab:IsA("TextButton") then
				if tab.Name == category .. "Tab" then
					tab.BackgroundColor3 = Color3.fromRGB(50, 200, 255)
				else
					tab.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
				end
			end
		end
	end

	-- Clear attachment panel title when switching
	local attachmentPanel = loadoutSection:FindFirstChild("AttachmentPanel")
	if attachmentPanel then
		local title = attachmentPanel:FindFirstChild("SelectedWeaponTitle")
		if title then
			title.Text = "SELECT A " .. category:upper()
		end
	end

	-- Display current loadout for this category
	self:DisplayCurrentLoadout(loadoutSection, category)

	-- Populate weapons for this category
	self:PopulateWeaponGrid(loadoutSection, category)

	print("Switched to category:", category)
end

function LoadoutController:PopulateWeaponGrid(loadoutSection, category)
	local weaponGrid = loadoutSection:FindFirstChild("WeaponGrid")
	if not weaponGrid then return end

	local scrollFrame = weaponGrid:FindFirstChild("WeaponScrollFrame")
	if not scrollFrame then return end

	local template = weaponGrid:FindFirstChild("WeaponTemplate")
	if not template then return end

	-- Clear existing weapons (except template)
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if not child:IsA("UIGridLayout") and child.Name ~= "WeaponTemplate" then
			child:Destroy()
		end
	end

	-- Handle special categories differently
	if category == "Perks" then
		self:PopulatePerksGrid(loadoutSection, scrollFrame, template)
		return
	elseif category == "Special" then
		-- Special weapons use "Extra" category in WeaponConfig
		self:PopulateSpecialGrid(loadoutSection, scrollFrame, template)
		return
	end

	-- Get weapons for this category
	local allWeapons = WeaponConfig:GetAllConfigs()
	local categoryWeapons = {}

	for weaponName, config in pairs(allWeapons) do
		if config.Category == category then
			table.insert(categoryWeapons, {Name = weaponName, Config = config})
		end
	end

	-- Create weapon cards
	for _, weaponData in ipairs(categoryWeapons) do
		local weaponCard = template:Clone()
		weaponCard.Name = weaponData.Name
		weaponCard.Visible = true
		weaponCard.Parent = scrollFrame

		-- Set weapon name
		local nameLabel = weaponCard:FindFirstChild("WeaponName")
		if nameLabel then
			nameLabel.Text = weaponData.Name:upper()
		end

		-- Create weapon viewport preview
		local viewport = weaponCard:FindFirstChild("WeaponViewport")
		if viewport and viewport:IsA("ViewportFrame") and _G.WeaponPreviewViewport then
			_G.WeaponPreviewViewport:CreateWeaponPreview(viewport, weaponData.Name)
		elseif not viewport then
			-- Create viewport if it doesn't exist
			viewport = Instance.new("ViewportFrame")
			viewport.Name = "WeaponViewport"
			viewport.Size = UDim2.new(1, 0, 0.7, 0)
			viewport.Position = UDim2.new(0, 0, 0, 0)
			viewport.BackgroundTransparency = 1
			viewport.Parent = weaponCard

			if _G.WeaponPreviewViewport then
				_G.WeaponPreviewViewport:CreateWeaponPreview(viewport, weaponData.Name)
			end
		end

		-- Check if locked (admins bypass all locks)
		local isLocked = false
		
		if not isAdmin then
			-- Check unlock level
			if weaponData.Config.UnlockLevel and weaponData.Config.UnlockLevel > 0 then
				-- TODO: Check player level from DataStore
				-- For now, lock weapons with UnlockLevel > 0
				isLocked = true
			end
		end
		
		local lockIcon = weaponCard:FindFirstChild("LockIcon")
		if lockIcon then
			lockIcon.Visible = isLocked
		end
		
		-- Show admin badge if admin
		if isAdmin and not lockIcon then
			local adminBadge = Instance.new("TextLabel")
			adminBadge.Name = "AdminBadge"
			adminBadge.Size = UDim2.new(0, 60, 0, 20)
			adminBadge.Position = UDim2.new(1, -65, 0, 5)
			adminBadge.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			adminBadge.Text = "ADMIN"
			adminBadge.TextColor3 = Color3.fromRGB(0, 0, 0)
			adminBadge.Font = Enum.Font.GothamBold
			adminBadge.TextSize = 10
			adminBadge.Parent = weaponCard
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = adminBadge
		end

		-- Make clickable if not a template
		local button = weaponCard:FindFirstChildOfClass("TextButton")
		if not button then
			-- Wrap in button behavior
			button = Instance.new("TextButton")
			button.Size = UDim2.new(1, 0, 1, 0)
			button.BackgroundTransparency = 1
			button.Text = ""
			button.Parent = weaponCard
		end

		button.MouseButton1Click:Connect(function()
			-- Auto-equip weapon when selected (no separate equip button needed)
			self:SelectWeapon(loadoutSection, weaponData.Name, category, true)
		end)
	end

	print("✓ Populated", #categoryWeapons, "weapons for", category)
end

function LoadoutController:PopulatePerksGrid(loadoutSection, scrollFrame, template)
	-- Require PerkSystem to get available perks
	local PerkSystem = require(ReplicatedStorage.FPSSystem.Modules.PerkSystem)
	local availablePerks = PerkSystem:GetAvailablePerks()

	local perkCount = 0

	-- Display all perks from all categories
	for categoryName, perks in pairs(availablePerks) do
		for _, perk in ipairs(perks) do
			perkCount = perkCount + 1

			local perkCard = template:Clone()
			perkCard.Name = perk.id
			perkCard.Visible = true
			perkCard.Parent = scrollFrame

			-- Set perk name
			local nameLabel = perkCard:FindFirstChild("WeaponName")
			if nameLabel then
				nameLabel.Text = perk.displayName:upper()
			end

			-- No viewport for perks - add description text instead
			local viewport = perkCard:FindFirstChild("WeaponViewport")
			if viewport then
				viewport.Visible = false

				-- Create description label
				local descLabel = Instance.new("TextLabel")
				descLabel.Name = "PerkDescription"
				descLabel.Size = UDim2.new(1, -10, 0.6, 0)
				descLabel.Position = UDim2.new(0, 5, 0, 5)
				descLabel.BackgroundTransparency = 1
				descLabel.Text = perk.description
				descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				descLabel.TextSize = 12
				descLabel.Font = Enum.Font.Gotham
				descLabel.TextWrapped = true
				descLabel.TextYAlignment = Enum.TextYAlignment.Top
				descLabel.Parent = perkCard
			end

			-- Show perk info (cooldown, type, etc)
			local infoLabel = Instance.new("TextLabel")
			infoLabel.Name = "PerkInfo"
			infoLabel.Size = UDim2.new(1, -10, 0, 20)
			infoLabel.Position = UDim2.new(0, 5, 0.7, 0)
			infoLabel.BackgroundTransparency = 1
			infoLabel.Text = string.format("Lvl %d | %s", perk.level, perk.type:upper())
			infoLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
			infoLabel.TextSize = 11
			infoLabel.Font = Enum.Font.GothamBold
			infoLabel.TextXAlignment = Enum.TextXAlignment.Left
			infoLabel.Parent = perkCard

			-- Check if unlocked (admins bypass)
			local isLocked = false
			if not isAdmin then
				-- For now, all perks are locked unless admin
				-- TODO: Check player level and unlocked perks from DataStore
				isLocked = true
			end

			local lockIcon = perkCard:FindFirstChild("LockIcon")
			if lockIcon then
				lockIcon.Visible = isLocked
			end

			-- Make clickable
			local button = perkCard:FindFirstChildOfClass("TextButton")
			if not button then
				button = Instance.new("TextButton")
				button.Size = UDim2.new(1, 0, 1, 0)
				button.BackgroundTransparency = 1
				button.Text = ""
				button.Parent = perkCard
			end

			button.MouseButton1Click:Connect(function()
				-- Try to equip perk (or show locked message)
				if isAdmin or PerkSystem:IsPerkUnlocked(perk.id) then
					PerkSystem:EquipPerk(perk.id)
					print("✓ Equipped perk:", perk.displayName)
				else
					print("✗ Perk locked! Requires level", perk.level)
				end
			end)
		end
	end

	print("✓ Populated", perkCount, "perks")
end

function LoadoutController:PopulateSpecialGrid(loadoutSection, scrollFrame, template)
	-- Get special weapons (Extra category)
	local allWeapons = WeaponConfig:GetAllConfigs()
	local specialWeapons = {}

	for weaponName, config in pairs(allWeapons) do
		-- Check for both "Special" and "Extra" categories
		if config.Category == "Special" or config.Category == "Extra" then
			table.insert(specialWeapons, {Name = weaponName, Config = config})
		end
	end

	-- Create weapon cards for special weapons
	for _, weaponData in ipairs(specialWeapons) do
		local weaponCard = template:Clone()
		weaponCard.Name = weaponData.Name
		weaponCard.Visible = true
		weaponCard.Parent = scrollFrame

		-- Set weapon name
		local nameLabel = weaponCard:FindFirstChild("WeaponName")
		if nameLabel then
			nameLabel.Text = weaponData.Name:upper()
		end

		-- Create weapon viewport preview
		local viewport = weaponCard:FindFirstChild("WeaponViewport")
		if viewport and viewport:IsA("ViewportFrame") and _G.WeaponPreviewViewport then
			_G.WeaponPreviewViewport:CreateWeaponPreview(viewport, weaponData.Name)
		end

		-- Check if locked
		local isLocked = false
		if not isAdmin then
			if weaponData.Config.UnlockLevel and weaponData.Config.UnlockLevel > 0 then
				isLocked = true
			end
		end

		local lockIcon = weaponCard:FindFirstChild("LockIcon")
		if lockIcon then
			lockIcon.Visible = isLocked
		end

		-- Make clickable
		local button = weaponCard:FindFirstChildOfClass("TextButton")
		if not button then
			button = Instance.new("TextButton")
			button.Size = UDim2.new(1, 0, 1, 0)
			button.BackgroundTransparency = 1
			button.Text = ""
			button.Parent = weaponCard
		end

		button.MouseButton1Click:Connect(function()
			self:SelectWeapon(loadoutSection, weaponData.Name, "Special", false)
		end)
	end

	print("✓ Populated", #specialWeapons, "special weapons")
end

function LoadoutController:SelectWeapon(loadoutSection, weaponName, category, equipNow)
	selectedWeapon = weaponName

	print("Selected weapon:", weaponName, "for", category, equipNow and "(EQUIPPED)" or "(PREVIEW)")

	-- Update selected weapon title
	local attachmentPanel = loadoutSection:FindFirstChild("AttachmentPanel")
	if attachmentPanel then
		local title = attachmentPanel:FindFirstChild("SelectedWeaponTitle")
		if title then
			title.Text = weaponName:upper() .. (equipNow and " ✓" or " (PREVIEW)")
		end

		-- Create/update weapon preview viewport in attachment panel
		local previewViewport = attachmentPanel:FindFirstChild("WeaponPreviewViewport")
		if not previewViewport then
			previewViewport = Instance.new("ViewportFrame")
			previewViewport.Name = "WeaponPreviewViewport"
			previewViewport.Size = UDim2.new(0.9, 0, 0.3, 0)
			previewViewport.Position = UDim2.new(0.05, 0, 0, 30)
			previewViewport.BackgroundColor3 = Color3.fromRGB(10, 15, 20)
			previewViewport.BorderSizePixel = 0
			previewViewport.Parent = attachmentPanel

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = previewViewport
		end

		-- Clear existing preview and create new one
		if _G.WeaponPreviewViewport then
			_G.WeaponPreviewViewport:ClearViewport(previewViewport)
			local success = _G.WeaponPreviewViewport:CreateWeaponPreview(previewViewport, weaponName)
			
			-- If model not found, display a message
			if not success then
				local noModelLabel = previewViewport:FindFirstChild("NoModelLabel")
				if not noModelLabel then
					noModelLabel = Instance.new("TextLabel")
					noModelLabel.Name = "NoModelLabel"
					noModelLabel.Size = UDim2.new(1, 0, 1, 0)
					noModelLabel.BackgroundTransparency = 1
					noModelLabel.Text = "3D Model Not Available"
					noModelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
					noModelLabel.TextSize = 18
					noModelLabel.Font = Enum.Font.GothamBold
					noModelLabel.Parent = previewViewport
				end
			else
				-- Remove no model label if weapon was found
				local noModelLabel = previewViewport:FindFirstChild("NoModelLabel")
				if noModelLabel then
					noModelLabel:Destroy()
				end
			end
		end

		-- Show weapon stats
		self:DisplayWeaponStats(attachmentPanel, weaponName, category)

		-- No equip button needed - weapons auto-equip when selected
	end

	-- Always equip weapon when selected (auto-update loadout)
	self:EquipWeapon(loadoutSection, weaponName, category)
	
	-- Update hotbar to reflect changes
	self:UpdateHotbar()
end

function LoadoutController:EquipWeapon(loadoutSection, weaponName, category)
	-- Initialize category if it doesn't exist
	if not currentLoadout[category] then
		currentLoadout[category] = {}
	end
	
	currentLoadout[category].Weapon = weaponName

	print("✓ EQUIPPED:", weaponName, "for", category)

	-- Save to server
	SaveLoadoutEvent:FireServer(currentLoadout)

	-- Update current loadout display
	self:DisplayCurrentLoadout(loadoutSection, category)

	-- Update title to show equipped
	local attachmentPanel = loadoutSection:FindFirstChild("AttachmentPanel")
	if attachmentPanel then
		local title = attachmentPanel:FindFirstChild("SelectedWeaponTitle")
		if title then
			title.Text = weaponName:upper() .. " ✓"
		end

		local equipButton = attachmentPanel:FindFirstChild("EquipButton")
		if equipButton then
			equipButton.Visible = false
		end
	end
end

function LoadoutController:DisplayWeaponStats(attachmentPanel, weaponName, category)
	-- Get weapon config
	local allWeapons = WeaponConfig:GetAllConfigs()
	local weaponConfig = allWeapons[weaponName]
	if not weaponConfig then return end

	-- Find or create stats container
	local statsContainer = attachmentPanel:FindFirstChild("WeaponStatsContainer")
	if not statsContainer then
		statsContainer = Instance.new("ScrollingFrame")
		statsContainer.Name = "WeaponStatsContainer"
		statsContainer.Size = UDim2.new(1, -20, 0, 200)
		statsContainer.Position = UDim2.new(0, 10, 0.3, 40) -- Position below viewport
		statsContainer.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
		statsContainer.BorderSizePixel = 0
		statsContainer.ScrollBarThickness = 6
		statsContainer.Parent = attachmentPanel

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = statsContainer

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 5)
		listLayout.Parent = statsContainer
	end

	-- Clear existing stats
	for _, child in ipairs(statsContainer:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Display relevant stats based on category
	local stats = {}
	if category == "Primary" or category == "Secondary" then
		stats = {
			{Name = "Damage", Value = weaponConfig.Damage or "N/A"},
			{Name = "Fire Rate", Value = weaponConfig.FireRate or "N/A"},
			{Name = "Range", Value = weaponConfig.MaxRange or "N/A"},
			{Name = "Magazine Size", Value = weaponConfig.MagazineSize or "N/A"},
			{Name = "Reload Time", Value = weaponConfig.ReloadTime or "N/A"},
			{Name = "Fire Mode", Value = weaponConfig.FireMode or "N/A"}
		}
	elseif category == "Melee" then
		stats = {
			{Name = "Damage", Value = weaponConfig.Damage or "N/A"},
			{Name = "Range", Value = weaponConfig.Range or "N/A"},
			{Name = "Swing Speed", Value = weaponConfig.SwingSpeed or "N/A"}
		}
	elseif category == "Grenade" then
		stats = {
			{Name = "Damage", Value = weaponConfig.Damage or "N/A"},
			{Name = "Blast Radius", Value = weaponConfig.BlastRadius or "N/A"},
			{Name = "Fuse Time", Value = weaponConfig.FuseTime or "N/A"}
		}
	end

	-- Create stat labels
	for _, stat in ipairs(stats) do
		local statLabel = Instance.new("TextLabel")
		statLabel.Size = UDim2.new(1, 0, 0, 25)
		statLabel.BackgroundTransparency = 1
		statLabel.Text = stat.Name .. ": " .. tostring(stat.Value)
		statLabel.TextColor3 = Color3.new(1, 1, 1)
		statLabel.Font = Enum.Font.Gotham
		statLabel.TextSize = 14
		statLabel.TextXAlignment = Enum.TextXAlignment.Left
		statLabel.Parent = statsContainer
	end

	statsContainer.CanvasSize = UDim2.new(0, 0, 0, statsContainer.UIListLayout.AbsoluteContentSize.Y)
end

function LoadoutController:DisplayCurrentLoadout(loadoutSection, category)
	-- Find or create current loadout display
	local currentLoadoutDisplay = loadoutSection:FindFirstChild("CurrentLoadoutDisplay")
	if not currentLoadoutDisplay then
		currentLoadoutDisplay = Instance.new("Frame")
		currentLoadoutDisplay.Name = "CurrentLoadoutDisplay"
		-- Fixed size for 1920x1080 display - positioned on left side
		currentLoadoutDisplay.Size = UDim2.fromOffset(280, 350)
		currentLoadoutDisplay.Position = UDim2.fromOffset(15, 120)
		currentLoadoutDisplay.AnchorPoint = Vector2.new(0, 0)
		currentLoadoutDisplay.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
		currentLoadoutDisplay.BackgroundTransparency = 0.2
		currentLoadoutDisplay.BorderSizePixel = 0
		currentLoadoutDisplay.ZIndex = 5
		currentLoadoutDisplay.Parent = loadoutSection

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = currentLoadoutDisplay

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, 0, 0, 40)
		title.BackgroundTransparency = 1
		title.Text = "CURRENT LOADOUT"
		title.TextColor3 = Color3.fromRGB(100, 200, 255)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 16
		title.Parent = currentLoadoutDisplay

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 5)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = currentLoadoutDisplay
	end

	-- Clear existing items (except title and layout)
	for _, child in ipairs(currentLoadoutDisplay:GetChildren()) do
		if child.Name ~= "Title" and not child:IsA("UIListLayout") and not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	-- Display each category (including Special)
	local categories = {"Primary", "Secondary", "Melee", "Grenade", "Special"}
	for i, cat in ipairs(categories) do
		local itemFrame = Instance.new("Frame")
		itemFrame.Name = cat .. "Item"
		itemFrame.Size = UDim2.new(1, -20, 0, 70)
		itemFrame.BackgroundColor3 = cat == category and Color3.fromRGB(50, 100, 150) or Color3.fromRGB(25, 30, 35)
		itemFrame.BorderSizePixel = 0
		itemFrame.LayoutOrder = i + 1
		itemFrame.Parent = currentLoadoutDisplay

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 6)
		itemCorner.Parent = itemFrame

		local catLabel = Instance.new("TextLabel")
		catLabel.Size = UDim2.new(1, -10, 0, 25)
		catLabel.Position = UDim2.fromOffset(10, 5)
		catLabel.BackgroundTransparency = 1
		catLabel.Text = cat:upper()
		catLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		catLabel.Font = Enum.Font.GothamBold
		catLabel.TextSize = 14
		catLabel.TextXAlignment = Enum.TextXAlignment.Left
		catLabel.Parent = itemFrame

		local weaponLabel = Instance.new("TextLabel")
		weaponLabel.Size = UDim2.new(1, -10, 1, -30)
		weaponLabel.Position = UDim2.fromOffset(10, 25)
		weaponLabel.BackgroundTransparency = 1
		weaponLabel.Text = currentLoadout[cat].Weapon or "NONE"
		weaponLabel.TextColor3 = Color3.new(1, 1, 1)
		weaponLabel.Font = Enum.Font.GothamBold
		weaponLabel.TextSize = 18
		weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
		weaponLabel.TextYAlignment = Enum.TextYAlignment.Top
		weaponLabel.Parent = itemFrame
	end
end

function LoadoutController:RefreshLoadoutUI(loadoutSection)
	-- Refresh the current category view
	self:PopulateWeaponGrid(loadoutSection, currentCategory)
	
	-- Also refresh the current loadout display
	self:DisplayCurrentLoadout(loadoutSection, currentCategory)
end

-- Get current loadout data (for HotbarController integration)
function LoadoutController:GetCurrentLoadout()
	return currentLoadout
end

-- Update hotbar when loadout changes
function LoadoutController:UpdateHotbar()
	if _G.HotbarController and _G.HotbarController.ScanBackpack then
		_G.HotbarController:ScanBackpack()
	end
end

-- Initialize
LoadoutController:Initialize()

return LoadoutController
