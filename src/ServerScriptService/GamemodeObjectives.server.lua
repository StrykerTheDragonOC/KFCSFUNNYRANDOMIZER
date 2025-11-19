--[[
	Gamemode Objectives Handler
	Manages CTF flags, KOTH zones, KC dog tags, Hardpoints, etc.
	Creates and handles all objective logic
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

repeat
	task.wait()
until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents

local ObjectiveCapturedEvent = RemoteEvents:FindFirstChild("ObjectiveCaptured")
if not ObjectiveCapturedEvent then
	ObjectiveCapturedEvent = Instance.new("RemoteEvent")
	ObjectiveCapturedEvent.Name = "ObjectiveCaptured"
	ObjectiveCapturedEvent.Parent = RemoteEvents
end


local FlagPickedUpEvent = RemoteEvents:FindFirstChild("FlagPickedUp")
if not FlagPickedUpEvent then
	FlagPickedUpEvent = Instance.new("RemoteEvent")
	FlagPickedUpEvent.Name = "FlagPickedUp"
	FlagPickedUpEvent.Parent = RemoteEvents
end

local FlagDroppedEvent = RemoteEvents:FindFirstChild("FlagDropped")
if not FlagDroppedEvent then
	FlagDroppedEvent = Instance.new("RemoteEvent")
	FlagDroppedEvent.Name = "FlagDropped"
	FlagDroppedEvent.Parent = RemoteEvents
end

local DogTagCreatedEvent = RemoteEvents:FindFirstChild("DogTagCreated")
if not DogTagCreatedEvent then
	DogTagCreatedEvent = Instance.new("RemoteEvent")
	DogTagCreatedEvent.Name = "DogTagCreated"
	DogTagCreatedEvent.Parent = RemoteEvents
end

local GamemodeObjectives = {}

-- Objective states
local activeObjectives = {}
local flagCarriers = {}
local dogTags = {}
local captureZones = {}
local hardpoints = {}

-- Current gamemode
local currentGamemode = "TDM"

function GamemodeObjectives:Initialize()
	-- Find Map folder
	local mapFolder = Workspace:FindFirstChild("Map")
	if not mapFolder then
		warn("Map folder not found in Workspace")
		return
	end

	-- Find or create objectives folder in Map
	local objectivesFolder = mapFolder:FindFirstChild("GamemodeObjectives")
	if not objectivesFolder then
		objectivesFolder = Instance.new("Folder")
		objectivesFolder.Name = "GamemodeObjectives"
		objectivesFolder.Parent = mapFolder
		print("Created GamemodeObjectives folder in Map")
	end

	-- Setup ALL objectives but keep them hidden initially
	self:SetupCTFFlags(objectivesFolder)
	self:SetupKOTHZones(objectivesFolder)
	self:SetupHardpoints(objectivesFolder)
	self:SetupFlareDominationPoints(objectivesFolder)

	-- Hide all objectives initially
	self:HideAllObjectives(objectivesFolder)

	-- Listen for player deaths to spawn dog tags
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				if currentGamemode == "KC" then
					self:SpawnDogTag(character, player)
				end
			end)
		end)
	end)

	print("GamemodeObjectives initialized - all objectives hidden by default")
end

function GamemodeObjectives:HideAllObjectives(objectivesFolder)
	-- Hide all objective folders
	for _, folder in ipairs(objectivesFolder:GetChildren()) do
		if folder:IsA("Folder") then
			for _, obj in ipairs(folder:GetDescendants()) do
				if obj:IsA("ProximityPrompt") or obj:IsA("Highlight") then
					obj.Enabled = false
				elseif obj:IsA("BasePart") then
					obj.Transparency = 1
					obj.CanCollide = false
				end
			end
		end
	end
end

