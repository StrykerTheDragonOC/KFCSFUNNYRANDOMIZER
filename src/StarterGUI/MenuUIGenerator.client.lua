--[[
	Menu UI Generator - Phantom Forces Style
	Left sidebar navigation with sections on the right
	Based on PhantomForcesMainMenuExample.png reference
	UPDATED: Now integrates with existing RBXM files and MenuSections module
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load MenuSections module
local MenuSections = require(script.Parent:WaitForChild("MenuSections"))

local MenuGenerator = {}

-- Color scheme
local COLORS = {
	Background = Color3.fromRGB(15, 20, 25),
	Sidebar = Color3.fromRGB(20, 25, 30),
	ButtonInactive = Color3.fromRGB(30, 40, 50),
	ButtonActive = Color3.fromRGB(40, 90, 110),
	ButtonHover = Color3.fromRGB(35, 70, 90),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(180, 190, 200),
	Accent = Color3.fromRGB(50, 200, 255)
}

-- Create or get main ScreenGui (use existing RBXM if available)
function MenuGenerator:CreateScreenGui()
	local existing = playerGui:FindFirstChild("FPSMainMenu")

	-- If RBXM exists, use it instead of destroying!
	if existing then
		print("✓ Found existing FPSMainMenu RBXM, using it")
		-- Ensure properties are correct
		existing.ResetOnSpawn = false
		existing.DisplayOrder = 100
		existing.IgnoreGuiInset = true
		existing.Enabled = true
		return existing
	end

	-- No RBXM found, create new ScreenGui
	print("⚠ No FPSMainMenu RBXM found, creating new ScreenGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FPSMainMenu"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = true
	screenGui.Parent = playerGui

	return screenGui
end

-- Create or get main container
function MenuGenerator:CreateMainContainer(parent)
	-- Check if MainContainer already exists in RBXM
	local existing = parent:FindFirstChild("MainContainer")
	if existing then
		print("✓ Found existing MainContainer, using it")
		-- Ensure properties are correct
		existing.Size = UDim2.new(1, 0, 1, 0)
		existing.BackgroundColor3 = COLORS.Background
		existing.BorderSizePixel = 0
		return existing
	end

	print("⚠ Creating new MainContainer")
	local container = Instance.new("Frame")
	container.Name = "MainContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = COLORS.Background
	container.BorderSizePixel = 0
	container.Parent = parent

	return container
end

-- Create or get left sidebar
function MenuGenerator:CreateSidebar(parent)
	-- Check if Sidebar already exists in RBXM
	local existing = parent:FindFirstChild("Sidebar")
	if existing then
		print("✓ Found existing Sidebar, populating it")
		-- Ensure properties are correct
		existing.Size = UDim2.new(0, 200, 1, 0)
		existing.Position = UDim2.new(0, 0, 0, 0)
		existing.BackgroundColor3 = COLORS.Sidebar
		existing.BorderSizePixel = 0

		-- Check for title, add if missing
		local title = existing:FindFirstChild("MenuTitle")
		if not title then
			title = Instance.new("TextLabel")
			title.Name = "MenuTitle"
			title.Size = UDim2.new(1, -20, 0, 50)
			title.Position = UDim2.new(0, 10, 0, 10)
			title.BackgroundTransparency = 1
			title.Text = "MAIN MENU"
			title.TextColor3 = COLORS.Accent
			title.Font = Enum.Font.GothamBold
			title.TextSize = 20
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = existing
		end

		return existing
	end

	print("⚠ Creating new Sidebar")
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 200, 1, 0)
	sidebar.Position = UDim2.new(0, 0, 0, 0)
	sidebar.BackgroundColor3 = COLORS.Sidebar
	sidebar.BorderSizePixel = 0
	sidebar.Parent = parent

	-- Title at top
	local title = Instance.new("TextLabel")
	title.Name = "MenuTitle"
	title.Size = UDim2.new(1, -20, 0, 50)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "MAIN MENU"
	title.TextColor3 = COLORS.Accent
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = sidebar

	return sidebar
end

-- Create sidebar button
function MenuGenerator:CreateSidebarButton(parent, text, position, isFirst)
	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Size = UDim2.new(1, -10, 0, 45)
	button.Position = position
	button.BackgroundColor3 = isFirst and COLORS.ButtonActive or COLORS.ButtonInactive
	button.BorderSizePixel = 0
	button.Text = text:upper()
	button.TextColor3 = COLORS.Text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.AutoButtonColor = false
	button.Parent = parent

	-- Add padding for left-aligned text
	local textPadding = Instance.new("UIPadding")
	textPadding.PaddingLeft = UDim.new(0, 15)
	textPadding.Parent = button

	-- Active indicator
	local indicator = Instance.new("Frame")
	indicator.Name = "ActiveIndicator"
	indicator.Size = UDim2.new(0, 4, 0.7, 0)
	indicator.Position = UDim2.new(0, 0, 0.15, 0)
	indicator.BackgroundColor3 = COLORS.Accent
	indicator.BorderSizePixel = 0
	indicator.Visible = isFirst
	indicator.Parent = button

	return button
end

-- Create or get content area
function MenuGenerator:CreateContentArea(parent)
	-- Check if ContentArea already exists in RBXM
	local existing = parent:FindFirstChild("ContentArea")
	if existing then
		print("✓ Found existing ContentArea, using it")
		-- Ensure properties are correct
		existing.Size = UDim2.new(1, -200, 1, 0)
		existing.Position = UDim2.new(0, 200, 0, 0)
		existing.BackgroundTransparency = 1
		return existing
	end

	print("⚠ Creating new ContentArea")
	local content = Instance.new("Frame")
	content.Name = "ContentArea"
	content.Size = UDim2.new(1, -200, 1, 0)
	content.Position = UDim2.new(0, 200, 0, 0)
	content.BackgroundTransparency = 1
	content.Parent = parent

	return content
end

-- Create Deploy section
function MenuGenerator:CreateDeploySection(parent)
	-- Check if DeploySection already exists in RBXM
	local existing = parent:FindFirstChild("DeploySection")
	if existing then
		print("✓ Found existing DeploySection in RBXM, using it")
		-- Ensure it's visible and properly configured
		existing.Size = UDim2.new(1, 0, 1, 0)
		existing.BackgroundTransparency = 1
		existing.Visible = true

		-- Setup hover effects on existing deploy button if found
		local existingBtn = existing:FindFirstChild("DeployButton")
		if existingBtn and existingBtn:IsA("TextButton") then
			-- Clear any existing connections and add new ones
			existingBtn.MouseEnter:Connect(function()
				TweenService:Create(existingBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 200, 110)}):Play()
			end)
			existingBtn.MouseLeave:Connect(function()
				TweenService:Create(existingBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 180, 100)}):Play()
			end)
			print("✓ Connected hover effects to existing DeployButton")
		end

		return existing
	end

	print("⚠ Creating new DeploySection")
	local section = Instance.new("Frame")
	section.Name = "DeploySection"
	section.Size = UDim2.new(1, 0, 1, 0)
	section.BackgroundTransparency = 1
	section.Visible = true
	section.Parent = parent

	-- Check if GameTitle already exists before creating (in case RBXM has it elsewhere)
	local existingTitle = section:FindFirstChild("GameTitle", true) or parent:FindFirstChild("GameTitle", true)
	if not existingTitle then
		-- Game title
		local title = Instance.new("TextLabel")
		title.Name = "GameTitle"
		title.Size = UDim2.new(0, 700, 0, 80)
		title.Position = UDim2.new(0.5, -350, 0.15, 0)
		title.BackgroundTransparency = 1
		title.Text = "KFC'S FUNNY RANDOMIZER 4.0"
		title.TextColor3 = COLORS.Accent
		title.Font = Enum.Font.GothamBold
		title.TextSize = 38
		title.Parent = section
		print("✓ Created GameTitle")
	else
		print("✓ GameTitle already exists, skipping creation")
		-- Move it to section if it's in parent
		if existingTitle.Parent == parent then
			existingTitle.Parent = section
		end
	end

	-- Check if DeployButton already exists before creating
	local existingBtn = section:FindFirstChild("DeployButton", true) or parent:FindFirstChild("DeployButton", true)
	if not existingBtn then
		-- Deploy button
		local deployBtn = Instance.new("TextButton")
		deployBtn.Name = "DeployButton"
		deployBtn.Size = UDim2.new(0, 400, 0, 80)
		deployBtn.Position = UDim2.new(0.5, -200, 0.45, 0)
		deployBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
		deployBtn.BorderSizePixel = 0
		deployBtn.Text = "ENTER THE BATTLEFIELD"
		deployBtn.TextColor3 = COLORS.Text
		deployBtn.Font = Enum.Font.GothamBold
		deployBtn.TextSize = 24
		deployBtn.AutoButtonColor = false
		deployBtn.Parent = section

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = deployBtn

		-- Hover effect
		deployBtn.MouseEnter:Connect(function()
			TweenService:Create(deployBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 200, 110)}):Play()
		end)

		deployBtn.MouseLeave:Connect(function()
			TweenService:Create(deployBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 180, 100)}):Play()
		end)
		print("✓ Created DeployButton")
	else
		print("✓ DeployButton already exists, skipping creation")
		-- Move it to section if it's in parent and connect hover effects
		if existingBtn.Parent == parent then
			existingBtn.Parent = section
		end

		-- Connect hover effects to existing button
		if existingBtn:IsA("TextButton") then
			existingBtn.MouseEnter:Connect(function()
				TweenService:Create(existingBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 200, 110)}):Play()
			end)
			existingBtn.MouseLeave:Connect(function()
				TweenService:Create(existingBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 180, 100)}):Play()
			end)
		end
	end

	-- Check if Hint already exists before creating
	local existingHint = section:FindFirstChild("Hint", true) or parent:FindFirstChild("Hint", true)
	if not existingHint then
		-- Hint text
		local hint = Instance.new("TextLabel")
		hint.Name = "Hint"
		hint.Size = UDim2.new(1, 0, 0, 30)
		hint.Position = UDim2.new(0, 0, 0.58, 0)
		hint.BackgroundTransparency = 1
		hint.Text = "Press SPACE or click to deploy"
		hint.TextColor3 = COLORS.TextDim
		hint.Font = Enum.Font.Gotham
		hint.TextSize = 16
		hint.Parent = section
		print("✓ Created Hint text")
	else
		print("✓ Hint text already exists, skipping creation")
		-- Move it to section if it's in parent
		if existingHint.Parent == parent then
			existingHint.Parent = section
		end
	end

	-- Add gamemode voting panel
	self:CreateGamemodeVotingPanel(section)

	return section
