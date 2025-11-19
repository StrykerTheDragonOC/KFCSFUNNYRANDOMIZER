--[[
	Spotting Controller
	Press Q to:
	- Spot enemies (puts red indicator over them, visible to team)
	- Place map markers (when looking at ground/walls)

	Spotted enemies can hide to remove indicator
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local SpotEnemyEvent = RemoteEvents:FindFirstChild("SpotEnemy") or Instance.new("RemoteEvent", RemoteEvents)
SpotEnemyEvent.Name = "SpotEnemy"
local RemoveSpotEvent = RemoteEvents:FindFirstChild("RemoveSpot") or Instance.new("RemoteEvent", RemoteEvents)
RemoveSpotEvent.Name = "RemoveSpot"

local SpottingController = {}

-- Spotting settings
local SPOT_RANGE = 500  -- studs
local SPOT_COOLDOWN = 1  -- seconds between spots
local SPOT_DURATION = 5  -- seconds indicator lasts
local SPOT_FOV = 30  -- degrees, cone for enemy detection

local lastSpotTime = 0
local activeSpots = {}  -- {enemyPlayer = {indicator, expireTime}}

-- Sounds
local SPOT_SOUND_ID = "rbxassetid://3140357033"  -- Ping sound

function SpottingController:Initialize()
	-- Listen for Q key
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Q then
			self:TrySpot()
		end
	end)

	-- Listen for enemy spots from server
	SpotEnemyEvent.OnClientEvent:Connect(function(spottedPlayer, spotterTeam)
		self:ShowSpotIndicator(spottedPlayer, spotterTeam)
	end)

	-- Listen for spot removals from server
	RemoveSpotEvent.OnClientEvent:Connect(function(spottedPlayer)
		self:RemoveSpotIndicator(spottedPlayer)
	end)

	-- Update spot indicators every frame
	RunService.RenderStepped:Connect(function()
		self:UpdateSpotIndicators()
	end)

	-- Remove expired spots
	spawn(function()
		while true do
			task.wait(1)
			self:RemoveExpiredSpots()
		end
	end)

	print("SpottingController initialized")
end

function SpottingController:TrySpot()
	-- Check cooldown
	if tick() - lastSpotTime < SPOT_COOLDOWN then
		return
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	-- Raycast from camera
	local mousePos = UserInputService:GetMouseLocation()
	local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * SPOT_RANGE, raycastParams)

	if raycastResult then
		-- Check if hit an enemy player
		local hitPlayer = self:GetPlayerFromHit(raycastResult.Instance)

		if hitPlayer and hitPlayer ~= player and hitPlayer.Team ~= player.Team then
			-- Spot enemy player
			self:SpotEnemy(hitPlayer)
			lastSpotTime = tick()
			return
		end

		-- If not player, try to find enemy in view
		local enemyInView = self:FindEnemyInView()
		if enemyInView then
			self:SpotEnemy(enemyInView)
			lastSpotTime = tick()
			return
		end

		-- If no enemy found, place map marker
		self:PlaceMapMarker(raycastResult.Position)
		lastSpotTime = tick()
	end
end

function SpottingController:FindEnemyInView()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end

	local root = character.HumanoidRootPart
	local cameraPos = Camera.CFrame.Position
	local cameraLook = Camera.CFrame.LookVector

	local closestEnemy = nil
	local closestDistance = SPOT_RANGE

	-- Check all players
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Team ~= player.Team then
			local otherChar = otherPlayer.Character
			if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
				local otherRoot = otherChar.HumanoidRootPart
				local distance = (otherRoot.Position - cameraPos).Magnitude

				if distance <= SPOT_RANGE then
					-- Check if in FOV
					local directionToEnemy = (otherRoot.Position - cameraPos).Unit
					local angle = math.deg(math.acos(math.clamp(cameraLook:Dot(directionToEnemy), -1, 1)))

					if angle <= SPOT_FOV then
						-- Check line of sight
						local raycastParams = RaycastParams.new()
						raycastParams.FilterDescendantsInstances = {character, otherChar}
						raycastParams.FilterType = Enum.RaycastFilterType.Exclude

						local los = workspace:Raycast(cameraPos, otherRoot.Position - cameraPos, raycastParams)

						if not los or los.Instance:IsDescendantOf(otherChar) then
							-- Clear line of sight
							if distance < closestDistance then
								closestDistance = distance
								closestEnemy = otherPlayer
							end
						end
					end
				end
			end
		end
	end

	return closestEnemy
end