function GamemodeObjectives:ActivateGamemode(gamemode)
	currentGamemode = gamemode
	print("=== ACTIVATING GAMEMODE:", gamemode, "===")

	-- Find objectives folder
	local mapFolder = Workspace:FindFirstChild("Map")
	if not mapFolder then return end
	local objectivesFolder = mapFolder:FindFirstChild("GamemodeObjectives")
	if not objectivesFolder then return end

	-- Hide all objectives first
	self:HideAllObjectives(objectivesFolder)

	-- Show only the current gamemode's objectives
	local gamemodeToFolder = {
		["CTF"] = "CTF",
		["KOTH"] = "KOTH",
		["KC"] = nil, -- Dog tags spawn dynamically
		["HP"] = "Hardpoint",
		["FD"] = "FlareDomination",
		["TDM"] = nil -- No objectives for TDM
	}

	local targetFolder = gamemodeToFolder[gamemode]
	if targetFolder then
		local folder = objectivesFolder:FindFirstChild(targetFolder)
		if folder then
			for _, obj in ipairs(folder:GetDescendants()) do
				if obj:IsA("ProximityPrompt") or obj:IsA("Highlight") then
					obj.Enabled = true
				elseif obj:IsA("BasePart") then
					obj.Transparency = obj:GetAttribute("OriginalTransparency") or 0.7
					obj.CanCollide = obj:GetAttribute("OriginalCanCollide") or false
				end
			end
			print("✓ Activated objectives for:", gamemode)
		else
			warn("No objectives folder found for:", gamemode)
		end
	else
		print("✓ No map objectives for:", gamemode)
	end
end

-- ========== CTF (Capture the Flag) ==========
function GamemodeObjectives:SetupCTFFlags(parent)
	local ctfFolder = parent:FindFirstChild("CTF")
	if not ctfFolder then
		ctfFolder = Instance.new("Folder")
		ctfFolder.Name = "CTF"
		ctfFolder.Parent = parent
	end

	-- Create FBI flag if it doesn't exist
	local fbiFlagSpawn = ctfFolder:FindFirstChild("FBIFlagSpawn")
	if not fbiFlagSpawn then
		fbiFlagSpawn = Instance.new("Part")
		fbiFlagSpawn.Name = "FBIFlagSpawn"
		fbiFlagSpawn.Size = Vector3.new(4, 1, 4)
		fbiFlagSpawn.Position = Vector3.new(-50, 1, 0)
		fbiFlagSpawn.Anchored = true
		fbiFlagSpawn.Transparency = 0.8
		fbiFlagSpawn.Color = Color3.fromRGB(100, 150, 255)
		fbiFlagSpawn.CanCollide = false
		fbiFlagSpawn:SetAttribute("Team", "FBI")
		fbiFlagSpawn.Parent = ctfFolder
	end

	-- Create KFC flag if it doesn't exist
	local kfcFlagSpawn = ctfFolder:FindFirstChild("KFCFlagSpawn")
	if not kfcFlagSpawn then
		kfcFlagSpawn = Instance.new("Part")
		kfcFlagSpawn.Name = "KFCFlagSpawn"
		kfcFlagSpawn.Size = Vector3.new(4, 1, 4)
		kfcFlagSpawn.Position = Vector3.new(50, 1, 0)
		kfcFlagSpawn.Anchored = true
		kfcFlagSpawn.Transparency = 0.8
		kfcFlagSpawn.Color = Color3.fromRGB(255, 100, 100)
		kfcFlagSpawn.CanCollide = false
		kfcFlagSpawn:SetAttribute("Team", "KFC")
		kfcFlagSpawn.Parent = ctfFolder
	end

	-- Create actual flag models
	for _, spawn in ipairs(ctfFolder:GetChildren()) do
		if spawn:IsA("BasePart") and spawn.Name:match("FlagSpawn") then
			local team = spawn:GetAttribute("Team")
			if team then
				self:CreateFlag(spawn, team)
			end
		end
	end
end