end

-- Create Gamemode Voting Panel
function MenuGenerator:CreateGamemodeVotingPanel(deploySection)
	-- Voting panel container (hidden by default) - positioned properly in center
	local votingPanel = Instance.new("Frame")
	votingPanel.Name = "VotingPanel"
	votingPanel.Size = UDim2.new(0, 600, 0, 250)
	votingPanel.Position = UDim2.new(0.5, -300, 0.5, -125) -- Centered
	votingPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	votingPanel.BorderSizePixel = 0
	votingPanel.Visible = false -- Hidden until voting starts
	votingPanel.ZIndex = 10 -- Ensure it's on top
	votingPanel.Parent = deploySection

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = votingPanel

	-- Voting title
	local votingTitle = Instance.new("TextLabel")
	votingTitle.Name = "VotingTitle"
	votingTitle.Size = UDim2.new(1, -20, 0, 30)
	votingTitle.Position = UDim2.new(0, 10, 0, 10)
	votingTitle.BackgroundTransparency = 1
	votingTitle.Text = "VOTE FOR GAMEMODE"
	votingTitle.TextColor3 = COLORS.Accent
	votingTitle.Font = Enum.Font.GothamBold
	votingTitle.TextSize = 18
	votingTitle.TextXAlignment = Enum.TextXAlignment.Left
	votingTitle.Parent = votingPanel

	-- Time remaining label
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(0, 100, 0, 30)
	timeLabel.Position = UDim2.new(1, -110, 0, 10)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "30s"
	timeLabel.TextColor3 = COLORS.TextDim
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.TextSize = 16
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeLabel.Parent = votingPanel

	-- Gamemode options container
	local optionsContainer = Instance.new("Frame")
	optionsContainer.Name = "OptionsContainer"
	optionsContainer.Size = UDim2.new(1, -20, 1, -50)
	optionsContainer.Position = UDim2.new(0, 10, 0, 45)
	optionsContainer.BackgroundTransparency = 1
	optionsContainer.Parent = votingPanel

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.24, -5, 1, 0)
	gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = optionsContainer

	-- Setup voting event listeners
	self:SetupVotingEvents(deploySection)

	print("✓ Gamemode voting panel created")
