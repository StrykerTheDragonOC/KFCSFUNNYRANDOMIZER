--[[
	Admin Panel Client
	Modern, aesthetically pleasing admin panel with animations
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local adminCommandEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AdminCommand")
local isAdmin = false

-- Check if player is admin
local function checkAdmin()
	-- Game creator is always admin
	if player.UserId == game.CreatorId then
		isAdmin = true
		return true
	end

	-- Could also check via server
	return isAdmin
end

-- Check on startup
checkAdmin()

-- Admin Panel UI
local adminPanel = nil
local selectedPlayer = nil

-- Color scheme - Modern dark theme with accent colors
local COLORS = {
	Background = Color3.fromRGB(20, 20, 25),
	Panel = Color3.fromRGB(30, 30, 35),
	Accent = Color3.fromRGB(99, 102, 241), -- Indigo
	AccentHover = Color3.fromRGB(129, 140, 248),
	Success = Color3.fromRGB(34, 197, 94), -- Green
	Danger = Color3.fromRGB(239, 68, 68), -- Red
	Warning = Color3.fromRGB(251, 191, 36), -- Yellow
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(156, 163, 175),
	Border = Color3.fromRGB(55, 65, 81)
}

-- Create notification
local function createNotification(message, color, duration)
	duration = duration or 3

	local notif = Instance.new("ScreenGui")
	notif.Name = "AdminNotification"
	notif.ResetOnSpawn = false
	notif.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(400, 80)
	frame.Position = UDim2.new(1, 420, 0, 20) -- Start off-screen
	frame.BackgroundColor3 = color or COLORS.Accent
	frame.BorderSizePixel = 0
	frame.Parent = notif

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.Accent
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.fromOffset(20, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = COLORS.Text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = frame

	-- Slide in animation
	frame:TweenPosition(
		UDim2.new(1, -420, 0, 20),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		0.5,
		true
	)

	-- Slide out and destroy
	task.delay(duration, function()
		if frame and frame.Parent then
			frame:TweenPosition(
				UDim2.new(1, 420, 0, 20),
				Enum.EasingDirection.In,
				Enum.EasingStyle.Quad,
				0.3,
				true,
				function()
					notif:Destroy()
				end
			)
		end
	end)
end

-- Create stylish button
local function createButton(parent, text, color, position, size, callback)
	local button = Instance.new("TextButton")
	button.Size = size or UDim2.fromOffset(200, 45)
	button.Position = position
	button.BackgroundColor3 = color or COLORS.Accent
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = color == COLORS.Accent and COLORS.AccentHover or Color3.fromRGB(
				math.min(color.R * 255 + 20, 255),
				math.min(color.G * 255 + 20, 255),
				math.min(color.B * 255 + 20, 255)
			)
		}):Play()
		TweenService:Create(button, TweenInfo.new(0.2), {
			Size = (size or UDim2.fromOffset(200, 45)) + UDim2.fromOffset(5, 2)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = color or COLORS.Accent
		}):Play()
		TweenService:Create(button, TweenInfo.new(0.2), {
			Size = size or UDim2.fromOffset(200, 45)
		}):Play()
	end)

	if callback then
		button.MouseButton1Click:Connect(callback)
	end

	return button
end

