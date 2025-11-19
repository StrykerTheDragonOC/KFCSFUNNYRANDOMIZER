--[[
	Match Timer HUD
	Displays the current match timer, gamemode, and team scores at the top-center of screen
	Battlefield 2042-inspired design
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents

local MatchTimerHUD = {}

-- HUD Elements
local timerGui = nil
local timerLabel = nil
local gamemodeLabel = nil
local fbiScoreLabel = nil
local kfcScoreLabel = nil

-- State
local currentTimeLeft = 600 -- Default 10 minutes
local currentGamemode = "TDM"
local fbiScore = 0
local kfcScore = 0

-- Colors
local PRIMARY_COLOR = Color3.fromRGB(0, 255, 230) -- Cyan
local TEXT_COLOR = Color3.fromRGB(200, 255, 245)
local BACKGROUND_COLOR = Color3.fromRGB(10, 15, 20)

function MatchTimerHUD:CreateHUD()
	-- Create ScreenGui
	timerGui = Instance.new("ScreenGui")
	timerGui.Name = "MatchTimerHUD"
	timerGui.ResetOnSpawn = false
	timerGui.DisplayOrder = 10
	timerGui.IgnoreGuiInset = true
	timerGui.Enabled = false -- Start hidden (show when deployed)
	timerGui.Parent = playerGui

	-- Main container (top-center)
	local container = Instance.new("Frame")
	container.Name = "TimerContainer"
	container.Size = UDim2.new(0, 450, 0, 80)
	container.Position = UDim2.new(0.5, -225, 0, 20)
	container.BackgroundColor3 = BACKGROUND_COLOR
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = timerGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 8)
	containerCorner.Parent = container

	-- FBI Score (left side)
	fbiScoreLabel = Instance.new("TextLabel")
	fbiScoreLabel.Name = "FBIScore"
	fbiScoreLabel.Size = UDim2.new(0, 100, 0, 40)
	fbiScoreLabel.Position = UDim2.new(0, 10, 0, 10)
	fbiScoreLabel.BackgroundTransparency = 1
	fbiScoreLabel.Text = "FBI: 0"
	fbiScoreLabel.TextColor3 = Color3.fromRGB(100, 150, 255) -- Blue
	fbiScoreLabel.Font = Enum.Font.GothamBold
	fbiScoreLabel.TextSize = 20
	fbiScoreLabel.TextXAlignment = Enum.TextXAlignment.Left
	fbiScoreLabel.TextStrokeTransparency = 0.5
	fbiScoreLabel.Parent = container

	-- KFC Score (right side)
	kfcScoreLabel = Instance.new("TextLabel")
	kfcScoreLabel.Name = "KFCScore"
	kfcScoreLabel.Size = UDim2.new(0, 100, 0, 40)
	kfcScoreLabel.Position = UDim2.new(1, -110, 0, 10)
	kfcScoreLabel.BackgroundTransparency = 1
	kfcScoreLabel.Text = "KFC: 0"
	kfcScoreLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red
	kfcScoreLabel.Font = Enum.Font.GothamBold
	kfcScoreLabel.TextSize = 20
	kfcScoreLabel.TextXAlignment = Enum.TextXAlignment.Right
	kfcScoreLabel.TextStrokeTransparency = 0.5
	kfcScoreLabel.Parent = container

	-- Timer Label (center, large)
	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(0, 150, 0, 45)
	timerLabel.Position = UDim2.new(0.5, -75, 0, 5)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "10:00"
	timerLabel.TextColor3 = PRIMARY_COLOR
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.TextSize = 36
	timerLabel.TextStrokeTransparency = 0.4
	timerLabel.Parent = container

	-- Gamemode Label (center, below timer)
	gamemodeLabel = Instance.new("TextLabel")
	gamemodeLabel.Name = "GamemodeLabel"
	gamemodeLabel.Size = UDim2.new(0, 200, 0, 25)
	gamemodeLabel.Position = UDim2.new(0.5, -100, 0, 50)
	gamemodeLabel.BackgroundTransparency = 1
	gamemodeLabel.Text = "TDM"
	gamemodeLabel.TextColor3 = TEXT_COLOR
	gamemodeLabel.Font = Enum.Font.Gotham
	gamemodeLabel.TextSize = 14
	gamemodeLabel.TextStrokeTransparency = 0.6
	gamemodeLabel.Parent = container

	print("MatchTimerHUD created")
end

function MatchTimerHUD:UpdateTimer(timeLeft)
	if not timerLabel then return end

	currentTimeLeft = timeLeft or 0
	local minutes = math.floor(currentTimeLeft / 60)
	local seconds = currentTimeLeft % 60

	timerLabel.Text = string.format("%d:%02d", minutes, seconds)

	-- Change color based on time remaining
	if currentTimeLeft <= 60 then
		-- Last minute - red
		timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	elseif currentTimeLeft <= 120 then
		-- Last 2 minutes - yellow
		timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	else
		-- Normal - cyan
		timerLabel.TextColor3 = PRIMARY_COLOR
	end
end

function MatchTimerHUD:UpdateGamemode(gamemode)
	if not gamemodeLabel then return end

	currentGamemode = gamemode or "TDM"

	-- Map gamemode codes to display names
	local gamemodeNames = {
		TDM = "Team Deathmatch",
		KOTH = "King of the Hill",
		KC = "Kill Confirmed",
		CTF = "Capture the Flag",
		FD = "Flare Domination",
		HD = "Hardpoint",
		GG = "Gun Game",
		DUEL = "Duel",
		KNIFE = "Knife Fight"
	}

	gamemodeLabel.Text = gamemodeNames[currentGamemode] or currentGamemode
end

function MatchTimerHUD:UpdateScores(fbi, kfc)
	if fbiScoreLabel then
		fbiScore = fbi or 0
		fbiScoreLabel.Text = string.format("FBI: %d", fbiScore)
	end

	if kfcScoreLabel then
		kfcScore = kfc or 0
		kfcScoreLabel.Text = string.format("KFC: %d", kfcScore)
	end
end

function MatchTimerHUD:Show()
	if timerGui then
		timerGui.Enabled = true
	end
end

function MatchTimerHUD:Hide()
	if timerGui then
		timerGui.Enabled = false
	end
end

function MatchTimerHUD:Initialize()
	-- Create the HUD
	self:CreateHUD()

	-- Listen for timer updates from server
	local timerUpdateEvent = RemoteEvents:FindFirstChild("TimerUpdate")
	if timerUpdateEvent then
		timerUpdateEvent.OnClientEvent:Connect(function(data)
			if data then
				self:UpdateTimer(data.TimeLeft)
				self:UpdateGamemode(data.Gamemode)
			end
		end)
	else
		warn("TimerUpdate RemoteEvent not found")
	end

	-- Listen for score updates
	local scoreUpdateEvent = RemoteEvents:FindFirstChild("TeamScoreUpdated")
	if scoreUpdateEvent then
		scoreUpdateEvent.OnClientEvent:Connect(function(teamName, newScore)
			if teamName == "FBI" then
				self:UpdateScores(newScore, kfcScore)
			elseif teamName == "KFC" then
				self:UpdateScores(fbiScore, newScore)
			end
		end)
	end

	-- Listen for match started event
	local matchStartedEvent = RemoteEvents:FindFirstChild("MatchStarted")
	if matchStartedEvent then
		matchStartedEvent.OnClientEvent:Connect(function(data)
			if data then
				self:UpdateGamemode(data.Gamemode)
				self:Show()
				print("Match started - showing timer HUD")
			end
		end)
	end

	-- Listen for returned to lobby event
	local returnedToLobbyEvent = RemoteEvents:FindFirstChild("ReturnedToLobby")
	if returnedToLobbyEvent then
		returnedToLobbyEvent.OnClientEvent:Connect(function()
			self:Hide()
			print("Returned to lobby - hiding timer HUD")
		end)
	end

	-- Show/hide based on deployment state
	local function updateVisibility()
		local isDeployed = player.Team and player.Team.Name ~= "Lobby"
		if isDeployed then
			self:Show()
		else
			self:Hide()
		end
	end

	-- Listen for team changes
	player:GetPropertyChangedSignal("Team"):Connect(updateVisibility)

	-- Initial check
	updateVisibility()

	-- Backup: Poll MatchStatusHandler every second for timer if RemoteEvent doesn't work
	spawn(function()
		while true do
			task.wait(1)

			-- Only poll if HUD is visible
			if timerGui and timerGui.Enabled then
				-- Try to get time from MatchStatusHandler
				local getMatchStatusFunc = RemoteEvents:FindFirstChild("GetMatchStatus")
				if getMatchStatusFunc and getMatchStatusFunc:IsA("RemoteFunction") then
					local success, matchData = pcall(function()
						return getMatchStatusFunc:InvokeServer()
					end)

					if success and matchData then
						self:UpdateTimer(matchData.timeRemaining)
						self:UpdateGamemode(matchData.currentGamemode)
						self:UpdateScores(matchData.teamScores.FBI, matchData.teamScores.KFC)
					end
				end
			end
		end
	end)

	print("MatchTimerHUD initialized")
end

-- Initialize
MatchTimerHUD:Initialize()

-- Expose globally for other scripts
_G.MatchTimerHUD = MatchTimerHUD

return MatchTimerHUD