function GamemodeObjectives:CreateFlag(spawnPoint, teamName)
	local flag = Instance.new("Model")
	flag.Name = teamName .. "_Flag"

	-- Flag pole
	local pole = Instance.new("Part")
	pole.Name = "Pole"
	pole.Size = Vector3.new(0.5, 8, 0.5)
	pole.Position = spawnPoint.Position + Vector3.new(0, 4, 0)
	pole.Anchored = true
	pole.Material = Enum.Material.Metal
	pole.Color = Color3.fromRGB(100, 100, 100)
	pole.Parent = flag

	-- Flag cloth
	local cloth = Instance.new("Part")
	cloth.Name = "Cloth"
	cloth.Size = Vector3.new(4, 3, 0.1)
	cloth.Position = pole.Position + Vector3.new(2, 1, 0)
	cloth.Anchored = true
	cloth.Material = Enum.Material.Fabric
	cloth.Color = (teamName == "FBI") and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(255, 100, 100)
	cloth.Parent = flag

	-- Highlight effect
	local highlight = Instance.new("Highlight")
	highlight.FillColor = cloth.Color
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 0
	highlight.Parent = flag

	-- ProximityPrompt to pick up
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Capture Flag"
	prompt.ObjectText = teamName .. " Flag"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 1.5
	prompt.Parent = pole

	prompt.Triggered:Connect(function(player)
		self:PickupFlag(player, flag, teamName)
	end)

	flag.Parent = spawnPoint
	flag.PrimaryPart = pole

	-- Store flag reference
	activeObjectives[teamName .. "_Flag"] = {
		Model = flag,
		Team = teamName,
		SpawnPoint = spawnPoint,
		Carrier = nil,
		IsHome = true
	}

	-- Wave animation
	spawn(function()
		while flag.Parent do
			cloth.CFrame = cloth.CFrame * CFrame.Angles(0, 0, math.rad(math.sin(tick() * 2) * 5))
			task.wait(0.05)
		end
	end)

	print("Created", teamName, "flag")
end

function GamemodeObjectives:PickupFlag(player, flag, flagTeam)
	-- Check if player is on opposite team
	if player.Team and player.Team.Name == flagTeam then
		print(player.Name, "can't pick up own flag")
		return
	end

	local flagData = activeObjectives[flagTeam .. "_Flag"]
	if flagData.Carrier then
		print("Flag already being carried by:", flagData.Carrier.Name)
		return
	end

	-- Attach flag to player
	flagData.Carrier = player
	flagData.IsHome = false

	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			-- Attach flag to player's back
			flag:SetPrimaryPartCFrame(rootPart.CFrame * CFrame.new(0, 2, -1))

			-- Weld to player
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rootPart
			weld.Part1 = flag.PrimaryPart
			weld.Parent = flag.PrimaryPart

			flag.PrimaryPart.Anchored = false

			print(player.Name, "picked up", flagTeam, "flag")
			FlagPickedUpEvent:FireAllClients(player, flagTeam)
		end
	end

	-- Listen for player death or leaving
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Once(function()
				self:DropFlag(player, flag, flagTeam)
			end)
		end
	end
end

function GamemodeObjectives:DropFlag(player, flag, flagTeam)
	local flagData = activeObjectives[flagTeam .. "_Flag"]
	if flagData.Carrier ~= player then return end

	flagData.Carrier = nil

	-- Drop flag at player's position
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			flag:SetPrimaryPartCFrame(CFrame.new(rootPart.Position + Vector3.new(0, 2, 0)))

			-- Remove weld
			for _, desc in ipairs(flag:GetDescendants()) do
				if desc:IsA("WeldConstraint") then
					desc:Destroy()
				end
			end

			flag.PrimaryPart.Anchored = true

			print(player.Name, "dropped", flagTeam, "flag")
			FlagDroppedEvent:FireAllClients(player, flagTeam, rootPart.Position)

			-- Return to base after 30 seconds
			task.delay(30, function()
				if not flagData.Carrier then
					self:ReturnFlag(flag, flagTeam)
				end
			end)
		end
	end
end

function GamemodeObjectives:ReturnFlag(flag, flagTeam)
	local flagData = activeObjectives[flagTeam .. "_Flag"]
	if flagData.Carrier then return end

	-- Move flag back to spawn
	flag:SetPrimaryPartCFrame(flagData.SpawnPoint.CFrame * CFrame.new(0, 5, 0))
	flagData.IsHome = true

	print(flagTeam, "flag returned to base")
	ObjectiveCapturedEvent:FireAllClients("FlagReturned", flagTeam)
end