-- Create admin panel
local function createAdminPanel()
	if not isAdmin then
		createNotification("You are not an admin!", COLORS.Danger)
		return
	end

	if adminPanel then
		adminPanel:Destroy()
		adminPanel = nil
		return
	end

	adminPanel = Instance.new("ScreenGui")
	adminPanel.Name = "AdminPanel"
	adminPanel.ResetOnSpawn = false
	adminPanel.IgnoreGuiInset = true
	adminPanel.Parent = playerGui

	-- Blur background
	local blur = Instance.new("Frame")
	blur.Size = UDim2.fromScale(1, 1)
	blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	blur.BackgroundTransparency = 0.3
	blur.BorderSizePixel = 0
	blur.Parent = adminPanel

	-- Main panel
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.fromOffset(900, 650)
	mainFrame.Position = UDim2.new(0.5, -450, 0.5, -325)
	mainFrame.BackgroundColor3 = COLORS.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = adminPanel

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = COLORS.Border
	mainStroke.Thickness = 1
	mainStroke.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 70)
	header.BackgroundColor3 = COLORS.Panel
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 16)
	headerCorner.Parent = header

	-- Title with gradient
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -80, 1, 0)
	title.Position = UDim2.fromOffset(30, 0)
	title.BackgroundTransparency = 1
	title.Text = "⚡ ADMIN PANEL"
	title.TextColor3 = COLORS.Text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 28
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.fromOffset(300, 20)
	subtitle.Position = UDim2.fromOffset(30, 45)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Advanced Command Center"
	subtitle.TextColor3 = COLORS.TextSecondary
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 12
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = header

	-- Close button
	createButton(header, "✕", COLORS.Danger, UDim2.new(1, -60, 0, 15), UDim2.fromOffset(45, 45), function()
		adminPanel:Destroy()
		adminPanel = nil
	end)

	-- Content container
	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -40, 1, -90)
	content.Position = UDim2.fromOffset(20, 80)
	content.BackgroundTransparency = 1
	content.Parent = mainFrame

	-- Left panel - Player list
	local leftPanel = Instance.new("Frame")
	leftPanel.Size = UDim2.fromOffset(300, 540)
	leftPanel.Position = UDim2.fromOffset(0, 0)
	leftPanel.BackgroundColor3 = COLORS.Panel
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = content

	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 12)
	leftCorner.Parent = leftPanel

	-- Player list header
	local playerListHeader = Instance.new("TextLabel")
	playerListHeader.Size = UDim2.new(1, 0, 0, 50)
	playerListHeader.BackgroundColor3 = COLORS.Accent
	playerListHeader.BorderSizePixel = 0
	playerListHeader.Text = "👥 PLAYERS ONLINE"
	playerListHeader.TextColor3 = COLORS.Text
	playerListHeader.Font = Enum.Font.GothamBold
	playerListHeader.TextSize = 16
	playerListHeader.Parent = leftPanel

	local headerCorner2 = Instance.new("UICorner")
	headerCorner2.CornerRadius = UDim.new(0, 12)
	headerCorner2.Parent = playerListHeader

	-- Player count badge
	local playerCount = Instance.new("TextLabel")
	playerCount.Size = UDim2.fromOffset(40, 30)
	playerCount.Position = UDim2.new(1, -50, 0, 10)
	playerCount.BackgroundColor3 = COLORS.Background
	playerCount.BorderSizePixel = 0
	playerCount.Text = tostring(#Players:GetPlayers())
	playerCount.TextColor3 = COLORS.Accent
	playerCount.Font = Enum.Font.GothamBold
	playerCount.TextSize = 14
	playerCount.Parent = playerListHeader

	local countCorner = Instance.new("UICorner")
	countCorner.CornerRadius = UDim.new(0, 8)
	countCorner.Parent = playerCount

	-- Player scroll frame
	local playerScroll = Instance.new("ScrollingFrame")
	playerScroll.Size = UDim2.new(1, -10, 1, -60)
	playerScroll.Position = UDim2.fromOffset(5, 55)
	playerScroll.BackgroundTransparency = 1
	playerScroll.BorderSizePixel = 0
	playerScroll.ScrollBarThickness = 6
	playerScroll.ScrollBarImageColor3 = COLORS.Accent
	playerScroll.Parent = leftPanel

	local playerListLayout = Instance.new("UIListLayout")
	playerListLayout.SortOrder = Enum.SortOrder.Name
	playerListLayout.Padding = UDim.new(0, 5)
	playerListLayout.Parent = playerScroll

	-- Right panel - Commands
	local rightPanel = Instance.new("Frame")
	rightPanel.Size = UDim2.fromOffset(540, 540)
	rightPanel.Position = UDim2.fromOffset(320, 0)
	rightPanel.BackgroundColor3 = COLORS.Panel
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = content

	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 12)
	rightCorner.Parent = rightPanel

	-- Commands header
	local commandsHeader = Instance.new("TextLabel")
	commandsHeader.Size = UDim2.new(1, 0, 0, 50)
	commandsHeader.BackgroundColor3 = COLORS.Accent
	commandsHeader.BorderSizePixel = 0
	commandsHeader.Text = "⚙️ COMMANDS"
	commandsHeader.TextColor3 = COLORS.Text
	commandsHeader.Font = Enum.Font.GothamBold
	commandsHeader.TextSize = 16
	commandsHeader.Parent = rightPanel

	local commandsCorner = Instance.new("UICorner")
	commandsCorner.CornerRadius = UDim.new(0, 12)
	commandsCorner.Parent = commandsHeader

	-- Selected player display
	local selectedDisplay = Instance.new("Frame")
	selectedDisplay.Size = UDim2.new(1, -20, 0, 60)
	selectedDisplay.Position = UDim2.fromOffset(10, 60)
	selectedDisplay.BackgroundColor3 = COLORS.Background
	selectedDisplay.BorderSizePixel = 0
	selectedDisplay.Parent = rightPanel

	local selectedCorner = Instance.new("UICorner")
	selectedCorner.CornerRadius = UDim.new(0, 10)
	selectedCorner.Parent = selectedDisplay

	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Size = UDim2.new(1, -20, 1, 0)
	selectedLabel.Position = UDim2.fromOffset(10, 0)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Text = "No player selected"
	selectedLabel.TextColor3 = COLORS.TextSecondary
	selectedLabel.Font = Enum.Font.GothamBold
	selectedLabel.TextSize = 14
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedLabel.Parent = selectedDisplay

	-- Commands container
	local commandsContainer = Instance.new("Frame")
	commandsContainer.Size = UDim2.new(1, -20, 1, -140)
	commandsContainer.Position = UDim2.fromOffset(10, 130)
	commandsContainer.BackgroundTransparency = 1
	commandsContainer.Parent = rightPanel

	-- Command sections
	local yPos = 0

	-- Weapon Commands Section
	local function createSection(title, y)
		local section = Instance.new("TextLabel")
		section.Size = UDim2.new(1, 0, 0, 30)
		section.Position = UDim2.fromOffset(0, y)
		section.BackgroundTransparency = 1
		section.Text = title
		section.TextColor3 = COLORS.Text
		section.Font = Enum.Font.GothamBold
		section.TextSize = 14
		section.TextXAlignment = Enum.TextXAlignment.Left
		section.Parent = commandsContainer
		return y + 35
	end

	yPos = createSection("🔫 WEAPON COMMANDS", yPos)

	-- Give NTW button
	createButton(commandsContainer, "Give NTW-20", COLORS.Warning, UDim2.fromOffset(0, yPos), UDim2.fromOffset(165, 45), function()
		if selectedPlayer then
			adminCommandEvent:FireServer("GiveWeapon", selectedPlayer.Name, "NTW-20")
			createNotification("Gave NTW-20 to " .. selectedPlayer.Name, COLORS.Success)
		else
			createNotification("Please select a player first!", COLORS.Danger)
		end
	end)

	createButton(commandsContainer, "Give All Weapons", COLORS.Accent, UDim2.fromOffset(175, yPos), UDim2.fromOffset(165, 45), function()
		if selectedPlayer then
			adminCommandEvent:FireServer("GiveAllWeapons", selectedPlayer.Name)
			createNotification("Gave all weapons to " .. selectedPlayer.Name, COLORS.Success)
		else
			createNotification("Please select a player first!", COLORS.Danger)
		end
	end)

	createButton(commandsContainer, "Clear Weapons", COLORS.Danger, UDim2.fromOffset(350, yPos), UDim2.fromOffset(165, 45), function()
		if selectedPlayer then
			adminCommandEvent:FireServer("ClearWeapons", selectedPlayer.Name)
			createNotification("Cleared weapons from " .. selectedPlayer.Name, COLORS.Success)
		else
			createNotification("Please select a player first!", COLORS.Danger)
		end
	end)

	yPos = yPos + 60
	yPos = createSection("💊 PLAYER COMMANDS", yPos)

	-- Heal button
	createButton(commandsContainer, "Heal Player", COLORS.Success, UDim2.fromOffset(0, yPos), UDim2.fromOffset(165, 45), function()
		if selectedPlayer then
			adminCommandEvent:FireServer("HealPlayer", selectedPlayer.Name)
			createNotification("Healed " .. selectedPlayer.Name, COLORS.Success)
		else
			createNotification("Please select a player first!", COLORS.Danger)
		end
	end)

	-- Max Armor button
	createButton(commandsContainer, "Give Max Armor", COLORS.Accent, UDim2.fromOffset(175, yPos), UDim2.fromOffset(165, 45), function()
		if selectedPlayer then
			adminCommandEvent:FireServer("GiveMaxArmor", selectedPlayer.Name)
			createNotification("Gave max armor to " .. selectedPlayer.Name, COLORS.Success)
		else
			createNotification("Please select a player first!", COLORS.Danger)
		end
	end)

	-- Teleport to player button
	createButton(commandsContainer, "Teleport To", COLORS.Warning, UDim2.fromOffset(350, yPos), UDim2.fromOffset(165, 45), function()
		if selectedPlayer and selectedPlayer.Character and player.Character then
			local targetPos = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
			local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
			if targetPos and myRoot then
				myRoot.CFrame = targetPos.CFrame + Vector3.new(5, 0, 0)
				createNotification("Teleported to " .. selectedPlayer.Name, COLORS.Success)
			end
		else
			createNotification("Please select a player first!", COLORS.Danger)
		end
	end)

	-- Update player list
	local function updatePlayerList()
		for _, child in pairs(playerScroll:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		playerCount.Text = tostring(#Players:GetPlayers())

		for _, plr in pairs(Players:GetPlayers()) do
			local playerButton = Instance.new("TextButton")
			playerButton.Size = UDim2.fromOffset(280, 50)
			playerButton.BackgroundColor3 = selectedPlayer == plr and COLORS.Accent or COLORS.Background
			playerButton.BorderSizePixel = 0
			playerButton.AutoButtonColor = false
			playerButton.Text = ""
			playerButton.Parent = playerScroll

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 8)
			btnCorner.Parent = playerButton

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -60, 1, 0)
			nameLabel.Position = UDim2.fromOffset(50, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = plr.Name
			nameLabel.TextColor3 = selectedPlayer == plr and COLORS.Text or COLORS.TextSecondary
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 14
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = playerButton

			-- Player thumbnail
			local thumbnail = Instance.new("ImageLabel")
			thumbnail.Size = UDim2.fromOffset(35, 35)
			thumbnail.Position = UDim2.fromOffset(8, 8)
			thumbnail.BackgroundColor3 = COLORS.Panel
			thumbnail.BorderSizePixel = 0
			thumbnail.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			thumbnail.Parent = playerButton

			local thumbCorner = Instance.new("UICorner")
			thumbCorner.CornerRadius = UDim.new(1, 0)
			thumbCorner.Parent = thumbnail

			playerButton.MouseButton1Click:Connect(function()
				selectedPlayer = plr
				selectedLabel.Text = "Selected: " .. plr.Name
				selectedLabel.TextColor3 = COLORS.Accent
				updatePlayerList()
			end)

			-- Hover effect
			playerButton.MouseEnter:Connect(function()
				if selectedPlayer ~= plr then
					TweenService:Create(playerButton, TweenInfo.new(0.2), {
						BackgroundColor3 = COLORS.Border
					}):Play()
				end
			end)

			playerButton.MouseLeave:Connect(function()
				if selectedPlayer ~= plr then
					TweenService:Create(playerButton, TweenInfo.new(0.2), {
						BackgroundColor3 = COLORS.Background
					}):Play()
				end
			end)
		end

		playerScroll.CanvasSize = UDim2.fromOffset(0, #Players:GetPlayers() * 55)
	end

	updatePlayerList()

	Players.PlayerAdded:Connect(updatePlayerList)
	Players.PlayerRemoving:Connect(updatePlayerList)

	-- Animate panel in
	mainFrame.Position = UDim2.new(0.5, -450, -1, 0)
	mainFrame:TweenPosition(
		UDim2.new(0.5, -450, 0.5, -325),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		0.5,
		true
	)
end

-- Keybind to open admin panel (=)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Equals then -- "=" key
		createAdminPanel()
	end
end)

-- Auto-check admin status on startup
if isAdmin then
	createNotification("Admin Panel loaded! Press '=' to open", COLORS.Accent, 5)
end

print("✓ Admin Panel loaded - Press '=' to open (admins only)")
