--[[
	Radar Controller
	Top-left minimap showing:
	- Player position and rotation
	- Enemy positions when they fire (unsuppressed) or throw grenades
	- Expanding wave effect for gunshots
	- Gamemode and score display
	- Suppressor detection ranges
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponFiredEvent = RemoteEvents:WaitForChild("WeaponFired")
local GrenadeExplodedEvent = RemoteEvents:FindFirstChild("GrenadeExploded")

local RadarController = {}

-- Radar settings
local RADAR_SIZE = 200  -- Pixel size of radar
local RADAR_RANGE = 300  -- Studs radius shown on radar
local DETECTION_DURATION = 3  -- Seconds enemies stay visible
local WAVE_DURATION = 1.5  -- Seconds wave animation lasts

-- Suppressor detection ranges (studs)
local SUPPRESSOR_RANGES = {
	None = 999999,  -- No suppressor = shows on radar globally
	Standard = 150,  -- Standard suppressor = 150 stud detection
	Heavy = 100,  -- Heavy suppressor = 100 stud detection
	Subsonic = 50  -- Subsonic suppressor = 50 stud detection
}

-- Radar UI
local radarGui = nil
local radarFrame = nil
local playerDot = nil
local detectedEnemies = {}  -- {player = {dot, expireTime}}
local activeWaves = {}

function RadarController:Initialize()
	-- Create radar GUI
	self:CreateRadarGUI()
	
	-- Hide radar by default (only show when deployed)
	if radarGui then
		radarGui.Enabled = false
	end

	-- Listen for weapon fire events
	WeaponFiredEvent.OnClientEvent:Connect(function(shooter, shotData)
		if shooter and shooter ~= player then
			self:DetectGunfire(shooter, shotData)
		end
	end)

	-- Listen for grenade explosions
	if GrenadeExplodedEvent then
		GrenadeExplodedEvent.OnClientEvent:Connect(function(thrower, position)
			if thrower and thrower ~= player then
				self:DetectGrenadeExplosion(thrower, position)
			end
		end)
	end

	-- Update radar every frame
	RunService.RenderStepped:Connect(function()
		self:UpdateRadar()
	end)

	-- Update score display
	spawn(function()
		while true do
			task.wait(1)
			self:UpdateScoreDisplay()
		end
	end)

	-- Show/hide based on deployment state
	local function updateRadarVisibility()
		if radarGui then
			local isDeployed = player.Team and player.Team.Name ~= "Lobby"
			radarGui.Enabled = isDeployed
			print("Radar visibility updated:", radarGui.Enabled, "Team:", player.Team and player.Team.Name or "nil")
		end
	end

	-- Initial check
	updateRadarVisibility()

	-- Listen for team changes
	player:GetPropertyChangedSignal("Team"):Connect(updateRadarVisibility)

	-- Also update when character spawns (in case team was set before radar initialized)
	player.CharacterAdded:Connect(function()
		task.wait(0.5) -- Wait for team to be fully set
		updateRadarVisibility()
	end)

	-- If character already exists, check visibility
	if player.Character then
		task.wait(0.5)
		updateRadarVisibility()
	end

	print("RadarController initialized")
end

function RadarController:CreateRadarGUI()
	radarGui = Instance.new("ScreenGui")
	radarGui.Name = "RadarUI"
	radarGui.ResetOnSpawn = false
	radarGui.DisplayOrder = 100
	radarGui.Parent = playerGui

	-- Background container
	local container = Instance.new("Frame")
	container.Name = "RadarContainer"
	container.Size = UDim2.new(0, RADAR_SIZE + 20, 0, RADAR_SIZE + 90)
	container.Position = UDim2.new(0, 20, 0, 20)
	container.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = radarGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 8)
	containerCorner.Parent = container

	-- Radar circular frame
	radarFrame = Instance.new("Frame")
	radarFrame.Name = "RadarFrame"
	radarFrame.Size = UDim2.new(0, RADAR_SIZE, 0, RADAR_SIZE)
	radarFrame.Position = UDim2.new(0, 10, 0, 10)
	radarFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	radarFrame.BorderSizePixel = 0
	radarFrame.ClipsDescendants = true
	radarFrame.Parent = container

	local radarCorner = Instance.new("UICorner")
	radarCorner.CornerRadius = UDim.new(1, 0)  -- Circular
	radarCorner.Parent = radarFrame

	-- Radar grid lines
	self:CreateRadarGrid(radarFrame)

	-- Player dot (center, always visible)
	playerDot = Instance.new("Frame")
	playerDot.Name = "PlayerDot"
	playerDot.Size = UDim2.new(0, 8, 0, 8)
	playerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
	playerDot.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	playerDot.BorderSizePixel = 0
	playerDot.ZIndex = 10
	playerDot.Parent = radarFrame

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = playerDot

	-- Player direction indicator (arrow)
	local directionArrow = Instance.new("Frame")
	directionArrow.Name = "DirectionArrow"
	directionArrow.Size = UDim2.new(0, 2, 0, 12)
	directionArrow.Position = UDim2.new(0.5, -1, 0, -14)
	directionArrow.AnchorPoint = Vector2.new(0.5, 1)
	directionArrow.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	directionArrow.BorderSizePixel = 0
	directionArrow.ZIndex = 11
	directionArrow.Parent = playerDot

	-- Gamemode display
	local gamemodeLabel = Instance.new("TextLabel")
	gamemodeLabel.Name = "GamemodeLabel"
	gamemodeLabel.Size = UDim2.new(1, -20, 0, 25)
	gamemodeLabel.Position = UDim2.new(0, 10, 1, -70)
	gamemodeLabel.BackgroundTransparency = 1
	gamemodeLabel.Text = "Team Deathmatch"
	gamemodeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	gamemodeLabel.Font = Enum.Font.GothamBold
	gamemodeLabel.TextSize = 14
	gamemodeLabel.TextXAlignment = Enum.TextXAlignment.Left
	gamemodeLabel.Parent = container

	-- Score display
	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "ScoreLabel"
	scoreLabel.Size = UDim2.new(1, -20, 0, 35)
	scoreLabel.Position = UDim2.new(0, 10, 1, -45)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text = "FBI: 0 | KFC: 0"
	scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	scoreLabel.Font = Enum.Font.GothamBold
	scoreLabel.TextSize = 16
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
	scoreLabel.Parent = container
end

function RadarController:CreateRadarGrid(parent)
	-- Cross-hair lines
	local hLine = Instance.new("Frame")
	hLine.Size = UDim2.new(1, 0, 0, 1)
	hLine.Position = UDim2.new(0, 0, 0.5, 0)
	hLine.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	hLine.BackgroundTransparency = 0.5
	hLine.BorderSizePixel = 0
	hLine.Parent = parent

	local vLine = Instance.new("Frame")
	vLine.Size = UDim2.new(0, 1, 1, 0)
	vLine.Position = UDim2.new(0.5, 0, 0, 0)
	vLine.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	vLine.BackgroundTransparency = 0.5
	vLine.BorderSizePixel = 0
	vLine.Parent = parent

	-- Concentric circles
	for i = 1, 3 do
		local circle = Instance.new("Frame")
		circle.Name = "Circle" .. i
		local size = (i / 3) * RADAR_SIZE
		circle.Size = UDim2.new(0, size, 0, size)
		circle.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
		circle.BackgroundTransparency = 1
		circle.BorderSizePixel = 0
		circle.Parent = parent

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(50, 50, 60)
		stroke.Transparency = 0.7
		stroke.Thickness = 1
		stroke.Parent = circle

		local cornerCircle = Instance.new("UICorner")
		cornerCircle.CornerRadius = UDim.new(1, 0)
		cornerCircle.Parent = circle
	end
end

function RadarController:UpdateRadar()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local root = character.HumanoidRootPart
	local playerPosition = root.Position
	local playerRotation = math.deg(math.atan2(root.CFrame.LookVector.X, root.CFrame.LookVector.Z))

	-- Rotate player dot to show direction
	if playerDot then
		playerDot.Rotation = -playerRotation
	end

	-- Update detected enemy positions
	local currentTime = tick()
	for enemyPlayer, data in pairs(detectedEnemies) do
		if currentTime > data.expireTime then
			-- Remove expired enemy dot
			if data.dot then
				data.dot:Destroy()
			end
			detectedEnemies[enemyPlayer] = nil
		elseif enemyPlayer.Character and enemyPlayer.Character:FindFirstChild("HumanoidRootPart") then
			-- Update enemy dot position
			local enemyPos = enemyPlayer.Character.HumanoidRootPart.Position
			local offset = enemyPos - playerPosition
			local distance = Vector2.new(offset.X, offset.Z).Magnitude

			if distance <= RADAR_RANGE then
				-- Calculate radar position
				local radarX = (offset.X / RADAR_RANGE) * (RADAR_SIZE / 2)
				local radarZ = (offset.Z / RADAR_RANGE) * (RADAR_SIZE / 2)

				-- Rotate based on player's rotation
				local rotatedX = radarX * math.cos(math.rad(playerRotation)) - radarZ * math.sin(math.rad(playerRotation))
				local rotatedZ = radarX * math.sin(math.rad(playerRotation)) + radarZ * math.cos(math.rad(playerRotation))

				-- Update dot position
				if data.dot then
					data.dot.Position = UDim2.new(0.5, rotatedX, 0.5, rotatedZ)
					data.dot.Visible = true
				end
			else
				-- Enemy out of range
				if data.dot then
					data.dot.Visible = false
				end
			end
		end
	end

	-- Update active waves
	for i = #activeWaves, 1, -1 do
		local waveData = activeWaves[i]
		if currentTime > waveData.expireTime then
			waveData.frame:Destroy()
			table.remove(activeWaves, i)
		end
	end
end

function RadarController:DetectGunfire(shooter, shotData)
	if not shooter or not shooter.Character then return end

	local suppressorType = shotData.SuppressorType or "None"
	local detectionRange = SUPPRESSOR_RANGES[suppressorType] or SUPPRESSOR_RANGES.None

	-- Check if player is in detection range
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local distance = (shooter.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude

	if distance <= detectionRange then
		-- Add enemy to radar
		self:AddEnemyToRadar(shooter, DETECTION_DURATION)

		-- Create wave effect (only for unsuppressed or standard suppressor)
		if suppressorType == "None" or suppressorType == "Standard" then
			self:CreateWaveEffect(shooter)
		end

		print("Detected gunfire from", shooter.Name, "at", math.floor(distance), "studs")
	end
end

function RadarController:DetectGrenadeExplosion(thrower, position)
	-- Grenades always show on radar (global detection)
	self:AddEnemyToRadar(thrower, DETECTION_DURATION)
	print("Detected grenade explosion from", thrower.Name)
end

function RadarController:AddEnemyToRadar(enemyPlayer, duration)
	if detectedEnemies[enemyPlayer] then
		-- Extend duration if already detected
		detectedEnemies[enemyPlayer].expireTime = tick() + duration
	else
		-- Create new enemy dot
		local enemyDot = Instance.new("Frame")
		enemyDot.Name = "EnemyDot_" .. enemyPlayer.Name
		enemyDot.Size = UDim2.new(0, 6, 0, 6)
		enemyDot.AnchorPoint = Vector2.new(0.5, 0.5)
		enemyDot.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		enemyDot.BorderSizePixel = 0
		enemyDot.ZIndex = 9
		enemyDot.Parent = radarFrame

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = enemyDot

		detectedEnemies[enemyPlayer] = {
			dot = enemyDot,
			expireTime = tick() + duration
		}

		-- Fade animation
		spawn(function()
			task.wait(duration - 0.5)
			if enemyDot and enemyDot.Parent then
				TweenService:Create(enemyDot, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
			end
		end)
	end
end

function RadarController:CreateWaveEffect(shooter)
	if not shooter.Character or not shooter.Character:FindFirstChild("HumanoidRootPart") then return end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local shooterPos = shooter.Character.HumanoidRootPart.Position
	local playerPos = character.HumanoidRootPart.Position
	local offset = shooterPos - playerPos
	local distance = Vector2.new(offset.X, offset.Z).Magnitude

	if distance > RADAR_RANGE then return end

	-- Calculate radar position
	local playerRotation = math.deg(math.atan2(character.HumanoidRootPart.CFrame.LookVector.X, character.HumanoidRootPart.CFrame.LookVector.Z))
	local radarX = (offset.X / RADAR_RANGE) * (RADAR_SIZE / 2)
	local radarZ = (offset.Z / RADAR_RANGE) * (RADAR_SIZE / 2)

	local rotatedX = radarX * math.cos(math.rad(playerRotation)) - radarZ * math.sin(math.rad(playerRotation))
	local rotatedZ = radarX * math.sin(math.rad(playerRotation)) + radarZ * math.cos(math.rad(playerRotation))

	-- Create expanding wave
	local wave = Instance.new("Frame")
	wave.Name = "Wave"
	wave.Size = UDim2.new(0, 10, 0, 10)
	wave.Position = UDim2.new(0.5, rotatedX - 5, 0.5, rotatedZ - 5)
	wave.BackgroundTransparency = 0.3
	wave.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
	wave.BorderSizePixel = 0
	wave.ZIndex = 8
	wave.Parent = radarFrame

	local waveCorner = Instance.new("UICorner")
	waveCorner.CornerRadius = UDim.new(1, 0)
	waveCorner.Parent = wave

	-- Animate wave expansion and fade
	local expandTween = TweenService:Create(wave, TweenInfo.new(WAVE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(0.5, rotatedX - 20, 0.5, rotatedZ - 20),
		BackgroundTransparency = 1
	})
	expandTween:Play()

	table.insert(activeWaves, {
		frame = wave,
		expireTime = tick() + WAVE_DURATION
	})

	expandTween.Completed:Connect(function()
		wave:Destroy()
	end)
end

function RadarController:UpdateScoreDisplay()
	local container = radarGui and radarGui:FindFirstChild("RadarContainer")
	if not container then return end

	local gamemodeLabel = container:FindFirstChild("GamemodeLabel")
	local scoreLabel = container:FindFirstChild("ScoreLabel")

	-- Get current gamemode
	local gamemodeManager = _G.GamemodeManager
	if gamemodeManager and gamemodeLabel then
		local gamemodeInfo = gamemodeManager:GetCurrentGamemodeInfo()
		if gamemodeInfo and gamemodeInfo.Data then
			gamemodeLabel.Text = gamemodeInfo.Data.Name or "Unknown"
		end
	end

	-- Get team scores
	if scoreLabel then
		local teamManager = require(ReplicatedStorage.FPSSystem.Modules.TeamManager)
		if teamManager then
			local fbiScore = teamManager:GetTeamScore("FBI") or 0
			local kfcScore = teamManager:GetTeamScore("KFC") or 0
			scoreLabel.Text = string.format("FBI: %d | KFC: %d", fbiScore, kfcScore)
		end
	end
end

-- Initialize
RadarController:Initialize()

return RadarController
