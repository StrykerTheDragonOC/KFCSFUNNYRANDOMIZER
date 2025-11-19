--[[
	Pickup Manager (Server)
	Manages all map pickups: Armor, Ammo, Medical, NVG
	Handles spawning, respawning, and pickup collection
	Integrates with player systems
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local PickupCollectedEvent = RemoteEvents:FindFirstChild("PickupCollected") or Instance.new("RemoteEvent", RemoteEvents)
PickupCollectedEvent.Name = "PickupCollected"

local PickupManager = {}

-- Pickup configurations
local PICKUP_TYPES = {
	Armor = {
		Name = "Armor Plate",
		Description = "Restores 50 armor",
		ArmorAmount = 50,
		RespawnTime = 30,
		Color = Color3.fromRGB(100, 150, 255),
		Size = Vector3.new(2, 1, 2),
		Sound = "rbxassetid://3581127385"
	},

	HeavyArmor = {
		Name = "Heavy Armor",
		Description = "Restores 100 armor",
		ArmorAmount = 100,
		RespawnTime = 60,
		Color = Color3.fromRGB(50, 100, 200),
		Size = Vector3.new(2.5, 1.5, 2.5),
		Sound = "rbxassetid://3581127385"
	},

	MedKit = {
		Name = "Medical Kit",
		Description = "Restores 50 health",
		HealAmount = 50,
		RespawnTime = 25,
		Color = Color3.fromRGB(255, 100, 100),
		Size = Vector3.new(1.5, 1, 1.5),
		Sound = "rbxassetid://3581127385"
	},

	Bandage = {
		Name = "Bandage",
		Description = "Restores 25 health, removes bleeding",
		HealAmount = 25,
		RemovesBleed = true,
		RespawnTime = 15,
		Color = Color3.fromRGB(255, 200, 200),
		Size = Vector3.new(1, 0.5, 1),
		Sound = "rbxassetid://3581127385"
	},

	Tourniquet = {
		Name = "Tourniquet",
		Description = "Removes fracture status",
		RemovesFracture = true,
		RespawnTime = 20,
		Color = Color3.fromRGB(200, 150, 100),
		Size = Vector3.new(1, 0.5, 1),
		Sound = "rbxassetid://3581127385"
	},

	AmmoBox = {
		Name = "Ammo Box",
		Description = "Refills ammo for equipped weapon",
		AmmoPercent = 1.0, -- 100% refill
		RespawnTime = 20,
		Color = Color3.fromRGB(255, 200, 50),
		Size = Vector3.new(1.5, 1.5, 1.5),
		Sound = "rbxassetid://3581127385"
	},

	NightVision = {
		Name = "Night Vision Goggles",
		Description = "Press N to toggle night vision",
		GivesNVG = true,
		RespawnTime = 45,
		Color = Color3.fromRGB(100, 255, 100),
		Size = Vector3.new(1.5, 1, 1.5),
		Sound = "rbxassetid://3581127385"
	}
}

-- Active pickups in the map
local activePickups = {}
local pickupRespawnTimers = {}

function PickupManager:Initialize()
	-- Find all pickup spawn points
	-- Check Map/Spawns first, then root Workspace
	local pickupSpawnsFolder = nil

	local mapFolder = Workspace:FindFirstChild("Map")
	if mapFolder then
		local spawnsFolder = mapFolder:FindFirstChild("Spawns")
		if spawnsFolder then
			pickupSpawnsFolder = spawnsFolder:FindFirstChild("PickupSpawns")
		end
	end

	-- Fallback to root Workspace
	if not pickupSpawnsFolder then
		pickupSpawnsFolder = Workspace:FindFirstChild("PickupSpawns")
	end

	if not pickupSpawnsFolder then
		warn("PickupSpawns folder not found in Workspace.Map.Spawns or Workspace - creating example spawns")
		pickupSpawnsFolder = Instance.new("Folder")
		pickupSpawnsFolder.Name = "PickupSpawns"
		pickupSpawnsFolder.Parent = Workspace

		-- Create example spawn points
		self:CreateExampleSpawns(pickupSpawnsFolder)
	end

	-- Spawn all pickups
	for _, spawnPoint in ipairs(pickupSpawnsFolder:GetChildren()) do
		if spawnPoint:IsA("BasePart") or spawnPoint:IsA("Model") then
			self:SpawnPickup(spawnPoint)
		end
	end

	-- Listen for pickup collection
	for _, pickup in ipairs(Workspace:GetDescendants()) do
		if pickup:IsA("Model") and pickup:FindFirstChild("PickupType") then
			self:SetupPickupTrigger(pickup)
		end
	end

	print("PickupManager initialized -", #activePickups, "pickups spawned")
end

function PickupManager:CreateExampleSpawns(parent)
	-- Create a few example spawn points
	local exampleTypes = {"Armor", "MedKit", "AmmoBox", "NightVision"}

	for i, pickupType in ipairs(exampleTypes) do
		local spawn = Instance.new("Part")
		spawn.Name = pickupType .. "Spawn"
		spawn.Size = Vector3.new(4, 1, 4)
		spawn.Position = Vector3.new(i * 10, 5, 0)
		spawn.Anchored = true
		spawn.Transparency = 0.8
		spawn.CanCollide = false
		spawn.Color = PICKUP_TYPES[pickupType].Color
		spawn.Parent = parent

		-- Add configuration attribute
		spawn:SetAttribute("PickupType", pickupType)
	end
end

function PickupManager:SpawnPickup(spawnPoint)
	local pickupType = spawnPoint:GetAttribute("PickupType")
	if not pickupType or not PICKUP_TYPES[pickupType] then
		warn("Invalid pickup type for spawn:", spawnPoint.Name)
		return
	end

	local config = PICKUP_TYPES[pickupType]

	-- Create pickup model
	local pickup = Instance.new("Model")
	pickup.Name = config.Name
	pickup.Parent = Workspace

	-- Create main part
	local mainPart = Instance.new("Part")
	mainPart.Name = "Main"
	mainPart.Size = config.Size
	mainPart.Position = spawnPoint.Position + Vector3.new(0, config.Size.Y/2, 0)
	mainPart.Anchored = true
	mainPart.CanCollide = false
	mainPart.Color = config.Color
	mainPart.Material = Enum.Material.Neon
	mainPart.Parent = pickup

	-- Add rounded corners
	local corner = Instance.new("CornerWedgePart")
	corner.Size = Vector3.new(0.2, 0.2, 0.2)
	corner.Parent = mainPart

	-- Create highlight effect
	local highlight = Instance.new("Highlight")
	highlight.FillColor = config.Color
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0.3
	highlight.Parent = pickup

	-- Create floating animation
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
	bodyPosition.Position = mainPart.Position
	bodyPosition.P = 1000
	bodyPosition.D = 100
	bodyPosition.Parent = mainPart

	-- Create spinning animation
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(0, math.huge, 0)
	bodyGyro.P = 1000
	bodyGyro.Parent = mainPart

	-- Animate rotation
	spawn(function()
		while pickup.Parent do
			bodyGyro.CFrame = bodyGyro.CFrame * CFrame.Angles(0, math.rad(2), 0)
			task.wait(0.03)
		end
	end)

	-- Animate bobbing
	local startY = mainPart.Position.Y
	spawn(function()
		local t = 0
		while pickup.Parent do
			t = t + 0.05
			local offset = math.sin(t * 2) * 0.5
			bodyPosition.Position = Vector3.new(mainPart.Position.X, startY + offset, mainPart.Position.Z)
			task.wait(0.03)
		end
	end)

	-- Create proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.ActionText = "Pick up"
	proximityPrompt.ObjectText = config.Name
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.MaxActivationDistance = 8
	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.Parent = mainPart

	-- Store pickup data
	local pickupData = Instance.new("StringValue")
	pickupData.Name = "PickupType"
	pickupData.Value = pickupType
	pickupData.Parent = pickup

	local spawnRef = Instance.new("ObjectValue")
	spawnRef.Name = "SpawnPoint"
	spawnRef.Value = spawnPoint
	spawnRef.Parent = pickup

	pickup.PrimaryPart = mainPart

	-- Setup trigger
	self:SetupPickupTrigger(pickup)

	table.insert(activePickups, pickup)

	return pickup
end

function PickupManager:SetupPickupTrigger(pickup)
	local mainPart = pickup:FindFirstChild("Main") or pickup.PrimaryPart
	if not mainPart then return end

	local proximityPrompt = mainPart:FindFirstChildOfClass("ProximityPrompt")
	if not proximityPrompt then return end

	proximityPrompt.Triggered:Connect(function(player)
		self:CollectPickup(player, pickup)
	end)
end

function PickupManager:CollectPickup(player, pickup)
	local pickupTypeValue = pickup:FindFirstChild("PickupType")
	if not pickupTypeValue then return end

	local pickupType = pickupTypeValue.Value
	local config = PICKUP_TYPES[pickupType]

	if not config then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Apply pickup effects
	local success = self:ApplyPickupEffects(player, character, humanoid, pickupType, config)

	if success then
		-- Broadcast to client
		PickupCollectedEvent:FireClient(player, pickupType, config)

		-- Play sound
		local sound = Instance.new("Sound")
		sound.SoundId = config.Sound
		sound.Volume = 0.5
		sound.Parent = pickup.PrimaryPart or pickup:FindFirstChild("Main")
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)

		-- Remove pickup and schedule respawn
		local spawnPoint = pickup:FindFirstChild("SpawnPoint")
		if spawnPoint and spawnPoint.Value then
			self:ScheduleRespawn(spawnPoint.Value, pickupType, config.RespawnTime)
		end

		pickup:Destroy()

		-- Remove from active pickups
		local index = table.find(activePickups, pickup)
		if index then
			table.remove(activePickups, index)
		end

		print(player.Name, "collected pickup:", config.Name)
	end
end

function PickupManager:ApplyPickupEffects(player, character, humanoid, pickupType, config)
	-- Armor pickup
	if config.ArmorAmount then
		local armorValue = character:FindFirstChild("Armor") or Instance.new("NumberValue", character)
		armorValue.Name = "Armor"
		armorValue.Value = math.min((armorValue.Value or 0) + config.ArmorAmount, 100)
		return true
	end

	-- Health pickup
	if config.HealAmount then
		humanoid.Health = math.min(humanoid.Health + config.HealAmount, humanoid.MaxHealth)

		-- Remove bleeding status if applicable
		if config.RemovesBleed then
			local statusEffects = character:FindFirstChild("StatusEffects")
			if statusEffects and statusEffects:FindFirstChild("Bleeding") then
				statusEffects.Bleeding:Destroy()
			end
		end

		return true
	end

	-- Remove fracture
	if config.RemovesFracture then
		local statusEffects = character:FindFirstChild("StatusEffects")
		if statusEffects and statusEffects:FindFirstChild("Fracture") then
			statusEffects.Fracture:Destroy()
		end
		return true
	end

	-- Ammo refill
	if config.AmmoPercent then
		-- Signal client to refill ammo
		PickupCollectedEvent:FireClient(player, pickupType, config)
		return true
	end

	-- Night vision goggles
	if config.GivesNVG then
		-- Signal client to give NVG
		PickupCollectedEvent:FireClient(player, pickupType, config)
		return true
	end

	return false
end

function PickupManager:ScheduleRespawn(spawnPoint, pickupType, respawnTime)
	local key = spawnPoint:GetFullName()

	-- Cancel existing timer if any
	if pickupRespawnTimers[key] then
		task.cancel(pickupRespawnTimers[key])
	end

	-- Schedule respawn
	pickupRespawnTimers[key] = task.delay(respawnTime, function()
		self:SpawnPickup(spawnPoint)
		pickupRespawnTimers[key] = nil
	end)
end

-- Admin commands
_G.PickupCommands = {
	spawnPickup = function(pickupType, position)
		if not PICKUP_TYPES[pickupType] then
			warn("Invalid pickup type:", pickupType)
			print("Available types:", table.concat(PickupManager:GetPickupTypes(), ", "))
			return
		end

		-- Create temp spawn point
		local spawn = Instance.new("Part")
		spawn.Position = position or Vector3.new(0, 5, 0)
		spawn.Anchored = true
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn:SetAttribute("PickupType", pickupType)
		spawn.Parent = Workspace

		PickupManager:SpawnPickup(spawn)
		spawn:Destroy()

		print("Spawned pickup:", pickupType)
	end,

	listPickupTypes = function()
		print("=== AVAILABLE PICKUP TYPES ===")
		for typeName, config in pairs(PICKUP_TYPES) do
			print(string.format("%s - %s (Respawn: %ds)",
				typeName,
				config.Description,
				config.RespawnTime
			))
		end
	end,

	clearAllPickups = function()
		for _, pickup in ipairs(activePickups) do
			if pickup.Parent then
				pickup:Destroy()
			end
		end
		table.clear(activePickups)
		print("Cleared all pickups")
	end,

	respawnAllPickups = function()
		_G.PickupCommands.clearAllPickups()
		PickupManager:Initialize()
		print("Respawned all pickups")
	end
}

function PickupManager:GetPickupTypes()
	local types = {}
	for typeName in pairs(PICKUP_TYPES) do
		table.insert(types, typeName)
	end
	return types
end

-- Initialize
PickupManager:Initialize()

-- Make globally accessible
_G.PickupManager = PickupManager

return PickupManager