function SpottingController:SpotEnemy(enemyPlayer)
	-- Send spot to server
	SpotEnemyEvent:FireServer(enemyPlayer)

	-- Play spot sound locally
	local spotSound = Instance.new("Sound")
	spotSound.SoundId = SPOT_SOUND_ID
	spotSound.Volume = 0.5
	spotSound.Parent = Camera
	spotSound:Play()
	game:GetService("Debris"):AddItem(spotSound, 1)

	print("Spotted enemy:", enemyPlayer.Name)
end

function SpottingController:ShowSpotIndicator(spottedPlayer, spotterTeam)
	-- Only show if on same team as spotter
	if not player.Team or player.Team.Name ~= spotterTeam then return end
	if spottedPlayer == player then return end  -- Don't spot self

	-- Remove existing spot if any
	if activeSpots[spottedPlayer] then
		if activeSpots[spottedPlayer].indicator then
			activeSpots[spottedPlayer].indicator:Destroy()
		end
	end

	-- Create spot indicator
	local indicator = self:CreateSpotIndicator()
	indicator.Adornee = spottedPlayer.Character and spottedPlayer.Character:FindFirstChild("HumanoidRootPart")

	activeSpots[spottedPlayer] = {
		indicator = indicator,
		expireTime = tick() + SPOT_DURATION
	}

	print("Showing spot indicator for:", spottedPlayer.Name)
end

function SpottingController:CreateSpotIndicator()
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "SpotIndicator"
	billboardGui.Size = UDim2.new(0, 50, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = playerGui

	-- Red diamond indicator
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.8, 0, 0.8, 0)
	frame.Position = UDim2.new(0.1, 0, 0.1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Rotation = 45  -- Diamond shape
	frame.Parent = billboardGui

	-- Pulsing animation
	spawn(function()
		while frame.Parent do
			for i = 0.3, 0.7, 0.05 do
				if not frame.Parent then break end
				frame.BackgroundTransparency = i
				task.wait(0.05)
			end
			for i = 0.7, 0.3, -0.05 do
				if not frame.Parent then break end
				frame.BackgroundTransparency = i
				task.wait(0.05)
			end
		end
	end)

	-- Arrow pointing down
	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(1, 0, 1, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "▼"
	arrow.TextColor3 = Color3.fromRGB(255, 50, 50)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 24
	arrow.TextStrokeTransparency = 0.5
	arrow.Rotation = -45  -- Undo parent rotation
	arrow.Parent = frame

	return billboardGui
end

function SpottingController:RemoveSpotIndicator(spottedPlayer)
	if activeSpots[spottedPlayer] then
		if activeSpots[spottedPlayer].indicator then
			activeSpots[spottedPlayer].indicator:Destroy()
		end
		activeSpots[spottedPlayer] = nil
		print("Removed spot indicator for:", spottedPlayer.Name)
	end
end

function SpottingController:UpdateSpotIndicators()
	for spottedPlayer, data in pairs(activeSpots) do
		if spottedPlayer.Character and spottedPlayer.Character:FindFirstChild("HumanoidRootPart") then
			if data.indicator then
				data.indicator.Adornee = spottedPlayer.Character.HumanoidRootPart
			end
		end
	end
end

function SpottingController:RemoveExpiredSpots()
	local currentTime = tick()
	for spottedPlayer, data in pairs(activeSpots) do
		if currentTime > data.expireTime then
			if data.indicator then
				data.indicator:Destroy()
			end
			activeSpots[spottedPlayer] = nil
		end
	end
end

function SpottingController:PlaceMapMarker(position)
	-- Create visual marker at position
	local marker = Instance.new("Part")
	marker.Name = "MapMarker"
	marker.Shape = Enum.PartType.Ball
	marker.Size = Vector3.new(2, 2, 2)
	marker.Position = position
	marker.BrickColor = player.Team and player.Team.TeamColor or BrickColor.new("Medium stone grey")
	marker.Material = Enum.Material.Neon
	marker.CanCollide = false
	marker.Anchored = true
	marker.Transparency = 0.3
	marker.Parent = workspace

	-- Pulsing effect
	spawn(function()
		for i = 1, 10 do
			marker.Transparency = 0.3 + (i * 0.07)
			task.wait(0.1)
		end
		marker:Destroy()
	end)

	-- Play marker sound
	local markerSound = Instance.new("Sound")
	markerSound.SoundId = SPOT_SOUND_ID
	markerSound.Volume = 0.3
	markerSound.Parent = marker
	markerSound:Play()

	print("Placed map marker at:", position)
end

function SpottingController:GetPlayerFromHit(instance)
	local current = instance
	while current do
		if current:IsA("Model") then
			local humanoid = current:FindFirstChild("Humanoid")
			if humanoid then
				return Players:GetPlayerFromCharacter(current)
			end
		end
		current = current.Parent
	end
	return nil
end

-- Initialize
SpottingController:Initialize()

return SpottingController