-- ========== KOTH (King of the Hill) ==========
function GamemodeObjectives:SetupKOTHZones(parent)
	local kothFolder = parent:FindFirstChild("KOTH")
	if not kothFolder then
		kothFolder = Instance.new("Folder")
		kothFolder.Name = "KOTH"
		kothFolder.Parent = parent
	end

	-- Create hill zone if it doesn't exist
	local hillZone = kothFolder:FindFirstChild("HillZone")
	if not hillZone then
		hillZone = Instance.new("Part")
		hillZone.Name = "HillZone"
		hillZone.Size = Vector3.new(20, 10, 20)
		hillZone.Position = Vector3.new(0, 5, 0)
		hillZone.Anchored = true
		hillZone.Transparency = 0.7
		hillZone.Color = Color3.fromRGB(255, 200, 100)
		hillZone.CanCollide = false
		hillZone.Material = Enum.Material.Neon
		hillZone.Parent = kothFolder

		local corner = Instance.new("CornerWedgePart")
		corner.Parent = hillZone
	end

	captureZones["Hill"] = {
		Zone = hillZone,
		CapturingTeam = nil,
		Progress = 0,
		MaxProgress = 100,
		PointsPerSecond = 1
	}

	-- Setup zone detection
	self:MonitorCaptureZone(hillZone, "Hill")
end

function GamemodeObjectives:MonitorCaptureZone(zone, zoneName)
	local zoneData = captureZones[zoneName]

	-- Count players in zone every second
	spawn(function()
		while currentGamemode == "KOTH" do
			local playersInZone = {}
			local teamCounts = {FBI = 0, KFC = 0}

			-- Check all players
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then
					local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
					if rootPart then
						local distance = (rootPart.Position - zone.Position).Magnitude
						if distance <= zone.Size.X/2 then
							table.insert(playersInZone, player)
							if player.Team then
								teamCounts[player.Team.Name] = (teamCounts[player.Team.Name] or 0) + 1
							end
						end
					end
				end
			end

			-- Determine capturing team
			if teamCounts.FBI > teamCounts.KFC then
				zoneData.CapturingTeam = "FBI"
				zoneData.Progress = math.min(zoneData.Progress + 1, zoneData.MaxProgress)
				zone.Color = Color3.fromRGB(100, 150, 255)
			elseif teamCounts.KFC > teamCounts.FBI then
				zoneData.CapturingTeam = "KFC"
				zoneData.Progress = math.min(zoneData.Progress + 1, zoneData.MaxProgress)
				zone.Color = Color3.fromRGB(255, 100, 100)
			else
				-- Contested or empty
				zoneData.Progress = math.max(zoneData.Progress - 0.5, 0)
				zone.Color = Color3.fromRGB(255, 200, 100)
			end

			task.wait(1)
		end
	end)
end

-- ========== KC (Kill Confirmed) ==========
function GamemodeObjectives:SpawnDogTag(character, player)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create dog tag model
	local dogTag = Instance.new("Model")
	dogTag.Name = player.Name .. "_DogTag"

	local tag = Instance.new("Part")
	tag.Name = "Tag"
	tag.Size = Vector3.new(1, 0.1, 1.5)
	tag.Position = rootPart.Position + Vector3.new(0, 0.5, 0)
	tag.Anchored = true
	tag.CanCollide = false
	tag.Material = Enum.Material.Metal
	tag.Color = player.Team and (player.Team.Name == "FBI" and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(255, 100, 100)) or Color3.fromRGB(200, 200, 200)
	tag.Parent = dogTag

	-- Add highlight
	local highlight = Instance.new("Highlight")
	highlight.FillColor = tag.Color
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.3
	highlight.Parent = dogTag

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = "Dog Tag"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 8
	prompt.HoldDuration = 0.2
	prompt.Parent = tag

	prompt.Triggered:Connect(function(collector)
		self:CollectDogTag(collector, player, dogTag)
	end)

	dogTag.PrimaryPart = tag
	dogTag.Parent = Workspace

	-- Despawn after 60 seconds
	game:GetService("Debris"):AddItem(dogTag, 60)

	dogTags[player.Name] = dogTag
	DogTagCreatedEvent:FireAllClients(player.Name, rootPart.Position)

	print("Spawned dog tag for:", player.Name)
end

function GamemodeObjectives:CollectDogTag(collector, victim, dogTag)
	-- Award points
	local isConfirm = collector.Team == victim.Team
	local points = isConfirm and 5 or 10 -- More points for enemy kills

	print(collector.Name, isConfirm and "denied" or "confirmed", "kill on", victim.Name, "-", points, "points")

	dogTag:Destroy()
	dogTags[victim.Name] = nil

	-- Broadcast collection
	ObjectiveCapturedEvent:FireAllClients("DogTagCollected", collector, victim, isConfirm)
