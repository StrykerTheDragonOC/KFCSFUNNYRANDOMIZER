--[[
	Scoreboard Controller
	Shows player stats when Tab is pressed
	Displays: Rank, Kills, Deaths, KDR, Streak, Score by team
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ScoreboardController = {}

-- Scoreboard GUI
local scoreboardGui = nil
local isVisible = false

function ScoreboardController:Initialize()
	-- Hide default Roblox playerlist
	local StarterGui = game:GetService("StarterGui")
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

	-- Create scoreboard GUI
	self:CreateScoreboardGUI()

	-- Setup input handling
	self:SetupInputHandling()

	-- Update scoreboard periodically
	spawn(function()
		while true do
			task.wait(1)
			if isVisible then
				self:UpdateScoreboard()
			end
		end
	end)

	print("ScoreboardController initialized")
end

function ScoreboardController:CreateScoreboardGUI()
	scoreboardGui = Instance.new("ScreenGui")
	scoreboardGui.Name = "FPSScoreboard"
	scoreboardGui.Enabled = false
	scoreboardGui.ResetOnSpawn = false
	scoreboardGui.DisplayOrder = 100
	scoreboardGui.Parent = playerGui

	-- Background frame
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(0, 800, 0, 500)
	background.Position = UDim2.new(0.5, -400, 0.5, -250)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	background.BackgroundTransparency = 0.1
	background.BorderSizePixel = 0
	background.Parent = scoreboardGui

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 8)
	bgCorner.Parent = background

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "SCOREBOARD"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 28
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = background

	-- Gamemode label
	local gamemodeLabel = Instance.new("TextLabel")
	gamemodeLabel.Name = "GamemodeLabel"
	gamemodeLabel.Size = UDim2.new(0, 200, 0, 30)
	gamemodeLabel.Position = UDim2.new(1, -220, 0, 20)
	gamemodeLabel.BackgroundTransparency = 1
	gamemodeLabel.Text = "Team Deathmatch"
	gamemodeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	gamemodeLabel.Font = Enum.Font.Gotham
	gamemodeLabel.TextSize = 16
	gamemodeLabel.TextXAlignment = Enum.TextXAlignment.Right
	gamemodeLabel.Parent = background

	-- Scrolling frame for players
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PlayerList"
	scrollFrame.Size = UDim2.new(1, -40, 1, -80)
	scrollFrame.Position = UDim2.new(0, 20, 0, 60)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = background

	-- List layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Update canvas size when children change
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

function ScoreboardController:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Tab then
			self:ToggleScoreboard(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Tab then
			self:ToggleScoreboard(false)
		end
	end)
end

function ScoreboardController:ToggleScoreboard(show)
	isVisible = show
	scoreboardGui.Enabled = show

	if show then
		self:UpdateScoreboard()
	end
end

function ScoreboardController:UpdateScoreboard()
	if not scoreboardGui then return end

	local scrollFrame = scoreboardGui.Background.PlayerList

	-- Clear existing entries
	for _, child in pairs(scrollFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Get all players sorted by team
	local teams = game:GetService("Teams"):GetChildren()

	for _, team in ipairs(teams) do
		-- Skip Lobby team
		if team.Name ~= "Lobby" then
			-- Team header
			local teamHeader = self:CreateTeamHeader(team)
			teamHeader.Parent = scrollFrame

			-- Get players on this team
			local teamPlayers = {}
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Team == team then
					table.insert(teamPlayers, plr)
				end
			end

			-- Sort by score (you can add score attribute later)
			table.sort(teamPlayers, function(a, b)
				local scoreA = a:GetAttribute("Score") or 0
				local scoreB = b:GetAttribute("Score") or 0
				return scoreA > scoreB
			end)

			-- Create player entries
			for _, plr in ipairs(teamPlayers) do
				local playerEntry = self:CreatePlayerEntry(plr)
				playerEntry.Parent = scrollFrame
			end
		end
	end
end

function ScoreboardController:CreateTeamHeader(team)
	local header = Instance.new("Frame")
	header.Name = "TeamHeader_" .. team.Name
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundColor3 = team.TeamColor.Color
	header.BackgroundTransparency = 0.7
	header.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = header

	local teamLabel = Instance.new("TextLabel")
	teamLabel.Size = UDim2.new(0.5, -10, 1, 0)
	teamLabel.Position = UDim2.new(0, 10, 0, 0)
	teamLabel.BackgroundTransparency = 1
	teamLabel.Text = team.Name
	teamLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamLabel.Font = Enum.Font.GothamBold
	teamLabel.TextSize = 20
	teamLabel.TextXAlignment = Enum.TextXAlignment.Left
	teamLabel.Parent = header

	-- Team score (placeholder)
	local teamScore = Instance.new("TextLabel")
	teamScore.Size = UDim2.new(0.5, -10, 1, 0)
	teamScore.Position = UDim2.new(0.5, 0, 0, 0)
	teamScore.BackgroundTransparency = 1
	teamScore.Text = "Score: 0"
	teamScore.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamScore.Font = Enum.Font.GothamBold
	teamScore.TextSize = 18
	teamScore.TextXAlignment = Enum.TextXAlignment.Right
	teamScore.Parent = header

	return header
end

function ScoreboardController:CreatePlayerEntry(plr)
	local entry = Instance.new("Frame")
	entry.Name = "PlayerEntry_" .. plr.Name
	entry.Size = UDim2.new(1, 0, 0, 35)
	entry.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
	entry.BackgroundTransparency = 0.3
	entry.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = entry

	-- Get player stats
	local rank = plr:GetAttribute("Level") or 0
	local kills = plr:GetAttribute("Kills") or 0
	local deaths = plr:GetAttribute("Deaths") or 0
	local kdr = deaths > 0 and math.floor((kills / deaths) * 100) / 100 or kills
	local streak = plr:GetAttribute("KillStreak") or 0
	local score = plr:GetAttribute("Score") or 0

	-- Rank
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0, 50, 1, 0)
	rankLabel.Position = UDim2.new(0, 5, 0, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = tostring(rank)
	rankLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextSize = 16
	rankLabel.Parent = entry

	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 180, 1, 0)
	nameLabel.Position = UDim2.new(0, 60, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = plr.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = entry

	-- Kills
	local killsLabel = Instance.new("TextLabel")
	killsLabel.Size = UDim2.new(0, 60, 1, 0)
	killsLabel.Position = UDim2.new(0, 250, 0, 0)
	killsLabel.BackgroundTransparency = 1
	killsLabel.Text = "K: " .. kills
	killsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	killsLabel.Font = Enum.Font.Gotham
	killsLabel.TextSize = 14
	killsLabel.Parent = entry

	-- Deaths
	local deathsLabel = Instance.new("TextLabel")
	deathsLabel.Size = UDim2.new(0, 60, 1, 0)
	deathsLabel.Position = UDim2.new(0, 320, 0, 0)
	deathsLabel.BackgroundTransparency = 1
	deathsLabel.Text = "D: " .. deaths
	deathsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	deathsLabel.Font = Enum.Font.Gotham
	deathsLabel.TextSize = 14
	deathsLabel.Parent = entry

	-- KDR
	local kdrLabel = Instance.new("TextLabel")
	kdrLabel.Size = UDim2.new(0, 70, 1, 0)
	kdrLabel.Position = UDim2.new(0, 390, 0, 0)
	kdrLabel.BackgroundTransparency = 1
	kdrLabel.Text = "KDR: " .. kdr
	kdrLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	kdrLabel.Font = Enum.Font.Gotham
	kdrLabel.TextSize = 14
	kdrLabel.Parent = entry

	-- Streak
	local streakLabel = Instance.new("TextLabel")
	streakLabel.Size = UDim2.new(0, 70, 1, 0)
	streakLabel.Position = UDim2.new(0, 470, 0, 0)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = "STR: " .. streak
	streakLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	streakLabel.Font = Enum.Font.Gotham
	streakLabel.TextSize = 14
	streakLabel.Parent = entry

	-- Score
	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Size = UDim2.new(0, 100, 1, 0)
	scoreLabel.Position = UDim2.new(0, 550, 0, 0)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text = "Score: " .. score
	scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	scoreLabel.Font = Enum.Font.GothamBold
	scoreLabel.TextSize = 14
	scoreLabel.Parent = entry

	-- Highlight local player
	if plr == player then
		entry.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
		entry.BackgroundTransparency = 0.2
	end

	return entry
end

-- DISABLED: Use TabScoreboard.client.lua instead (bigger, more feature-rich leaderboard)
-- ScoreboardController:Initialize()

print("⚠ ScoreboardController disabled - using TabScoreboard instead")

return ScoreboardController
