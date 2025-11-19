--[[
	Improved Bounty Menu Client
	Modern, aesthetically pleasing bounty system UI
	Press B to open
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for bounty events
local bountyEvents = ReplicatedStorage:WaitForChild("BountyEvents")
local placeBountyEvent = bountyEvents:WaitForChild("PlaceBounty")
local claimBountyEvent = bountyEvents:WaitForChild("ClaimBounty")
local bountyNotification = ReplicatedStorage:WaitForChild("BountyNotification")

local bountyMenu = nil
local selectedPlayer = nil
local isAdmin = false

-- Admin user IDs (add your Roblox user ID here)
local ADMIN_USER_IDS = {
	-- Add your user ID here
	-- Example: 123456789,
}

-- Check if player is admin
local function checkAdmin()
	-- Game creator is always admin
	if player.UserId == game.CreatorId then
		isAdmin = true
		return true
	end

	-- Check admin list
	for _, adminId in pairs(ADMIN_USER_IDS) do
		if player.UserId == adminId then
			isAdmin = true
			return true
		end
	end

	return false
end

-- Check on startup
checkAdmin()

-- Modern color scheme
local COLORS = {
	Background = Color3.fromRGB(20, 20, 25),
	Panel = Color3.fromRGB(30, 30, 35),
	Accent = Color3.fromRGB(234, 179, 8), -- Gold
	AccentHover = Color3.fromRGB(202, 138, 4),
	Success = Color3.fromRGB(34, 197, 94),
	Danger = Color3.fromRGB(239, 68, 68),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(156, 163, 175),
	Border = Color3.fromRGB(55, 65, 81)
}

-- Create notification
local function createNotification(message, color, duration)
	duration = duration or 3

	local notif = Instance.new("ScreenGui")
	notif.Name = "BountyNotification"
	notif.ResetOnSpawn = false
	notif.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(450, 90)
	frame.Position = UDim2.new(0.5, -225, 0, -100)
	frame.BackgroundColor3 = color or COLORS.Accent
	frame.BorderSizePixel = 0
	frame.Parent = notif

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.Accent
	stroke.Thickness = 3
	stroke.Transparency = 0.3
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -30, 1, 0)
	label.Position = UDim2.fromOffset(15, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = COLORS.Text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextWrapped = true
	label.Parent = frame

	-- Slide down animation
	frame:TweenPosition(
		UDim2.new(0.5, -225, 0, 20),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		0.5,
		true
	)

	-- Slide up and destroy
	task.delay(duration, function()
		if frame and frame.Parent then
			frame:TweenPosition(
				UDim2.new(0.5, -225, 0, -100),
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

-- Create modern bounty menu
local function createBountyMenu()
	-- Admin check
	if not isAdmin then
		createNotification("⛔ Access Denied! Bounty menu is admin-only.", COLORS.Danger, 4)
		return
	end

	if bountyMenu then
		bountyMenu:Destroy()
		bountyMenu = nil
		return
	end

	bountyMenu = Instance.new("ScreenGui")
	bountyMenu.Name = "BountyMenu"
	bountyMenu.ResetOnSpawn = false
	bountyMenu.IgnoreGuiInset = true
	bountyMenu.Parent = playerGui

	-- Blur background
	local blur = Instance.new("Frame")
	blur.Size = UDim2.fromScale(1, 1)
	blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	blur.BackgroundTransparency = 0.3
	blur.BorderSizePixel = 0
	blur.Parent = bountyMenu

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.fromOffset(700, 750)
	mainFrame.Position = UDim2.new(0.5, -350, 0.5, -375)
	mainFrame.BackgroundColor3 = COLORS.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = bountyMenu

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Border
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 90)
	header.BackgroundColor3 = COLORS.Panel
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 18)
	headerCorner.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -100, 1, -25)
	title.Position = UDim2.fromOffset(35, 0)
	title.BackgroundTransparency = 1
	title.Text = "💰 BOUNTY HUNTER"
	title.TextColor3 = COLORS.Text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 36
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.fromOffset(500, 22)
	subtitle.Position = UDim2.fromOffset(35, 60)
	subtitle.BackgroundTransparency = 1
	title.Text = "Place bounties on players and earn rewards for eliminations"
	subtitle.TextColor3 = COLORS.TextSecondary
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 13
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = header

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(55, 55)
	closeButton.Position = UDim2.new(1, -70, 0, 17)
	closeButton.BackgroundColor3 = COLORS.Danger
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = COLORS.Text
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 28
	closeButton.AutoButtonColor = false
	closeButton.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 12)
	closeCorner.Parent = closeButton

	closeButton.MouseEnter:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(220, 38, 38),
			Size = UDim2.fromOffset(58, 58)
		}):Play()
	end)

	closeButton.MouseLeave:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Danger,
			Size = UDim2.fromOffset(55, 55)
		}):Play()
	end)

	closeButton.MouseButton1Click:Connect(function()
		-- Animate out
		mainFrame:TweenPosition(
			UDim2.new(0.5, -350, 1.5, 0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			0.3,
			true,
			function()
				bountyMenu:Destroy()
				bountyMenu = nil
			end
		)
	end)

	-- Player list container
	local playerListContainer = Instance.new("Frame")
	playerListContainer.Size = UDim2.new(1, -40, 0, 500)
	playerListContainer.Position = UDim2.fromOffset(20, 110)
	playerListContainer.BackgroundColor3 = COLORS.Panel
	playerListContainer.BorderSizePixel = 0
	playerListContainer.Parent = mainFrame

	local listContainerCorner = Instance.new("UICorner")
	listContainerCorner.CornerRadius = UDim.new(0, 14)
	listContainerCorner.Parent = playerListContainer

	-- List header
	local listHeader = Instance.new("Frame")
	listHeader.Size = UDim2.new(1, 0, 0, 50)
	listHeader.BackgroundColor3 = COLORS.Accent
	listHeader.BorderSizePixel = 0
	listHeader.Parent = playerListContainer

	local listHeaderCorner = Instance.new("UICorner")
	listHeaderCorner.CornerRadius = UDim.new(0, 14)
	listHeaderCorner.Parent = listHeader

	local listHeaderLabel = Instance.new("TextLabel")
	listHeaderLabel.Size = UDim2.new(1, -20, 1, 0)
	listHeaderLabel.Position = UDim2.fromOffset(20, 0)
	listHeaderLabel.BackgroundTransparency = 1
	listHeaderLabel.Text = "👤 SELECT TARGET PLAYER"
	listHeaderLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	listHeaderLabel.Font = Enum.Font.GothamBold
	listHeaderLabel.TextSize = 18
	listHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
	listHeaderLabel.Parent = listHeader

	-- Player count badge
	local playerCountBadge = Instance.new("TextLabel")
	playerCountBadge.Size = UDim2.fromOffset(45, 32)
	playerCountBadge.Position = UDim2.new(1, -55, 0, 9)
	playerCountBadge.BackgroundColor3 = COLORS.Background
	playerCountBadge.BorderSizePixel = 0
	playerCountBadge.Text = tostring(#Players:GetPlayers())
	playerCountBadge.TextColor3 = COLORS.Accent
	playerCountBadge.Font = Enum.Font.GothamBold
	playerCountBadge.TextSize = 16
	playerCountBadge.Parent = listHeader

	local countCorner = Instance.new("UICorner")
	countCorner.CornerRadius = UDim.new(0, 8)
	countCorner.Parent = playerCountBadge

	-- Scroll frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -10, 1, -60)
	scrollFrame.Position = UDim2.fromOffset(5, 55)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = COLORS.Accent
	scrollFrame.Parent = playerListContainer

	local playerListLayout = Instance.new("UIListLayout")
	playerListLayout.SortOrder = Enum.SortOrder.Name
	playerListLayout.Padding = UDim.new(0, 6)
	playerListLayout.Parent = scrollFrame

	-- Bounty input section
	local bountyInputSection = Instance.new("Frame")
	bountyInputSection.Size = UDim2.new(1, -40, 0, 85)
	bountyInputSection.Position = UDim2.fromOffset(20, 630)
	bountyInputSection.BackgroundColor3 = COLORS.Panel
	bountyInputSection.BorderSizePixel = 0
	bountyInputSection.Parent = mainFrame

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 14)
	inputCorner.Parent = bountyInputSection

	local bountyLabel = Instance.new("TextLabel")
	bountyLabel.Size = UDim2.fromOffset(150, 85)
	bountyLabel.Position = UDim2.fromOffset(20, 0)
	bountyLabel.BackgroundTransparency = 1
	bountyLabel.Text = "💵 Bounty:"
	bountyLabel.TextColor3 = COLORS.Text
	bountyLabel.Font = Enum.Font.GothamBold
	bountyLabel.TextSize = 20
	bountyLabel.TextXAlignment = Enum.TextXAlignment.Left
	bountyLabel.Parent = bountyInputSection

	-- Amount input box
	local amountBox = Instance.new("TextBox")
	amountBox.Size = UDim2.fromOffset(280, 55)
	amountBox.Position = UDim2.fromOffset(165, 15)
	amountBox.BackgroundColor3 = COLORS.Background
	amountBox.BorderSizePixel = 0
	amountBox.Text = "1000"
	amountBox.TextColor3 = COLORS.Accent
	amountBox.Font = Enum.Font.GothamBold
	amountBox.TextSize = 24
	amountBox.PlaceholderText = "Enter amount..."
	amountBox.PlaceholderColor3 = COLORS.TextSecondary
	amountBox.ClearTextOnFocus = false
	amountBox.Parent = bountyInputSection

	local amountCorner = Instance.new("UICorner")
	amountCorner.CornerRadius = UDim.new(0, 12)
	amountCorner.Parent = amountBox

	local amountStroke = Instance.new("UIStroke")
	amountStroke.Color = COLORS.Border
	amountStroke.Thickness = 2
	amountStroke.Parent = amountBox

	-- Place bounty button
	local placeButton = Instance.new("TextButton")
	placeButton.Size = UDim2.fromOffset(185, 55)
	placeButton.Position = UDim2.fromOffset(455, 15)
	placeButton.BackgroundColor3 = COLORS.Accent
	placeButton.BorderSizePixel = 0
	placeButton.Text = "🎯 PLACE BOUNTY"
	placeButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	placeButton.Font = Enum.Font.GothamBold
	placeButton.TextSize = 16
	placeButton.AutoButtonColor = false
	placeButton.Parent = bountyInputSection

	local placeCorner = Instance.new("UICorner")
	placeCorner.CornerRadius = UDim.new(0, 12)
	placeCorner.Parent = placeButton

	-- Hover effect for place button
	placeButton.MouseEnter:Connect(function()
		TweenService:Create(placeButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.AccentHover,
			Size = UDim2.fromOffset(190, 58)
		}):Play()
	end)

	placeButton.MouseLeave:Connect(function()
		TweenService:Create(placeButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Accent,
			Size = UDim2.fromOffset(185, 55)
		}):Play()
	end)

	-- Update player list function
	local function updatePlayerList()
		-- Clear existing
		for _, child in pairs(scrollFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		playerCountBadge.Text = tostring(#Players:GetPlayers())

		for _, plr in pairs(Players:GetPlayers()) do
			local playerButton = Instance.new("TextButton")
			playerButton.Size = UDim2.fromOffset(640, 60)
			playerButton.BackgroundColor3 = selectedPlayer == plr and COLORS.Accent or COLORS.Background
			playerButton.BorderSizePixel = 0
			playerButton.AutoButtonColor = false
			playerButton.Text = ""
			playerButton.Parent = scrollFrame

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 10)
			btnCorner.Parent = playerButton

			-- Player thumbnail
			local thumbnail = Instance.new("ImageLabel")
			thumbnail.Size = UDim2.fromOffset(45, 45)
			thumbnail.Position = UDim2.fromOffset(10, 8)
			thumbnail.BackgroundColor3 = COLORS.Panel
			thumbnail.BorderSizePixel = 0
			thumbnail.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			thumbnail.Parent = playerButton

			local thumbCorner = Instance.new("UICorner")
			thumbCorner.CornerRadius = UDim.new(1, 0)
			thumbCorner.Parent = thumbnail

			-- Player name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -130, 1, 0)
			nameLabel.Position = UDim2.fromOffset(65, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = plr.Name .. (plr == player and " (YOU)" or "")
			nameLabel.TextColor3 = selectedPlayer == plr and Color3.fromRGB(0, 0, 0) or COLORS.Text
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 18
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = playerButton

			-- Selection indicator
			if selectedPlayer == plr then
				local checkMark = Instance.new("TextLabel")
				checkMark.Size = UDim2.fromOffset(40, 40)
				checkMark.Position = UDim2.new(1, -50, 0, 10)
				checkMark.BackgroundTransparency = 1
				checkMark.Text = "✓"
				checkMark.TextColor3 = Color3.fromRGB(0, 0, 0)
				checkMark.Font = Enum.Font.GothamBold
				checkMark.TextSize = 28
				checkMark.Parent = playerButton
			end

			playerButton.MouseButton1Click:Connect(function()
				selectedPlayer = plr
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

		scrollFrame.CanvasSize = UDim2.fromOffset(0, #Players:GetPlayers() * 66)
	end

	-- Place bounty logic
	placeButton.MouseButton1Click:Connect(function()
		if not selectedPlayer then
			createNotification("⚠️ Please select a target player first!", COLORS.Danger)
			return
		end

		local amount = tonumber(amountBox.Text)
		if not amount or amount < 100 or amount > 1000000 then
			createNotification("⚠️ Invalid amount! Must be between 100 and 1,000,000", COLORS.Danger)
			return
		end

		placeBountyEvent:FireServer(selectedPlayer, amount)

		-- Close menu with animation
		mainFrame:TweenPosition(
			UDim2.new(0.5, -350, 1.5, 0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			0.3,
			true,
			function()
				bountyMenu:Destroy()
				bountyMenu = nil
			end
		)

		local message = selectedPlayer == player and
			"💰 Placed bounty of $" .. amount .. " on yourself!" or
			"💰 Placed bounty of $" .. amount .. " on " .. selectedPlayer.Name .. "!"
		createNotification(message, COLORS.Success)
	end)

	updatePlayerList()

	Players.PlayerAdded:Connect(updatePlayerList)
	Players.PlayerRemoving:Connect(updatePlayerList)

	-- Animate menu in
	mainFrame.Position = UDim2.new(0.5, -350, -1, 0)
	mainFrame:TweenPosition(
		UDim2.new(0.5, -350, 0.5, -375),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		0.5,
		true
	)
end

-- Handle bounty notifications
bountyNotification.OnClientEvent:Connect(function(action, player1, player2, amount)
	if action == "placed" then
		local message = player1:find("(SELF)") and
			"💰 " .. player1 .. " placed a bounty of $" .. amount .. " on themselves!" or
			"💰 " .. player1 .. " placed a bounty of $" .. amount .. " on " .. player2 .. "!"
		createNotification(message, COLORS.Accent)
	elseif action == "claimed" then
		local message = "🎯 " .. player1 .. " claimed a bounty of $" .. amount .. " for eliminating " .. player2 .. "!"
		createNotification(message, COLORS.Success)
	elseif action == "cleared" then
		local message = "⚠️ Bounty of $" .. amount .. " on " .. player1 .. " was cleared!"
		createNotification(message, COLORS.Danger)
	end
end)

-- Press B to open bounty menu (admins only)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.B then
		createBountyMenu()
	end
end)

-- Notify admin status on load
if isAdmin then
	task.delay(2, function()
		createNotification("💰 Bounty Menu unlocked! Press 'B' to open", COLORS.Accent, 4)
	end)
end

print("✓ Improved Bounty System loaded - Press 'B' to open (admins only)")
