local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)

local PickupHandler = {}

local activePickups = {} -- [pickupId] = {type, position, spawnTime, respawnTime, spawnPoint}
local pickupSpawnPoints = {} -- Spawn point parts found in workspace/ServerStorage

-- Normalize pickup type names (convert PascalCase/camelCase to spaced names)
local function NormalizePickupType(pickupType)
	-- Common mappings for pickup types
	local nameMap = {
		["HealthPack"] = "Health Pack",
		["MedicalKit"] = "Medical Kit",
		["Adrenaline"] = "Adrenaline",
		["LightArmor"] = "Light Armor",
		["HeavyArmor"] = "Heavy Armor",
		["RiotArmor"] = "Riot Armor",
		["PistolAmmo"] = "Pistol Ammo",
		["RifleAmmo"] = "Rifle Ammo",
		["SniperAmmo"] = "Sniper Ammo",
		["ShotgunShells"] = "Shotgun Shells",
		["NVG"] = "Night Vision",
		["NightVision"] = "Night Vision",
		["ThermalScope"] = "Thermal Scope",
		["GhillieSuit"] = "Ghillie Suit",
		["SpeedBoost"] = "Speed Boost",
		["DamageBoost"] = "Damage Boost",
		["ShieldGenerator"] = "Shield Generator",
	}

	-- Check if we have a direct mapping
	if nameMap[pickupType] then
		return nameMap[pickupType]
	end

	-- If no mapping, try to insert spaces before capital letters (PascalCase to spaced)
	-- e.g., "HealthPack" -> "Health Pack"
	local normalized = pickupType:gsub("(%l)(%u)", "%1 %2")
	return normalized
end

function PickupHandler:Initialize()
	
	-- Handle pickup requests from clients
	local pickupEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupItem")
	if pickupEvent then
		pickupEvent.OnServerEvent:Connect(function(player, pickupData)
			self:HandlePickupRequest(player, pickupData)
		end)
	end
	
	-- Handle spawn pickup requests  
	local spawnEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SpawnPickup")
	if spawnEvent then
		spawnEvent.OnServerEvent:Connect(function(player, spawnData)
			-- Only allow admins/devs to spawn pickups
			if self:IsPlayerAdmin(player) then
				self:SpawnPickup(spawnData.PickupType, spawnData.Position)
			end
		end)
	end
	
	-- Initialize spawn points
	self:LoadSpawnPoints()
	
	-- Start pickup management loop
	self:StartPickupLoop()
	
	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerData(player)
	end)
	
	_G.PickupHandler = self
	print("PickupHandler initialized")
end