end

-- Setup voting event listeners
function MenuGenerator:SetupVotingEvents(deploySection)
	local votingPanel = deploySection:FindFirstChild("VotingPanel")
	if not votingPanel then return end

	local optionsContainer = votingPanel:FindFirstChild("OptionsContainer")
	local timeLabel = votingPanel:FindFirstChild("TimeLabel")

	-- Listen for voting start
	local startVotingEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("StartVoting")
	if startVotingEvent then
		startVotingEvent.OnClientEvent:Connect(function(data)
			print("✓ Voting started!", data)
			votingPanel.Visible = true

			-- Clear previous options
			for _, child in pairs(optionsContainer:GetChildren()) do
				if not child:IsA("UIGridLayout") then
					child:Destroy()
				end
			end

			-- Create gamemode option buttons
            for i, modeCode in ipairs(data.Candidates or data.modes or {}) do
                local modeData = (data.GamemodeData or data.modeData or {})[modeCode]
				if modeData then
					local optionButton = self:CreateGamemodeOption(modeCode, modeData, i)
					optionButton.Parent = optionsContainer
				end
			end

			-- Start countdown timer
            local duration = data.VotingTime or data.duration or 30
			local startTime = tick()

			local connection
			connection = game:GetService("RunService").Heartbeat:Connect(function()
				local remaining = math.max(0, duration - (tick() - startTime))
				if timeLabel then
					timeLabel.Text = string.format("%ds", math.ceil(remaining))
				end

				if remaining <= 0 then
					connection:Disconnect()
				end
			end)
		end)
	end

	-- Listen for vote updates
	local updateVotesEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("UpdateVotes")
	if updateVotesEvent then
		updateVotesEvent.OnClientEvent:Connect(function(data)
			-- Update vote counts on buttons
			for _, optionButton in pairs(optionsContainer:GetChildren()) do
				if optionButton:IsA("TextButton") and optionButton:GetAttribute("ModeCode") then
					local modeCode = optionButton:GetAttribute("ModeCode")
					local voteLabel = optionButton:FindFirstChild("VoteCount")
                    local votes = data.Votes or data.votes
                    if voteLabel and votes and votes[modeCode] then
                        voteLabel.Text = votes[modeCode] .. " votes"
					end
				end
			end
		end)
	end

	-- Listen for voting end
	local endVotingEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("EndVoting")
	if endVotingEvent then
		endVotingEvent.OnClientEvent:Connect(function(data)
			print("✓ Voting ended! Winner:", data.winner)

			-- Highlight winner for 3 seconds before hiding
            for _, optionButton in pairs(optionsContainer:GetChildren()) do
				if optionButton:IsA("TextButton") and optionButton:GetAttribute("ModeCode") == data.winner then
					optionButton.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
				end
			end

			wait(3)
			votingPanel.Visible = false
		end)
	end

	print("✓ Voting event listeners setup")
end

-- Create gamemode option button
function MenuGenerator:CreateGamemodeOption(modeCode, modeData, layoutOrder)
	local optionButton = Instance.new("TextButton")
	optionButton.Name = modeCode .. "Option"
	optionButton.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
	optionButton.BorderSizePixel = 0
	optionButton.Text = ""
	optionButton.AutoButtonColor = false
	optionButton.LayoutOrder = layoutOrder
	optionButton:SetAttribute("ModeCode", modeCode)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = optionButton

	-- Mode name
	local modeName = Instance.new("TextLabel")
	modeName.Name = "ModeName"
	modeName.Size = UDim2.new(1, -10, 0, 30)
	modeName.Position = UDim2.new(0, 5, 0, 10)
	modeName.BackgroundTransparency = 1
	modeName.Text = modeData.Name
	modeName.TextColor3 = COLORS.Text
	modeName.Font = Enum.Font.GothamBold
	modeName.TextSize = 14
	modeName.TextScaled = true
	modeName.TextWrapped = true
	modeName.Parent = optionButton

	-- Mode description
	local modeDesc = Instance.new("TextLabel")
	modeDesc.Name = "ModeDescription"
	modeDesc.Size = UDim2.new(1, -10, 0, 40)
	modeDesc.Position = UDim2.new(0, 5, 0, 45)
	modeDesc.BackgroundTransparency = 1
	modeDesc.Text = modeData.Description
	modeDesc.TextColor3 = COLORS.TextDim
	modeDesc.Font = Enum.Font.Gotham
	modeDesc.TextSize = 11
	modeDesc.TextScaled = true
	modeDesc.TextWrapped = true
	modeDesc.Parent = optionButton

	-- Vote count
	local voteCount = Instance.new("TextLabel")
	voteCount.Name = "VoteCount"
	voteCount.Size = UDim2.new(1, -10, 0, 25)
	voteCount.Position = UDim2.new(0, 5, 1, -30)
	voteCount.BackgroundTransparency = 1
	voteCount.Text = "0 votes"
	voteCount.TextColor3 = COLORS.Accent
	voteCount.Font = Enum.Font.GothamBold
	voteCount.TextSize = 12
	voteCount.Parent = optionButton

	-- Click to vote
	optionButton.MouseButton1Click:Connect(function()
		local voteEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("VoteForGamemode")
		if voteEvent then
			voteEvent:FireServer(modeCode)
			print("Voted for:", modeCode)
		end
	end)

	-- Hover effects
	optionButton.MouseEnter:Connect(function()
		TweenService:Create(optionButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 60, 80)}):Play()
	end)

	optionButton.MouseLeave:Connect(function()
		TweenService:Create(optionButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 40, 50)}):Play()
	end)

	return optionButton
end