end

-- ========== HD (Hardpoint) ==========
function GamemodeObjectives:SetupHardpoints(parent)
	local hardpointFolder = parent:FindFirstChild("Hardpoint")
	if not hardpointFolder then
		hardpointFolder = Instance.new("Folder")
		hardpointFolder.Name = "Hardpoint"
		hardpointFolder.Parent = parent
	end

	-- Create multiple hardpoint locations
	local hardpointLocations = {
		{Name = "HP1", Position = Vector3.new(-30, 5, -30)},
		{Name = "HP2", Position = Vector3.new(30, 5, -30)},
		{Name = "HP3", Position = Vector3.new(0, 5, 30)},
		{Name = "HP4", Position = Vector3.new(-30, 5, 30)},
		{Name = "HP5", Position = Vector3.new(30, 5, -30)}
	}

	for _, hpData in ipairs(hardpointLocations) do
		local hp = hardpointFolder:FindFirstChild(hpData.Name)
		if not hp then
			hp = Instance.new("Part")
			hp.Name = hpData.Name
			hp.Size = Vector3.new(15, 8, 15)
			hp.Position = hpData.Position
			hp.Anchored = true
			hp.Transparency = 0.7
			hp.Color = Color3.fromRGB(255, 200, 100)
			hp.CanCollide = false
			hp.Material = Enum.Material.Neon
			hp.Parent = hardpointFolder
		end

		table.insert(hardpoints, {
			Zone = hp,
			Active = false
		})
	end
end

-- ========== FD (Flare Domination) ==========
function GamemodeObjectives:SetupFlareDominationPoints(parent)
	local flareFolder = parent:FindFirstChild("FlareDomination")
	if not flareFolder then
		flareFolder = Instance.new("Folder")
		flareFolder.Name = "FlareDomination"
		flareFolder.Parent = parent
	end

	-- Create 3-5 flare points
	local flarePoints = {
		{Name = "FlareA", Position = Vector3.new(-40, 2, 0)},
		{Name = "FlareB", Position = Vector3.new(0, 2, 0)},
		{Name = "FlareC", Position = Vector3.new(40, 2, 0)}
	}

	for _, fpData in ipairs(flarePoints) do
		local flarePoint = flareFolder:FindFirstChild(fpData.Name)
		if not flarePoint then
			flarePoint = self:CreateFlarePoint(fpData.Name, fpData.Position)
			flarePoint.Parent = flareFolder
		end
	end
end

function GamemodeObjectives:CreateFlarePoint(name, position)
	local flare = Instance.new("Model")
	flare.Name = name

	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(6, 1, 6)
	base.Position = position
	base.Anchored = true
	base.Color = Color3.fromRGB(200, 200, 200)
	base.Material = Enum.Material.Metal
	base.Parent = flare

	-- Flare beam
	local beam = Instance.new("Part")
	beam.Name = "Beam"
	beam.Size = Vector3.new(1, 20, 1)
	beam.Position = position + Vector3.new(0, 10, 0)
	beam.Anchored = true
	beam.Transparency = 0.5
	beam.Color = Color3.fromRGB(255, 200, 100)
	beam.Material = Enum.Material.Neon
	beam.CanCollide = false
	beam.Parent = flare

	flare.PrimaryPart = base
	return flare
end

-- Admin commands
GamemodeObjectives.AdminCommands = {
	resetObjectives = function()
		print("Resetting all objectives...")
		-- Clear and recreate
	end,

	listObjectives = function()
		print("=== ACTIVE OBJECTIVES ===")
		for name, data in pairs(activeObjectives) do
			print("-", name, "- Carrier:", data.Carrier and data.Carrier.Name or "None")
		end
		print("=== CAPTURE ZONES ===")
		for name, data in pairs(captureZones) do
			print("-", name, "- Progress:", data.Progress, "/", data.MaxProgress)
		end
	end,

	setGamemode = function(mode)
		currentGamemode = mode
		print("Set gamemode to:", mode)
	end
}

-- Initialize
GamemodeObjectives:Initialize()

return GamemodeObjectives