function PickupHandler:LoadSpawnPoints()
	-- Scan workspace and ServerStorage for pickup spawn point parts
	-- Spawn points should be named: "PickupSpawn_[PickupType]"
	-- Example: "PickupSpawn_HealthPack", "PickupSpawn_LightArmor"

	local function scanFolder(folder)
		for _, child in pairs(folder:GetChildren()) do
			if child:IsA("Part") and child.Name:match("^PickupSpawn_") then
				-- Extract pickup type from part name
				local pickupType = child.Name:gsub("^PickupSpawn_", "")

				-- Normalize the pickup type (convert PascalCase to spaced names)
				local normalizedType = NormalizePickupType(pickupType)

				-- Validate pickup type exists in configs
				local config = self:GetPickupConfig(normalizedType)
				if config then
					table.insert(pickupSpawnPoints, {
						Part = child,
						Type = normalizedType,  -- Store normalized type
						Position = child.Position,
						Active = false, -- Track if pickup is currently spawned
						SpawnId = nil -- Track which pickup is at this point
					})
					print("✓ Found pickup spawn point:", normalizedType, "at", tostring(child.Position))
				else
					warn("Invalid pickup type in spawn point name:", pickupType, "-> normalized to:", normalizedType)
					warn("Available types: Health Pack, Medical Kit, Adrenaline, Light Armor, Heavy Armor, Riot Armor, Pistol Ammo, Rifle Ammo, etc.")
				end
			elseif child:IsA("Folder") or child:IsA("Model") then
				-- Recursively scan folders
				scanFolder(child)
			end
		end
	end

	-- Scan workspace
	scanFolder(workspace)

	-- Also scan ServerStorage if it has a PickupSpawns folder
	if ServerStorage:FindFirstChild("PickupSpawns") then
		scanFolder(ServerStorage.PickupSpawns)
	end

	print("Loaded " .. #pickupSpawnPoints .. " pickup spawn points from map")

	-- If no spawn points found, warn the user
	if #pickupSpawnPoints == 0 then
		warn("⚠ No pickup spawn points found in workspace!")
		warn("To create pickup spawns, add Parts to workspace named: PickupSpawn_[Type]")
		warn("Examples: PickupSpawn_HealthPack, PickupSpawn_LightArmor, PickupSpawn_RifleAmmo")
	end
end

function PickupHandler:StartPickupLoop()
	-- Initial spawn of all pickups
	spawn(function()
		wait(3) -- Wait for map to load
		self:SpawnInitialPickups()
	end)

	-- Respawn loop (checks every 2 seconds)
	spawn(function()
		while true do
			wait(2)
			self:CheckRespawns()
		end
	end)
end

function PickupHandler:CheckRespawns()
	local currentTime = tick()

	-- Check each spawn point for respawns
	for _, spawnPoint in pairs(pickupSpawnPoints) do
		-- If spawn point is inactive and has a respawn time
		if not spawnPoint.Active and spawnPoint.RespawnTime then
			if currentTime >= spawnPoint.RespawnTime then
				-- Respawn the pickup
				self:SpawnPickupAtPoint(spawnPoint)
				spawnPoint.RespawnTime = nil
			end
		end
	end
end

function PickupHandler:SpawnInitialPickups()
	-- Spawn a pickup at every spawn point
	for _, spawnPoint in pairs(pickupSpawnPoints) do
		self:SpawnPickupAtPoint(spawnPoint)
	end
	print("Spawned", #pickupSpawnPoints, "initial pickups")
end

function PickupHandler:SpawnPickupAtPoint(spawnPoint)
	if spawnPoint.Active then
		-- Pickup already spawned at this point
		return
	end

	local pickupType = spawnPoint.Type
	local config = self:GetPickupConfig(pickupType)
	if not config then return end

	-- Generate unique pickup ID
	local pickupId = "Pickup_" .. pickupType .. "_" .. tick()

	-- Store pickup data
	activePickups[pickupId] = {
		type = pickupType,
		position = spawnPoint.Position,
		spawnTime = tick(),
		taken = false,
		spawnPoint = spawnPoint
	}

	-- Mark spawn point as active
	spawnPoint.Active = true
	spawnPoint.SpawnId = pickupId

	-- Notify all clients to create visual pickup
	local pickupSpawnedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupSpawned")
	if pickupSpawnedEvent then
		pickupSpawnedEvent:FireAllClients({
			PickupId = pickupId,
			PickupType = pickupType,
			Position = spawnPoint.Position
		})
	end

	print("Spawned pickup:", pickupType, "at", tostring(spawnPoint.Position))
end

function PickupHandler:HandlePickupRequest(player, pickupData)
	local pickupId = pickupData.PickupId
	local pickup = activePickups[pickupId]

	if not pickup or pickup.taken then
		-- Pickup doesn't exist or was already taken
		return
	end

	-- Validate distance (anti-cheat)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local distance = (character.HumanoidRootPart.Position - pickup.position).Magnitude
	if distance > 8 then -- 8 stud max (5 stud client range + 3 stud buffer for lag)
		warn("Player", player.Name, "tried to pick up from too far:", distance, "studs")
		return
	end

	-- Apply pickup effects to player
	local success = self:ApplyPickupToPlayer(player, pickup.type)
	if success then
		-- Mark as taken
		pickup.taken = true

		-- Get pickup config for respawn time
		local config = self:GetPickupConfig(pickup.type)

		-- Schedule respawn at spawn point
		if pickup.spawnPoint and config and config.RespawnTime then
			pickup.spawnPoint.Active = false
			pickup.spawnPoint.SpawnId = nil
			pickup.spawnPoint.RespawnTime = tick() + config.RespawnTime

			print("Pickup will respawn in", config.RespawnTime, "seconds at", tostring(pickup.position))
		end

		-- Remove pickup from active list
		activePickups[pickupId] = nil

		-- Notify all clients to remove visual
		local pickupRemovedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupRemoved")
		if pickupRemovedEvent then
			pickupRemovedEvent:FireAllClients(pickupId)
		end

		-- Notify the player that they picked it up
		local pickupTakenEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupTaken")
		if pickupTakenEvent then
			pickupTakenEvent:FireClient(player, {
				PickupType = pickup.type,
				PickupId = pickupId
			})
		end

		print(player.Name .. " picked up " .. pickup.type)
	end
end

function PickupHandler:ApplyPickupToPlayer(player, pickupType)
	local config = self:GetPickupConfig(pickupType)
	if not config then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return false
	end

	-- Apply effects based on pickup type
	if config.Type == "Medical" then
		-- Heal player
		if config.HealAmount then
			local newHealth = math.min(humanoid.MaxHealth, humanoid.Health + config.HealAmount)
			humanoid.Health = newHealth
			print("Healed", player.Name, "for", config.HealAmount, "HP")
		end

		-- Remove status effects
		if config.RemoveStatusEffects then
			local statusSystem = _G.StatusEffectsSystem
			if statusSystem then
				statusSystem:CureAllStatusEffects(player)
				print("Removed negative status effects from", player.Name)
			end
		end

		-- Apply status effect
		if config.StatusEffect then
			local statusSystem = _G.StatusEffectsSystem
			if statusSystem then
				statusSystem:ApplyStatusEffect(player, config.StatusEffect, config.Duration or 30)
				print("Applied", config.StatusEffect, "to", player.Name)
			end
		end

	elseif config.Type == "Armor" then
		-- Add armor using player attributes
		local currentArmor = player:GetAttribute("Armor") or 0
		local newArmor = math.min(100, currentArmor + config.ArmorValue)
		player:SetAttribute("Armor", newArmor)
		print("Applied", config.ArmorValue, "armor to", player.Name, "(total:", newArmor .. ")")

	elseif config.Type == "Ammo" then
		-- Add ammunition via AmmoResupply RemoteEvent
		local ammoEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AmmoResupply")
		if ammoEvent then
			ammoEvent:FireClient(player, {
				AmmoType = config.AmmoType,
				Amount = config.AmmoAmount
			})
			print("Gave", config.AmmoAmount, config.AmmoType, "ammo to", player.Name)
		else
			warn("AmmoResupply RemoteEvent not found")
		end

	elseif config.Type == "Equipment" then
		-- Give equipment using player attributes
		player:SetAttribute("Equipment_" .. config.Equipment, true)

		-- Apply temporary effects if specified
		if config.StatusEffect then
			local statusSystem = _G.StatusEffectsSystem
			if statusSystem then
				statusSystem:ApplyStatusEffect(player, config.StatusEffect, config.Duration or 60)
			end
		end

		-- Schedule removal if equipment has duration
		if config.Duration then
			spawn(function()
				wait(config.Duration)
				player:SetAttribute("Equipment_" .. config.Equipment, false)
				print("Removed", config.Equipment, "from", player.Name)
			end)
		end

		print("Gave", config.Equipment, "to", player.Name)

	elseif config.Type == "Powerup" then
		-- Apply powerup status effect
		if config.StatusEffect then
			local statusSystem = _G.StatusEffectsSystem
			if statusSystem then
				statusSystem:ApplyStatusEffect(player, config.StatusEffect, config.Duration or 30)
				print("Applied powerup", config.StatusEffect, "to", player.Name)
			else
				-- Fallback if StatusEffectsSystem not available
				player:SetAttribute("StatusEffect_" .. config.StatusEffect, true)

				spawn(function()
					wait(config.Duration or 30)
					player:SetAttribute("StatusEffect_" .. config.StatusEffect, false)
				end)

				print("Applied powerup", config.StatusEffect, "to", player.Name, "(fallback)")
			end
		end
	end

	-- Award XP for pickup
	local xpReward = 10
	if config.Rarity == "Uncommon" then
		xpReward = 15
	elseif config.Rarity == "Rare" then
		xpReward = 25
	elseif config.Rarity == "Epic" then
		xpReward = 40
	elseif config.Rarity == "Legendary" then
		xpReward = 75
	end

	if DataStoreManager and DataStoreManager.AddXP then
		DataStoreManager:AddXP(player, xpReward, "Item Pickup")
	end

	return true
end

function PickupHandler:SpawnPickup(pickupType, position, pickupId)
	-- Spawn a pickup at a custom position (for admin commands)
	local config = self:GetPickupConfig(pickupType)
	if not config then
		warn("Invalid pickup type:", pickupType)
		return
	end

	pickupId = pickupId or "Pickup_" .. pickupType .. "_" .. tick()

	-- Store pickup data (no spawn point for custom spawns)
	activePickups[pickupId] = {
		type = pickupType,
		position = position,
		spawnTime = tick(),
		taken = false,
		spawnPoint = nil -- Custom spawns don't have spawn points
	}

	-- Notify all clients to create visual
	local pickupSpawnedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupSpawned")
	if pickupSpawnedEvent then
		pickupSpawnedEvent:FireAllClients({
			PickupId = pickupId,
			PickupType = pickupType,
			Position = position
		})
	end

	print("Admin spawned pickup:", pickupType, "at", tostring(position))
end

function PickupHandler:RemovePickup(pickupId)
	-- Remove from active pickups
	local pickup = activePickups[pickupId]
	if pickup then
		-- Clear spawn point if it exists
		if pickup.spawnPoint then
			pickup.spawnPoint.Active = false
			pickup.spawnPoint.SpawnId = nil
		end

		activePickups[pickupId] = nil
	end

	-- Remove visual from all clients
	local pickupRemovedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupRemoved")
	if pickupRemovedEvent then
		pickupRemovedEvent:FireAllClients(pickupId)
	end

	-- Also destroy the part in workspace if it exists
	local pickupPart = workspace:FindFirstChild(pickupId)
	if pickupPart then
		pickupPart:Destroy()
	end
end

function PickupHandler:GetPickupConfig(pickupType)
	-- Mirror of client-side config
	local PICKUP_CONFIGS = {
		-- Armor pickups
		["Light Armor"] = {Type = "Armor", ArmorValue = 25, RespawnTime = 45, Rarity = "Common"},
		["Heavy Armor"] = {Type = "Armor", ArmorValue = 50, RespawnTime = 90, Rarity = "Rare"},
		["Riot Armor"] = {Type = "Armor", ArmorValue = 100, RespawnTime = 120, Rarity = "Epic"},
		
		-- Medical pickups
		["Health Pack"] = {Type = "Medical", HealAmount = 50, RespawnTime = 30, Rarity = "Common"},
		["Medical Kit"] = {Type = "Medical", HealAmount = 100, RemoveStatusEffects = true, RespawnTime = 60, Rarity = "Rare"},
		["Adrenaline"] = {Type = "Medical", StatusEffect = "Adrenaline", Duration = 30, RespawnTime = 90, Rarity = "Rare"},
		
		-- Ammunition pickups
		["Pistol Ammo"] = {Type = "Ammo", AmmoType = "9mm", AmmoAmount = 30, RespawnTime = 20, Rarity = "Common"},
		["Rifle Ammo"] = {Type = "Ammo", AmmoType = "556", AmmoAmount = 60, RespawnTime = 25, Rarity = "Common"},
		["Sniper Ammo"] = {Type = "Ammo", AmmoType = "762", AmmoAmount = 20, RespawnTime = 40, Rarity = "Uncommon"},
		["Shotgun Shells"] = {Type = "Ammo", AmmoType = "12gauge", AmmoAmount = 16, RespawnTime = 30, Rarity = "Uncommon"},
		
		-- Equipment pickups
		["Night Vision"] = {Type = "Equipment", Equipment = "NVG", RespawnTime = 120, Rarity = "Epic"},
		["Thermal Scope"] = {Type = "Equipment", Equipment = "Thermal", RespawnTime = 150, Rarity = "Epic"},
		["Ghillie Suit"] = {Type = "Equipment", Equipment = "Ghillie", StatusEffect = "Camouflaged", Duration = 120, RespawnTime = 180, Rarity = "Legendary"},
		
		-- Special pickups
		["Speed Boost"] = {Type = "Powerup", StatusEffect = "SpeedBoost", Duration = 20, RespawnTime = 60, Rarity = "Rare"},
		["Damage Boost"] = {Type = "Powerup", StatusEffect = "DamageBoost", Duration = 15, RespawnTime = 75, Rarity = "Rare"},
		["Shield Generator"] = {Type = "Powerup", Equipment = "Shield", Duration = 45, RespawnTime = 120, Rarity = "Epic"}
	}
	
	return PICKUP_CONFIGS[pickupType]
end

function PickupHandler:IsPlayerAdmin(player)
	-- Check if player is admin
	-- Integrate with your admin system
	if _G.AdminSystem then
		return _G.AdminSystem:IsAdmin(player)
	end

	-- Fallback: game creator is always admin
	return player.UserId == game.CreatorId
end

function PickupHandler:CleanupPlayerData(player)
	-- Clean up any player-specific pickup data
	-- Currently no per-player data to clean up
end

function PickupHandler:GetActivePickups()
	return activePickups
end

function PickupHandler:GetSpawnPoints()
	return pickupSpawnPoints
end

-- Admin commands (accessible via _G.AdminPickupCommands)
_G.AdminPickupCommands = {
	spawnPickup = function(pickupType, x, y, z)
		local position = Vector3.new(tonumber(x) or 0, tonumber(y) or 10, tonumber(z) or 0)
		PickupHandler:SpawnPickup(pickupType, position)
		print("Spawned " .. pickupType .. " at " .. tostring(position))
	end,

	clearAllPickups = function()
		for pickupId, _ in pairs(activePickups) do
			PickupHandler:RemovePickup(pickupId)
		end
		activePickups = {}
		print("Cleared all pickups")
	end,

	listActivePickups = function()
		print("Active pickups:")
		local count = 0
		for pickupId, pickup in pairs(activePickups) do
			local status = pickup.taken and "TAKEN" or "ACTIVE"
			print("- " .. pickupId .. ": " .. pickup.type .. " (" .. status .. ")")
			count = count + 1
		end
		print("Total:", count, "active pickups")
	end,

	listSpawnPoints = function()
		print("Pickup spawn points:")
		for i, spawnPoint in pairs(pickupSpawnPoints) do
			local status = spawnPoint.Active and "OCCUPIED" or "EMPTY"
			local respawn = ""
			if spawnPoint.RespawnTime then
				local timeLeft = math.ceil(spawnPoint.RespawnTime - tick())
				respawn = " (respawns in " .. timeLeft .. "s)"
			end
			print(i .. ". " .. spawnPoint.Type .. " at " .. tostring(spawnPoint.Position) .. " [" .. status .. "]" .. respawn)
		end
		print("Total:", #pickupSpawnPoints, "spawn points")
	end,

	respawnAllPickups = function()
		-- Clear all active pickups and respawn at spawn points
		for pickupId, _ in pairs(activePickups) do
			PickupHandler:RemovePickup(pickupId)
		end

		-- Reset all spawn points
		for _, spawnPoint in pairs(pickupSpawnPoints) do
			spawnPoint.Active = false
			spawnPoint.SpawnId = nil
			spawnPoint.RespawnTime = nil
		end

		-- Spawn fresh pickups
		PickupHandler:SpawnInitialPickups()
		print("Respawned all pickups")
	end,

	testPickup = function(pickupType)
		-- Spawn a pickup in front of the calling player (must be run in command bar as player)
		local Players = game:GetService("Players")
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local pos = player.Character.HumanoidRootPart.Position + player.Character.HumanoidRootPart.CFrame.LookVector * 5
				PickupHandler:SpawnPickup(pickupType, pos)
				print("Spawned", pickupType, "in front of", player.Name)
				return
			end
		end
	end,

	listPickupTypes = function()
		print("Available pickup types:")
		local types = {}
		for pickupType, config in pairs(PickupHandler:GetPickupConfig("Health Pack") and PICKUP_CONFIGS or {}) do
			table.insert(types, pickupType)
		end
		table.sort(types)
		for _, pickupType in pairs(types) do
			local config = PickupHandler:GetPickupConfig(pickupType)
			print("- " .. pickupType .. " (" .. config.Type .. ", " .. config.Rarity .. ")")
		end
	end
}

PickupHandler:Initialize()

return PickupHandler