-- Create Loadout/Customize section (renamed to LoadoutSection to match MenuController)
function MenuGenerator:CreateCustomizeSection(parent)
	local section = Instance.new("Frame")
	section.Name = "LoadoutSection"  -- Changed from CustomizeSection to match MenuController
	section.Size = UDim2.new(1, 0, 1, 0)
	section.BackgroundTransparency = 1
	section.Visible = false
	section.Parent = parent

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0, 400, 0, 40)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "WEAPON LOADOUTS"
	title.TextColor3 = COLORS.Text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = section

	-- Class tabs (top)
	local classTabBar = Instance.new("Frame")
	classTabBar.Name = "ClassTabBar"
	classTabBar.Size = UDim2.new(1, -40, 0, 50)
	classTabBar.Position = UDim2.new(0, 20, 0, 60)
	classTabBar.BackgroundTransparency = 1
	classTabBar.Parent = section

	local classes = {"ASSAULT", "SCOUT", "SUPPORT", "RECON"}
	local classColors = {
		Color3.fromRGB(200, 80, 80),   -- Red
		Color3.fromRGB(80, 180, 100),  -- Green
		Color3.fromRGB(80, 120, 200),  -- Blue
		Color3.fromRGB(200, 160, 60)   -- Yellow
	}

	for i, className in ipairs(classes) do
		local tab = Instance.new("TextButton")
		tab.Name = className .. "Tab"
		tab.Size = UDim2.new(0.24, -5, 1, 0)
		tab.Position = UDim2.new((i - 1) * 0.25, 0, 0, 0)
		tab.BackgroundColor3 = i == 1 and classColors[i] or Color3.fromRGB(40, 50, 60)
		tab.BorderSizePixel = 0
		tab.Text = className
		tab.TextColor3 = COLORS.Text
		tab.Font = Enum.Font.GothamBold
		tab.TextSize = 16
		tab.AutoButtonColor = false
		tab.Parent = classTabBar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = tab

		-- Store class color
		tab:SetAttribute("ClassColor", classColors[i]:ToHex())
	end

	-- Weapon category tabs
	local categoryTabBar = Instance.new("Frame")
	categoryTabBar.Name = "CategoryTabBar"
	categoryTabBar.Size = UDim2.new(1, -40, 0, 45)
	categoryTabBar.Position = UDim2.new(0, 20, 0, 120)
	categoryTabBar.BackgroundTransparency = 1
	categoryTabBar.Parent = section

	local categories = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE"}
	for i, catName in ipairs(categories) do
		local tab = Instance.new("TextButton")
		tab.Name = catName .. "Tab"
		tab.Size = UDim2.new(0.24, -5, 1, 0)
		tab.Position = UDim2.new((i - 1) * 0.25, 0, 0, 0)
		tab.BackgroundColor3 = i == 1 and Color3.fromRGB(50, 140, 160) or Color3.fromRGB(30, 40, 50)
		tab.BorderSizePixel = 0
		tab.Text = catName
		tab.TextColor3 = COLORS.Text
		tab.Font = Enum.Font.Gotham
		tab.TextSize = 14
		tab.AutoButtonColor = false
		tab.Parent = categoryTabBar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = tab
	end

	-- Content panels container
	local panelsContainer = Instance.new("Frame")
	panelsContainer.Name = "PanelsContainer"
	panelsContainer.Size = UDim2.new(1, -40, 1, -185)
	panelsContainer.Position = UDim2.new(0, 20, 0, 175)
	panelsContainer.BackgroundTransparency = 1
	panelsContainer.Parent = section

	-- Left panel - Weapon list
	local weaponList = Instance.new("ScrollingFrame")
	weaponList.Name = "WeaponList"
	weaponList.Size = UDim2.new(0, 250, 1, 0)
	weaponList.Position = UDim2.new(0, 0, 0, 0)
	weaponList.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
	weaponList.BorderSizePixel = 0
	weaponList.ScrollBarThickness = 6
	weaponList.Parent = panelsContainer

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 6)
	listCorner.Parent = weaponList

	-- List title
	local listTitle = Instance.new("TextLabel")
	listTitle.Name = "Title"
	listTitle.Size = UDim2.new(1, -20, 0, 35)
	listTitle.Position = UDim2.new(0, 10, 0, 5)
	listTitle.BackgroundTransparency = 1
	listTitle.Text = "WEAPONS"
	listTitle.TextColor3 = COLORS.Text
	listTitle.Font = Enum.Font.GothamBold
	listTitle.TextSize = 14
	listTitle.TextXAlignment = Enum.TextXAlignment.Left
	listTitle.Parent = weaponList

	-- Add UIListLayout for weapon buttons
	local listLayout = Instance.new("UIListLayout")
	listLayout.Name = "ListLayout"
	listLayout.Padding = UDim.new(0, 3)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = weaponList

	-- Padding for list
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingLeft = UDim.new(0, 10)
	listPadding.PaddingRight = UDim.new(0, 10)
	listPadding.PaddingTop = UDim.new(0, 45)
	listPadding.PaddingBottom = UDim.new(0, 10)
	listPadding.Parent = weaponList

	-- Center panel - Weapon preview
	local weaponPreview = Instance.new("Frame")
	weaponPreview.Name = "WeaponPreview"
	weaponPreview.Size = UDim2.new(1, -520, 1, 0)
	weaponPreview.Position = UDim2.new(0, 260, 0, 0)
	weaponPreview.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
	weaponPreview.BorderSizePixel = 0
	weaponPreview.Parent = panelsContainer

	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 6)
	previewCorner.Parent = weaponPreview

	-- Preview title
	local previewTitle = Instance.new("TextLabel")
	previewTitle.Name = "WeaponName"
	previewTitle.Size = UDim2.new(1, -20, 0, 40)
	previewTitle.Position = UDim2.new(0, 10, 0, 10)
	previewTitle.BackgroundTransparency = 1
	previewTitle.Text = "SELECT A WEAPON"
	previewTitle.TextColor3 = COLORS.TextDim
	previewTitle.Font = Enum.Font.GothamBold
	previewTitle.TextSize = 18
	previewTitle.TextXAlignment = Enum.TextXAlignment.Left
	previewTitle.Parent = weaponPreview

	-- ViewportFrame for 3D weapon model
	local viewportFrame = Instance.new("ViewportFrame")
	viewportFrame.Name = "WeaponViewport"
	viewportFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
	viewportFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
	viewportFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	viewportFrame.BorderSizePixel = 0
	viewportFrame.Ambient = Color3.fromRGB(150, 150, 150)
	viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
	viewportFrame.Parent = weaponPreview

	local viewportCorner = Instance.new("UICorner")
	viewportCorner.CornerRadius = UDim.new(0, 4)
	viewportCorner.Parent = viewportFrame

	-- Create camera for viewport
	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	-- Placeholder text when no weapon selected
	local placeholderText = Instance.new("TextLabel")
	placeholderText.Name = "PlaceholderText"
	placeholderText.Size = UDim2.new(1, 0, 1, 0)
	placeholderText.BackgroundTransparency = 1
	placeholderText.Text = "Select a weapon"
	placeholderText.TextColor3 = COLORS.TextDim
	placeholderText.Font = Enum.Font.Gotham
	placeholderText.TextSize = 14
	placeholderText.Visible = true
	placeholderText.Parent = viewportFrame

	-- Right panel - Weapon stats
	local weaponStats = Instance.new("ScrollingFrame")
	weaponStats.Name = "WeaponStats"
	weaponStats.Size = UDim2.new(0, 250, 1, 0)
	weaponStats.Position = UDim2.new(1, -250, 0, 0)
	weaponStats.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
	weaponStats.BorderSizePixel = 0
	weaponStats.ScrollBarThickness = 6
	weaponStats.Parent = panelsContainer

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 6)
	statsCorner.Parent = weaponStats

	-- Stats title
	local statsTitle = Instance.new("TextLabel")
	statsTitle.Name = "Title"
	statsTitle.Size = UDim2.new(1, -20, 0, 35)
	statsTitle.Position = UDim2.new(0, 10, 0, 5)
	statsTitle.BackgroundTransparency = 1
	statsTitle.Text = "WEAPON BALLISTICS"
	statsTitle.TextColor3 = COLORS.Text
	statsTitle.Font = Enum.Font.GothamBold
	statsTitle.TextSize = 14
	statsTitle.TextXAlignment = Enum.TextXAlignment.Left
	statsTitle.Parent = weaponStats

	-- Add UIListLayout for stats
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.Name = "StatsLayout"
	statsLayout.Padding = UDim.new(0, 8)
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Parent = weaponStats

	-- Padding for stats
	local statsPadding = Instance.new("UIPadding")
	statsPadding.PaddingLeft = UDim.new(0, 10)
	statsPadding.PaddingRight = UDim.new(0, 10)
	statsPadding.PaddingTop = UDim.new(0, 45)
	statsPadding.PaddingBottom = UDim.new(0, 10)
	statsPadding.Parent = weaponStats

	-- Setup tab navigation
	self:SetupCustomizeTabs(classTabBar, categoryTabBar, weaponList)

	-- Populate with default weapons
	self:PopulateWeaponList(weaponList, "Primary")

	return section
end

-- Setup customize section tab navigation
function MenuGenerator:SetupCustomizeTabs(classTabBar, categoryTabBar, weaponList)
	-- Class tab switching
	for _, classTab in pairs(classTabBar:GetChildren()) do
		if classTab:IsA("TextButton") then
			classTab.MouseButton1Click:Connect(function()
				local classColor = Color3.fromHex(classTab:GetAttribute("ClassColor"))

				for _, tab in pairs(classTabBar:GetChildren()) do
					if tab:IsA("TextButton") then
						if tab == classTab then
							tab.BackgroundColor3 = classColor
						else
							tab.BackgroundColor3 = Color3.fromRGB(40, 50, 60)
						end
					end
				end
			end)

			classTab.MouseEnter:Connect(function()
				local classColor = Color3.fromHex(classTab:GetAttribute("ClassColor"))
				if classTab.BackgroundColor3 == Color3.fromRGB(40, 50, 60) then
					classTab.BackgroundColor3 = Color3.new(
						classColor.R * 0.6,
						classColor.G * 0.6,
						classColor.B * 0.6
					)
				end
			end)

			classTab.MouseLeave:Connect(function()
				local classColor = Color3.fromHex(classTab:GetAttribute("ClassColor"))
				local isActive = classTab.BackgroundColor3.R > 0.5 or classTab.BackgroundColor3.G > 0.5 or classTab.BackgroundColor3.B > 0.5
				if not (classTab.BackgroundColor3 == classColor) then
					classTab.BackgroundColor3 = Color3.fromRGB(40, 50, 60)
				end
			end)
		end
	end

	-- Category tab switching
	for _, catTab in pairs(categoryTabBar:GetChildren()) do
		if catTab:IsA("TextButton") then
			catTab.MouseButton1Click:Connect(function()
				for _, tab in pairs(categoryTabBar:GetChildren()) do
					if tab:IsA("TextButton") then
						if tab == catTab then
							tab.BackgroundColor3 = Color3.fromRGB(50, 140, 160)
						else
							tab.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
						end
					end
				end

				-- Update weapon list
				local category = catTab.Name:gsub("Tab", "")
				self:PopulateWeaponList(weaponList, category)
			end)

			catTab.MouseEnter:Connect(function()
				if catTab.BackgroundColor3 == Color3.fromRGB(30, 40, 50) then
					catTab.BackgroundColor3 = Color3.fromRGB(40, 80, 100)
				end
			end)

			catTab.MouseLeave:Connect(function()
				if catTab.BackgroundColor3 ~= Color3.fromRGB(50, 140, 160) then
					catTab.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
				end
			end)
		end
	end
end

-- Populate weapon list based on category
function MenuGenerator:PopulateWeaponList(weaponList, category)
	-- Clear existing weapons (except title and layout)
	for _, child in pairs(weaponList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Get weapons from WeaponConfig
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

	local weaponList_weapons = {}
	local allWeapons = WeaponConfig:GetAllConfigs()

	-- Filter weapons by category
	for weaponName, weaponData in pairs(allWeapons) do
		if weaponData.Category == category then
			table.insert(weaponList_weapons, weaponName)
		end
	end

	-- Sort alphabetically
	table.sort(weaponList_weapons)

	for i, weaponName in ipairs(weaponList_weapons) do
		local weaponBtn = Instance.new("TextButton")
		weaponBtn.Name = weaponName .. "Button"
		weaponBtn.Size = UDim2.new(1, 0, 0, 40)
		weaponBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 55)
		weaponBtn.BorderSizePixel = 0
		weaponBtn.Text = weaponName:upper()
		weaponBtn.TextColor3 = COLORS.Text
		weaponBtn.Font = Enum.Font.Gotham
		weaponBtn.TextSize = 13
		weaponBtn.TextXAlignment = Enum.TextXAlignment.Left
		weaponBtn.AutoButtonColor = false
		weaponBtn.LayoutOrder = i
		weaponBtn.Parent = weaponList

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = weaponBtn

		-- Add padding for left-aligned text
		local weaponBtnPadding = Instance.new("UIPadding")
		weaponBtnPadding.PaddingLeft = UDim.new(0, 10)
		weaponBtnPadding.Parent = weaponBtn

		-- Click handler
		weaponBtn.MouseButton1Click:Connect(function()
			-- Update all weapon buttons
			for _, btn in pairs(weaponList:GetChildren()) do
				if btn:IsA("TextButton") then
					btn.BackgroundColor3 = Color3.fromRGB(35, 45, 55)
				end
			end
			weaponBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 140)

			-- Update preview
			local preview = weaponList.Parent:FindFirstChild("WeaponPreview")
			if preview then
				local nameLabel = preview:FindFirstChild("WeaponName")
				if nameLabel then
					nameLabel.Text = weaponName:upper()
					nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				end

				-- Update 3D model
				self:UpdateWeaponModel(preview:FindFirstChild("WeaponViewport"), weaponName)
			end

			-- Update stats panel
			self:UpdateWeaponStats(weaponList.Parent:FindFirstChild("WeaponStats"), weaponName)
		end)

		-- Hover effects
		weaponBtn.MouseEnter:Connect(function()
			if weaponBtn.BackgroundColor3 ~= Color3.fromRGB(50, 120, 140) then
				weaponBtn.BackgroundColor3 = Color3.fromRGB(45, 60, 70)
			end
		end)

		weaponBtn.MouseLeave:Connect(function()
			if weaponBtn.BackgroundColor3 ~= Color3.fromRGB(50, 120, 140) then
				weaponBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 55)
			end
		end)
	end

	-- Update canvas size
	weaponList.CanvasSize = UDim2.new(0, 0, 0, #weaponList_weapons * 43 + 55)
end

-- Update weapon model in viewport
function MenuGenerator:UpdateWeaponModel(viewportFrame, weaponName)
	if not viewportFrame then return end

	-- Clear existing model
	for _, child in pairs(viewportFrame:GetChildren()) do
		if child:IsA("Model") then
			child:Destroy()
		end
	end

	-- Hide placeholder
	local placeholder = viewportFrame:FindFirstChild("PlaceholderText")
	if placeholder then
		placeholder.Visible = false
	end

	-- Get weapon config to find model path
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
	local weaponData = WeaponConfig:GetWeaponConfig(weaponName)

	if not weaponData then
		if placeholder then placeholder.Visible = true end
		return
	end

	-- Build path to weapon model
	local modelPath = ReplicatedStorage.FPSSystem:FindFirstChild("WeaponModels")
	if not modelPath then
		warn("WeaponModels folder not found")
		if placeholder then placeholder.Visible = true end
		return
	end

	-- Navigate through category and type
	local categoryFolder = modelPath:FindFirstChild(weaponData.Category)
	if not categoryFolder then
		warn("Category folder not found:", weaponData.Category)
		if placeholder then placeholder.Visible = true end
		return
	end

	local typeFolder = categoryFolder:FindFirstChild(weaponData.Type)
	if not typeFolder then
		warn("Type folder not found:", weaponData.Type)
		if placeholder then placeholder.Visible = true end
		return
	end

	-- Find weapon model
	local weaponModel = typeFolder:FindFirstChild(weaponName)
	if not weaponModel then
		warn("Weapon model not found:", weaponName)
		if placeholder then placeholder.Visible = true end
		return
	end

	-- Clone model into viewport
	local modelClone = weaponModel:Clone()
	modelClone.Parent = viewportFrame

	-- Position camera to view the model
	local camera = viewportFrame.CurrentCamera
	if camera and modelClone:IsA("Model") then
		-- Calculate model size and center
		local modelCFrame, modelSize = modelClone:GetBoundingBox()

		-- Position camera
		local distance = math.max(modelSize.X, modelSize.Y, modelSize.Z) * 2
		camera.CFrame = CFrame.new(modelCFrame.Position + Vector3.new(distance * 0.7, distance * 0.3, distance * 0.7), modelCFrame.Position)

		-- Rotate model slowly
		local RunService = game:GetService("RunService")
		local connection
		connection = RunService.RenderStepped:Connect(function(dt)
			if not modelClone.Parent then
				connection:Disconnect()
				return
			end
			modelClone:PivotTo(modelClone:GetPivot() * CFrame.Angles(0, math.rad(30 * dt), 0))
		end)
	end
end

-- Update weapon stats display
function MenuGenerator:UpdateWeaponStats(statsPanel, weaponName)
	if not statsPanel then return end

	-- Get weapon config
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
	local weaponData = WeaponConfig:GetWeaponConfig(weaponName)

	if not weaponData then return end

	-- Clear existing stats
	for _, child in pairs(statsPanel:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("Stat") then
			child:Destroy()
		end
	end

	-- Create stat display function
	local function createStat(name, value, order)
		local statFrame = Instance.new("Frame")
		statFrame.Name = name .. "Stat"
		statFrame.Size = UDim2.new(1, 0, 0, 25)
		statFrame.BackgroundTransparency = 1
		statFrame.LayoutOrder = order
		statFrame.Parent = statsPanel

		local statName = Instance.new("TextLabel")
		statName.Name = "StatName"
		statName.Size = UDim2.new(0.5, -5, 1, 0)
		statName.Position = UDim2.new(0, 0, 0, 0)
		statName.BackgroundTransparency = 1
		statName.Text = name
		statName.TextColor3 = COLORS.TextDim
		statName.Font = Enum.Font.Gotham
		statName.TextSize = 12
		statName.TextXAlignment = Enum.TextXAlignment.Left
		statName.Parent = statFrame

		local statValue = Instance.new("TextLabel")
		statValue.Name = "StatValue"
		statValue.Size = UDim2.new(0.5, -5, 1, 0)
		statValue.Position = UDim2.new(0.5, 5, 0, 0)
		statValue.BackgroundTransparency = 1
		statValue.Text = tostring(value)
		statValue.TextColor3 = COLORS.Text
		statValue.Font = Enum.Font.GothamBold
		statValue.TextSize = 12
		statValue.TextXAlignment = Enum.TextXAlignment.Right
		statValue.Parent = statFrame

		return statFrame
	end

	-- Display relevant stats
	local order = 1
	if weaponData.Damage then
		createStat("Damage", weaponData.Damage, order)
		order = order + 1
	end
	if weaponData.FireRate then
		createStat("Fire Rate", weaponData.FireRate .. " RPM", order)
		order = order + 1
	end
	if weaponData.Range then
		createStat("Range", weaponData.Range .. " studs", order)
		order = order + 1
	end
	if weaponData.MaxAmmo then
		createStat("Magazine", weaponData.MaxAmmo, order)
		order = order + 1
	end
	if weaponData.MaxReserveAmmo then
		createStat("Reserve Ammo", weaponData.MaxReserveAmmo, order)
		order = order + 1
	end
	if weaponData.ReloadTime then
		createStat("Reload Time", weaponData.ReloadTime .. "s", order)
		order = order + 1
	end
	if weaponData.Penetration then
		createStat("Penetration", weaponData.Penetration, order)
		order = order + 1
	end
	if weaponData.BulletVelocity then
		createStat("Velocity", weaponData.BulletVelocity .. " m/s", order)
		order = order + 1
	end

	-- Update canvas size
	statsPanel.CanvasSize = UDim2.new(0, 0, 0, order * 30 + 50)
end

-- Create placeholder section
function MenuGenerator:CreatePlaceholderSection(parent, name)
	local section = Instance.new("Frame")
	section.Name = name .. "Section"
	section.Size = UDim2.new(1, 0, 1, 0)
	section.BackgroundTransparency = 1
	section.Visible = false
	section.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 400, 0, 100)
	label.Position = UDim2.new(0.5, -200, 0.5, -50)
	label.BackgroundTransparency = 1
	label.Text = name:upper() .. "\n(Coming Soon)"
	label.TextColor3 = COLORS.TextDim
	label.Font = Enum.Font.GothamBold
	label.TextSize = 32
	label.Parent = section

	return section
end

-- Setup sidebar navigation
function MenuGenerator:SetupNavigation(sidebar, contentArea)
	-- Get all existing buttons from sidebar
	local buttons = {}
	for _, child in pairs(sidebar:GetChildren()) do
		if child:IsA("TextButton") then
			table.insert(buttons, child)
		end
	end

	-- Get all existing sections from contentArea
	local sections = {}
	for _, child in pairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ScrollingFrame") then
			if child.Name:match("Section$") then
				sections[child.Name:gsub("Section", "")] = child
			end
		end
	end

	-- Connect each button to show its section
	for _, button in pairs(buttons) do
		button.MouseButton1Click:Connect(function()
			-- Update button states
			for _, btn in pairs(buttons) do
				local indicator = btn:FindFirstChild("ActiveIndicator")
				if btn == button then
					btn.BackgroundColor3 = COLORS.ButtonActive
					if indicator then indicator.Visible = true end
				else
					btn.BackgroundColor3 = COLORS.ButtonInactive
					if indicator then indicator.Visible = false end
				end
			end

			-- Show corresponding section
			local sectionName = button.Name:gsub("Button", "")
			for name, section in pairs(sections) do
				section.Visible = (name == sectionName)
			end
		end)

		-- Hover effects
		button.MouseEnter:Connect(function()
			local indicator = button:FindFirstChild("ActiveIndicator")
			if not indicator or not indicator.Visible then
				button.BackgroundColor3 = COLORS.ButtonHover
			end
		end)

		button.MouseLeave:Connect(function()
			local indicator = button:FindFirstChild("ActiveIndicator")
			if not indicator or not indicator.Visible then
				button.BackgroundColor3 = COLORS.ButtonInactive
			end
		end)
	end

	print("✓ Connected", #buttons, "sidebar buttons to", #sections, "sections")
end

-- Setup ViewportFrame character animation
function MenuGenerator:SetupViewportCharacter(screenGui)
	-- Look for ViewportFrame in multiple possible locations
	-- Priority: ContentArea > DeploySection > anywhere in screenGui
	local mainContainer = screenGui:FindFirstChild("MainContainer")
	local contentArea = mainContainer and mainContainer:FindFirstChild("ContentArea")
	local deploySection = contentArea and contentArea:FindFirstChild("DeploySection")

	local viewportFrame = nil

	-- Try to find ViewportFrame in order of priority
	if deploySection then
		viewportFrame = deploySection:FindFirstChild("ViewportFrame", true)
	end

	if not viewportFrame and contentArea then
		viewportFrame = contentArea:FindFirstChild("ViewportFrame", true)
	end

	if not viewportFrame then
		viewportFrame = screenGui:FindFirstChild("ViewportFrame", true)
	end

	if not viewportFrame then
		print("⚠ ViewportFrame not found in menu (searched DeploySection, ContentArea, and ScreenGui)")
		return
	end

	print("✓ Found ViewportFrame at:", viewportFrame:GetFullName())

	-- CRITICAL FIX: Remove any UI elements that don't belong in ViewportFrame
	-- ViewportFrame should ONLY contain: Camera and R6 character model
	for _, child in pairs(viewportFrame:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") or child:IsA("ImageLabel") then
			warn("⚠ Removing misplaced UI element from ViewportFrame:", child.Name)

			-- Try to move it to DeploySection if it belongs there
			if deploySection and (child.Name == "DeployButton" or child.Name == "GameTitle" or child.Name == "Hint" or child.Name == "MenuTitle") then
				print("  → Moving", child.Name, "to DeploySection")
				child.Parent = deploySection
			else
				print("  → Destroying", child.Name)
				child:Destroy()
			end
		end
	end

    -- Find the R6 character model (could be named Background, R6, or just Model)
    local characterModel = viewportFrame:FindFirstChild("Background")
        or viewportFrame:FindFirstChild("R6")
        or viewportFrame:FindFirstChild("KFC")
        or viewportFrame:FindFirstChildWhichIsA("Model")

	if not characterModel then
		print("⚠ Character model not found in ViewportFrame")
		return
	end

	print("✓ Found character model:", characterModel.Name)

	-- Find humanoid
	local humanoid = characterModel:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		print("⚠ Humanoid not found in character model")
		return
	end

    -- Ensure any prop/desk under the character is visible
    local desk = viewportFrame:FindFirstChild("Desk") or viewportFrame:FindFirstChild("WoodenDesk") or viewportFrame:FindFirstChild("Table")
    if desk and desk:IsA("Model") then
        for _, part in ipairs(desk:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.CanCollide = false
            end
        end
    end

    -- Setup camera for viewport
	local camera = viewportFrame:FindFirstChildOfClass("Camera")
	if not camera then
		camera = Instance.new("Camera")
		camera.Parent = viewportFrame
	end
	viewportFrame.CurrentCamera = camera

	-- Position camera to view the character
    local rootPart = characterModel:FindFirstChild("HumanoidRootPart") or characterModel:FindFirstChild("Torso")
    if rootPart then
        -- Try to frame both character and desk by using bounding box when possible
        local cf, size = characterModel:GetBoundingBox()
        if desk and desk:IsA("Model") then
            local dcf, dsize = desk:GetBoundingBox()
            local minPos = Vector3.new(
                math.min(cf.Position.X, dcf.Position.X),
                math.min(cf.Position.Y, dcf.Position.Y),
                math.min(cf.Position.Z, dcf.Position.Z)
            )
            local maxPos = Vector3.new(
                math.max(cf.Position.X, dcf.Position.X),
                math.max(cf.Position.Y, dcf.Position.Y),
                math.max(cf.Position.Z, dcf.Position.Z)
            )
            local center = (minPos + maxPos) * 0.5
            local extents = (maxPos - minPos)
            local dist = math.max(extents.X, extents.Y, extents.Z) * 1.8
            camera.CFrame = CFrame.new(center + Vector3.new(0, extents.Y * 0.2, dist), center)
        else
            camera.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 1, 5), rootPart.Position + Vector3.new(0, 1, 0))
        end
    end

	-- Find and play idle animation
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Look for animation in the model
	local animSaves = characterModel:FindFirstChild("AnimSaves")
	local idleAnim = animSaves and animSaves:FindFirstChildOfClass("Animation")

	if not idleAnim then
		-- Try to find any Animation instance in the model
		idleAnim = characterModel:FindFirstChild("Animation", true)
	end

	if idleAnim then
		local animTrack = animator:LoadAnimation(idleAnim)
		animTrack.Looped = true
		animTrack:Play()
		print("✓ Playing idle animation in ViewportFrame")
	else
		print("⚠ No idle animation found for character")
	end

	-- Slowly rotate the character for visual effect
	local RunService = game:GetService("RunService")
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not characterModel.Parent or not screenGui.Parent then
			connection:Disconnect()
			return
		end

		if rootPart and rootPart.Parent then
			-- Slowly rotate character
			rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(15 * dt), 0)
		end
	end)

	print("✓ ViewportFrame character setup complete")
end

-- Generate complete menu
function MenuGenerator:Generate()
	print("Generating Phantom Forces style menu...")

	local screenGui = self:CreateScreenGui()
	local mainContainer = self:CreateMainContainer(screenGui)
	local sidebar = self:CreateSidebar(mainContainer)
	local contentArea = self:CreateContentArea(mainContainer)

	-- Check if RBXM already has buttons - if so, DON'T create new ones
	local existingButtons = {}
	for _, child in pairs(sidebar:GetChildren()) do
		if child:IsA("TextButton") then
			table.insert(existingButtons, child)
		end
	end

	if #existingButtons == 0 then
		-- No existing buttons, create them
		print("⚠ No existing sidebar buttons found, creating new ones...")
		local menuItems = {
			{Name = "Deploy", Y = 70},
			{Name = "Loadout", Y = 120},
			{Name = "Leaderboard", Y = 170},
			{Name = "Settings", Y = 220},
			{Name = "Shop", Y = 270}
		}

		for i, item in ipairs(menuItems) do
			self:CreateSidebarButton(
				sidebar,
				item.Name,
				UDim2.new(0, 5, 0, item.Y),
				i == 1
			)
		end
	else
		print("✓ Found", #existingButtons, "existing sidebar buttons in RBXM, using them")
	end

	-- Check if sections already exist in RBXM
	local existingSections = {
		Deploy = contentArea:FindFirstChild("DeploySection"),
		Loadout = contentArea:FindFirstChild("LoadoutSection"),
		Shop = contentArea:FindFirstChild("ShopSection"),
		Settings = contentArea:FindFirstChild("SettingsSection"),
		Leaderboard = contentArea:FindFirstChild("LeaderboardSection")
	}

	-- Only create sections that don't exist
	if not existingSections.Deploy then
		print("⚠ Creating DeploySection...")
		existingSections.Deploy = self:CreateDeploySection(contentArea)
	else
		print("✓ Found existing DeploySection")
	end

	if not existingSections.Loadout then
		print("⚠ Creating LoadoutSection...")
		existingSections.Loadout = self:CreateCustomizeSection(contentArea)
	else
		print("✓ Found existing LoadoutSection")
	end

	if not existingSections.Shop then
		print("⚠ Creating ShopSection...")
		existingSections.Shop = MenuSections:CreateShopSection(contentArea)
	else
		print("✓ Found existing ShopSection")
	end

	if not existingSections.Settings then
		print("⚠ Creating SettingsSection...")
		existingSections.Settings = MenuSections:CreateSettingsSection(contentArea)
	else
		print("✓ Found existing SettingsSection")
	end

	if not existingSections.Leaderboard then
		print("⚠ Creating LeaderboardSection...")
		existingSections.Leaderboard = MenuSections:CreateLeaderboardSection(contentArea)
	else
		print("✓ Found existing LeaderboardSection")
	end

	-- Setup navigation (pass contentArea instead of sections array)
	self:SetupNavigation(sidebar, contentArea)

	-- Setup viewport frame character animation
	self:SetupViewportCharacter(screenGui)

	print("✓ Phantom Forces style menu generated")
	return screenGui
end

-- Initialize
MenuGenerator:Generate()

return MenuGenerator
