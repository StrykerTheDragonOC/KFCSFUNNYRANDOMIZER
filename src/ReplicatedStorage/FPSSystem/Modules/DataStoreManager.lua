local DataStoreManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)

-- DataStore variables (server-side only)
local DataStoreService = nil
local playerDataStore = nil
local weaponStatsStore = nil

-- Initialize DataStores only on server
if RunService:IsServer() then
    DataStoreService = game:GetService("DataStoreService")
    playerDataStore = DataStoreService:GetDataStore("PlayerData_v1")
    weaponStatsStore = DataStoreService:GetDataStore("WeaponStats_v1")
end

local playerData = {}
local saveQueue = {}

-- DataStore request throttling system
local REQUEST_THROTTLING = {
	maxRequestsPerMinute = 60, -- Roblox limit
	requestQueue = {},
	requestTimes = {},
	lastRequestTime = 0,
	isProcessingQueue = false
}

-- DataStore request throttling functions
local function cleanOldRequestTimes()
	local currentTime = tick()
	local oneMinuteAgo = currentTime - 60

	for i = #REQUEST_THROTTLING.requestTimes, 1, -1 do
		if REQUEST_THROTTLING.requestTimes[i] < oneMinuteAgo then
			table.remove(REQUEST_THROTTLING.requestTimes, i)
		end
	end
end

local function canMakeRequest()
	cleanOldRequestTimes()
	return #REQUEST_THROTTLING.requestTimes < REQUEST_THROTTLING.maxRequestsPerMinute
end

local function recordRequest()
	table.insert(REQUEST_THROTTLING.requestTimes, tick())
	REQUEST_THROTTLING.lastRequestTime = tick()
end

local function throttledDataStoreRequest(requestFunction, requestData, onSuccess, onFailure)
	table.insert(REQUEST_THROTTLING.requestQueue, {
		requestFunction = requestFunction,
		requestData = requestData,
		onSuccess = onSuccess,
		onFailure = onFailure,
		timestamp = tick()
	})

	if not REQUEST_THROTTLING.isProcessingQueue then
		spawn(function()
			REQUEST_THROTTLING.isProcessingQueue = true

			while #REQUEST_THROTTLING.requestQueue > 0 do
				if canMakeRequest() then
					local request = table.remove(REQUEST_THROTTLING.requestQueue, 1)
					recordRequest()

					local success, result = pcall(request.requestFunction, request.requestData)

					if success then
						if request.onSuccess then
							request.onSuccess(result)
						end
					else
						warn("DataStore request failed:", result)
						if request.onFailure then
							request.onFailure(result)
						end
					end
				else
					-- Wait before checking again
					wait(1)
				end
			end

			REQUEST_THROTTLING.isProcessingQueue = false
		end)
	end
end

local DEFAULT_PLAYER_DATA = {
	-- Core Progression
	Level = 0,
	XP = 0,
	Credits = 150, -- Starting credits for rank 0
	
	-- Comprehensive Stats
	Stats = {
		TotalKills = 0,
		TotalDeaths = 0,
		TotalAssists = 0,
		TotalMatches = 0,
		TotalXP = 0,
		TotalScore = 0,
		PlayTime = 0,
		
		-- Detailed Combat Stats
		HeadshotKills = 0,
		LongDistanceKills = 0,
		WallbangKills = 0,
		BackstabKills = 0,
		QuickscopeKills = 0,
		NoScopeKills = 0,
		
		-- Multi-kill Stats
		DoubleKills = 0,
		TripleKills = 0,
		QuadKills = 0,
		HighestKillStreak = 0,
		
		-- Objective Stats
		ObjectiveCaptures = 0,
		ObjectiveDefends = 0,
		ObjectiveTime = 0,
		
		-- Spotted System Stats
		EnemiesSpotted = 0,
		SpottedKills = 0,
		SpottedAssists = 0
	},
	
	-- Weapon Mastery System
	WeaponStats = {
		-- [WeaponName] = {
		--     Kills = number,
		--     MasteryLevel = number,
		--     Headshots = number,
		--     LongDistanceShots = number,
		--     Wallbangs = number,
		--     UnlockedAttachments = {attachment1, attachment2, ...}
		-- }
	},
	
	-- Unlocks System
	Unlocks = {
		Weapons = {"G36", "M9", "PocketKnife", "M67"}, -- Default weapons
		Attachments = {},
		Skins = {},
		Perks = {}
	},
	
	-- Player Preferences
	Settings = {
		Sensitivity = 1.0,
		FOV = 90,
		RagdollFactor = 1.0,
		ScopeMode = "3D", -- "3D" or "UI"
		CrosshairStyle = "Default",
		MasterVolume = 1.0,
		EffectsVolume = 1.0
	},
	
	-- Current Match Data (resets each match)
	MatchStats = {
		Kills = 0,
		Deaths = 0,
		Assists = 0,
		Score = 0,
		KillStreak = 0,
		BestStreak = 0,
		HeadshotCount = 0,
		ObjectivesCompleted = 0,
		XPGained = 0,
		Team = nil,
		Class = "Assault"
	},
	
	-- Session Data (resets each session)
	SessionStats = {
		MatchesPlayed = 0,
		TotalKills = 0,
		TotalDeaths = 0,
		TotalXP = 0,
		PlayTime = 0,
		LoginTime = 0
	},
	
	-- Loadout Configuration
	Loadouts = {
		Assault = {
			Primary = "G36",
			Secondary = "M9", 
			Melee = "PocketKnife",
			Grenade = "M67",
			Attachments = {
				Primary = {},
				Secondary = {}
			}
		},
		Scout = {
			Primary = "G36",
			Secondary = "M9",
			Melee = "PocketKnife", 
			Grenade = "M67",
			Attachments = {
				Primary = {},
				Secondary = {}
			}
		},
		Support = {
			Primary = "G36",
			Secondary = "M9",
			Melee = "PocketKnife",
			Grenade = "M67",
			Attachments = {
				Primary = {},
				Secondary = {}
			}
		},
		Recon = {
			Primary = "G36", 
			Secondary = "M9",
			Melee = "PocketKnife",
			Grenade = "M67",
			Attachments = {
				Primary = {},
				Secondary = {}
			}
		}
	},
	
	-- Legacy compatibility fields
	UnlockedWeapons = {"G36", "M9", "PocketKnife", "M67"},
	UnlockedAttachments = {},
	UnlockedSkins = {}
}

function DataStoreManager:Initialize()
	GameConfig:Initialize()

	print("DataStoreManager initialized")
end

function DataStoreManager:LoadPlayerData(player)
	-- Server-side only
	if not RunService:IsServer() then
		warn("DataStoreManager:LoadPlayerData can only be called on server")
		return
	end

	-- Use throttled request system
	throttledDataStoreRequest(
		function(userId) return playerDataStore:GetAsync(userId) end,
		player.UserId,
		function(data)
			-- Success callback
			if data then
				playerData[player] = self:MergeWithDefaults(data, DEFAULT_PLAYER_DATA)
			else
				playerData[player] = self:MergeWithDefaults({}, DEFAULT_PLAYER_DATA)
			end
			print("Loaded data for player:", player.Name)
		end,
		function(error)
			-- Failure callback - use default data
			warn("Failed to load data for player:", player.Name, "Error:", error)
			playerData[player] = self:MergeWithDefaults({}, DEFAULT_PLAYER_DATA)
		end
	)
end

function DataStoreManager:SavePlayerData(player)
	-- Server-side only
	if not RunService:IsServer() then
		warn("DataStoreManager:SavePlayerData can only be called on server")
		return
	end

	local data = playerData[player]
	if not data then return end

	-- Use throttled request system
	throttledDataStoreRequest(
		function(saveData)
			return playerDataStore:SetAsync(saveData.userId, saveData.data)
		end,
		{userId = player.UserId, data = data},
		function(result)
			-- Success callback
			print("Successfully saved data for player:", player.Name)
		end,
		function(error)
			-- Failure callback
			warn("Failed to save data for player:", player.Name, "Error:", error)
		end
	)
end

function DataStoreManager:CleanupPlayerData(player)
	playerData[player] = nil
	saveQueue[player] = nil
end

function DataStoreManager:GetPlayerData(player, key)
	local data = playerData[player]
	if not data then return nil end
	
	if key then
		return data[key]
	else
		return data
	end
end

function DataStoreManager:SetPlayerData(player, key, value)
	local data = playerData[player]
	if not data then return false end
	
	data[key] = value
	saveQueue[player] = true
	return true
end

function DataStoreManager:UpdatePlayerStat(player, statName, value, isIncrement)
	local data = playerData[player]
	if not data then return false end
	
	if isIncrement then
		data.Stats[statName] = (data.Stats[statName] or 0) + value
	else
		data.Stats[statName] = value
	end
	
	saveQueue[player] = true
	return true
end

function DataStoreManager:UpdateMatchStat(player, statName, value, isIncrement)
	local data = playerData[player]
	if not data then return false end
	
	if isIncrement then
		data.MatchStats[statName] = (data.MatchStats[statName] or 0) + value
	else
		data.MatchStats[statName] = value
	end
	
	return true
end

function DataStoreManager:AddXP(player, amount, reason)
	local data = playerData[player]
	if not data then return false end
	
	local oldLevel = data.Level
	data.XP = data.XP + amount
	data.Stats.TotalXP = data.Stats.TotalXP + amount
	
	local newLevel = self:CalculateLevelFromXP(data.XP)
	
	if newLevel > oldLevel then
		local creditsEarned = self:CalculateLevelReward(newLevel)
		data.Level = newLevel
		data.Credits = data.Credits + creditsEarned

		local levelUpEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("LevelUp")
		if levelUpEvent then
			levelUpEvent:FireClient(player, {
				NewLevel = newLevel,
				CreditsEarned = creditsEarned,
				XPGained = amount,
				Reason = reason
			})
		end
		
		print(player.Name .. " leveled up to " .. newLevel .. " and earned " .. creditsEarned .. " credits")
	end

	local xpAwardedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("XPAwarded")
	if xpAwardedEvent then
		xpAwardedEvent:FireClient(player, {
			Amount = amount,
			Reason = reason,
			NewXP = data.XP,
			NextLevelXP = self:CalculateXPForLevel(newLevel + 1)
		})
	end
	
	saveQueue[player] = true
	return true
end

function DataStoreManager:CalculateLevelFromXP(totalXP)
	local level = 0
	local requiredXP = 0
	
	while requiredXP <= totalXP do
		level = level + 1
		requiredXP = requiredXP + self:CalculateXPForLevel(level)
	end
	
	return math.max(0, level - 1)
end

function DataStoreManager:CalculateXPForLevel(level)
	return 1000 * ((level^2 + level) / 2)
end

function DataStoreManager:CalculateLevelReward(level)
	if level <= 20 then
		return ((level - 1) * 5) + 200
	else
		return (level * 5) + 200
	end
end

function DataStoreManager:GetPlayerLevel(player)
	local data = playerData[player]
	return data and data.Level or 0
end

function DataStoreManager:GetPlayerCredits(player)
	local data = playerData[player]
	return data and data.Credits or 0
end

function DataStoreManager:SpendCredits(player, amount)
	local data = playerData[player]
	if not data or data.Credits < amount then
		return false
	end
	
	data.Credits = data.Credits - amount
	saveQueue[player] = true
	return true
end

function DataStoreManager:AddCredits(player, amount)
	local data = playerData[player]
	if not data then return false end
	
	data.Credits = data.Credits + amount
	saveQueue[player] = true
	return true
end

function DataStoreManager:UnlockWeapon(player, weaponName, cost)
	local data = playerData[player]
	if not data then return false end
	
	if not table.find(data.Unlocks.Weapons, weaponName) then
		-- Spend credits if cost is provided
		if cost and data.Credits >= cost then
			data.Credits = data.Credits - cost
		elseif cost then
			return false -- Not enough credits
		end
		
		table.insert(data.Unlocks.Weapons, weaponName)
		-- Sync compatibility field
		data.UnlockedWeapons = data.Unlocks.Weapons
		saveQueue[player] = true
		return true
	end
	
	return false
end

function DataStoreManager:HasWeaponUnlocked(player, weaponName)
	local data = playerData[player]
	if not data then return false end
	
	return table.find(data.Unlocks.Weapons, weaponName) ~= nil
end

function DataStoreManager:GetClientSafeData(data)
	if not data then return nil end
	
	-- Return a copy of data with only client-safe fields
	return {
		Level = data.Level,
		XP = data.XP,
		Credits = data.Credits,
		UnlockedWeapons = data.UnlockedWeapons or data.Unlocks.Weapons,
		UnlockedAttachments = data.UnlockedAttachments or data.Unlocks.Attachments,
		UnlockedSkins = data.UnlockedSkins or data.Unlocks.Skins,
		Stats = data.Stats,
		Settings = data.Settings,
		MatchStats = data.MatchStats
	}
end

function DataStoreManager:ResetMatchStats(player)
	local data = playerData[player]
	if not data then return end
	
	data.MatchStats = {
		Kills = 0,
		Deaths = 0,
		Assists = 0,
		Score = 0,
		KillStreak = 0,
		BestStreak = 0
	}
end

function DataStoreManager:AutoSaveAllPlayers()
	for player, needsSave in pairs(saveQueue) do
		if needsSave then
			self:SavePlayerData(player)
			saveQueue[player] = false
		end
	end
end

function DataStoreManager:SaveAllPlayerData()
	for player, _ in pairs(playerData) do
		self:SavePlayerData(player)
	end
end

function DataStoreManager:MergeWithDefaults(data, defaults)
	local result = {}
	
	for key, defaultValue in pairs(defaults) do
		if data[key] ~= nil then
			if type(defaultValue) == "table" and type(data[key]) == "table" then
				result[key] = self:MergeWithDefaults(data[key], defaultValue)
			else
				result[key] = data[key]
			end
		else
			result[key] = self:DeepCopy(defaultValue)
		end
	end
	
	-- Ensure compatibility fields are synchronized
	result = self:SyncCompatibilityFields(result)
	return result
end

function DataStoreManager:SyncCompatibilityFields(data)
	-- Sync UnlockedWeapons with Unlocks.Weapons
	if data.Unlocks and data.Unlocks.Weapons then
		data.UnlockedWeapons = data.Unlocks.Weapons
	elseif data.UnlockedWeapons then
		if not data.Unlocks then data.Unlocks = {} end
		data.Unlocks.Weapons = data.UnlockedWeapons
	end
	
	-- Sync UnlockedAttachments with Unlocks.Attachments
	if data.Unlocks and data.Unlocks.Attachments then
		data.UnlockedAttachments = data.Unlocks.Attachments
	elseif data.UnlockedAttachments then
		if not data.Unlocks then data.Unlocks = {} end
		data.Unlocks.Attachments = data.UnlockedAttachments
	end
	
	-- Ensure UnlockedAttachments is properly structured
	if not data.UnlockedAttachments or type(data.UnlockedAttachments) ~= "table" then
		data.UnlockedAttachments = {}
	end
	
	-- Initialize attachment tables for each weapon
	if data.UnlockedWeapons then
		for _, weaponName in pairs(data.UnlockedWeapons) do
			if not data.UnlockedAttachments[weaponName] then
				data.UnlockedAttachments[weaponName] = {}
			end
		end
	end
	
	-- Sync UnlockedSkins with Unlocks.Skins
	if data.Unlocks and data.Unlocks.Skins then
		data.UnlockedSkins = data.Unlocks.Skins
	elseif data.UnlockedSkins then
		if not data.Unlocks then data.Unlocks = {} end
		data.Unlocks.Skins = data.UnlockedSkins
	end
	
	return data
end

function DataStoreManager:DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	
	local copy = {}
	
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = self:DeepCopy(value)
		else
			copy[key] = value
		end
	end
	
	return copy
end

-- Weapon Mastery System Functions
function DataStoreManager:InitializeWeaponStats(player, weaponName)
	local data = playerData[player]
	if not data or not data.WeaponStats then return false end
	
	if not data.WeaponStats[weaponName] then
		data.WeaponStats[weaponName] = {
			Kills = 0,
			MasteryLevel = 0,
			Headshots = 0,
			LongDistanceShots = 0,
			Wallbangs = 0,
			UnlockedAttachments = {}
		}
		saveQueue[player] = true
	end
	
	return true
end

function DataStoreManager:AddWeaponKill(player, weaponName, killData)
	local data = playerData[player]
	if not data then return false end
	
	self:InitializeWeaponStats(player, weaponName)
	
	local weaponStats = data.WeaponStats[weaponName]
	weaponStats.Kills = weaponStats.Kills + 1
	
	-- Track specific kill types
	if killData and killData.IsHeadshot then
		weaponStats.Headshots = weaponStats.Headshots + 1
	end
	if killData and killData.Distance and killData.Distance > 200 then
		weaponStats.LongDistanceShots = weaponStats.LongDistanceShots + 1
	end
	if killData and killData.IsWallbang then
		weaponStats.Wallbangs = weaponStats.Wallbangs + 1
	end
	
	-- Check for mastery level up
	local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
	local masteryRequirements = WeaponConfig:GetWeaponMasteryRequirements(weaponName)
	
	local currentMastery = weaponStats.MasteryLevel
	local newMasteryLevel = currentMastery
	
	for _, requirement in pairs(masteryRequirements) do
		if weaponStats.Kills >= requirement.Kills and requirement.Level > currentMastery then
			newMasteryLevel = requirement.Level
			
			-- Unlock attachment reward
			local attachmentName = requirement.Reward
			if not table.find(weaponStats.UnlockedAttachments, attachmentName) then
				table.insert(weaponStats.UnlockedAttachments, attachmentName)
				
				-- Add to global unlocks
				if not data.Unlocks.Attachments[weaponName] then
					data.Unlocks.Attachments[weaponName] = {}
				end
				table.insert(data.Unlocks.Attachments[weaponName], attachmentName)
				
				-- Fire mastery unlock event
				local masteryUnlockEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("WeaponMasteryUnlock")
				if masteryUnlockEvent then
					masteryUnlockEvent:FireClient(player, {
						WeaponName = weaponName,
						MasteryLevel = newMasteryLevel,
						Reward = attachmentName,
						TotalKills = weaponStats.Kills
					})
				end
				
				print(player.Name .. " unlocked " .. attachmentName .. " for " .. weaponName .. " (Mastery Level " .. newMasteryLevel .. ")")
			end
		end
	end
	
	weaponStats.MasteryLevel = newMasteryLevel
	saveQueue[player] = true
	return true
end

function DataStoreManager:GetWeaponStats(player, weaponName)
	local data = playerData[player]
	if not data or not data.WeaponStats then return nil end
	
	return data.WeaponStats[weaponName]
end

function DataStoreManager:GetWeaponKills(player, weaponName)
	local weaponStats = self:GetWeaponStats(player, weaponName)
	return weaponStats and weaponStats.Kills or 0
end

function DataStoreManager:GetWeaponMasteryLevel(player, weaponName)
	local weaponStats = self:GetWeaponStats(player, weaponName)
	return weaponStats and weaponStats.MasteryLevel or 0
end

function DataStoreManager:HasAttachmentUnlocked(player, weaponName, attachmentName)
	local data = playerData[player]
	if not data then return false end
	
	local weaponStats = data.WeaponStats[weaponName]
	if weaponStats and weaponStats.UnlockedAttachments then
		return table.find(weaponStats.UnlockedAttachments, attachmentName) ~= nil
	end
	
	-- Check global unlocks as fallback
	if data.Unlocks.Attachments[weaponName] then
		return table.find(data.Unlocks.Attachments[weaponName], attachmentName) ~= nil
	end
	
	return false
end

-- Loadout Management Functions
function DataStoreManager:GetPlayerLoadout(player, className)
	local data = playerData[player]
	if not data or not data.Loadouts then return nil end
	
	return data.Loadouts[className]
end

function DataStoreManager:SetPlayerLoadout(player, className, loadout)
	local data = playerData[player]
	if not data or not data.Loadouts then return false end
	
	data.Loadouts[className] = loadout
	saveQueue[player] = true
	return true
end

function DataStoreManager:UpdateLoadoutWeapon(player, className, slot, weaponName)
	local data = playerData[player]
	if not data or not data.Loadouts or not data.Loadouts[className] then return false end
	
	data.Loadouts[className][slot] = weaponName
	saveQueue[player] = true
	return true
end

function DataStoreManager:UpdateLoadoutAttachment(player, className, weaponSlot, attachmentSlot, attachmentName)
	local data = playerData[player]
	if not data or not data.Loadouts or not data.Loadouts[className] then return false end
	
	if not data.Loadouts[className].Attachments then
		data.Loadouts[className].Attachments = {Primary = {}, Secondary = {}}
	end
	if not data.Loadouts[className].Attachments[weaponSlot] then
		data.Loadouts[className].Attachments[weaponSlot] = {}
	end
	
	data.Loadouts[className].Attachments[weaponSlot][attachmentSlot] = attachmentName
	saveQueue[player] = true
	return true
end

-- Advanced Statistics Functions
function DataStoreManager:RecordKill(player, killData)
	local data = playerData[player]
	if not data then return false end
	
	-- Update match stats
	data.MatchStats.Kills = data.MatchStats.Kills + 1
	data.MatchStats.KillStreak = data.MatchStats.KillStreak + 1
	if data.MatchStats.KillStreak > data.MatchStats.BestStreak then
		data.MatchStats.BestStreak = data.MatchStats.KillStreak
	end
	
	-- Update all-time stats
	data.Stats.TotalKills = data.Stats.TotalKills + 1
	if data.MatchStats.KillStreak > data.Stats.HighestKillStreak then
		data.Stats.HighestKillStreak = data.MatchStats.KillStreak
	end
	
	-- Track specific kill types
	if killData then
		if killData.IsHeadshot then
			data.Stats.HeadshotKills = data.Stats.HeadshotKills + 1
			data.MatchStats.HeadshotCount = data.MatchStats.HeadshotCount + 1
		end
		if killData.Distance and killData.Distance > 200 then
			data.Stats.LongDistanceKills = data.Stats.LongDistanceKills + 1
		end
		if killData.IsWallbang then
			data.Stats.WallbangKills = data.Stats.WallbangKills + 1
		end
		if killData.IsBackstab then
			data.Stats.BackstabKills = data.Stats.BackstabKills + 1
		end
		if killData.IsQuickscope then
			data.Stats.QuickscopeKills = data.Stats.QuickscopeKills + 1
		end
		if killData.IsNoScope then
			data.Stats.NoScopeKills = data.Stats.NoScopeKills + 1
		end
		if killData.IsSpottedKill then
			data.Stats.SpottedKills = data.Stats.SpottedKills + 1
		end
		
		-- Multi-kill tracking
		local killStreak = data.MatchStats.KillStreak
		if killStreak >= 2 then
			if killStreak == 2 then
				data.Stats.DoubleKills = data.Stats.DoubleKills + 1
			elseif killStreak == 3 then
				data.Stats.TripleKills = data.Stats.TripleKills + 1
			elseif killStreak >= 4 then
				data.Stats.QuadKills = data.Stats.QuadKills + 1
			end
		end
		
		-- Add weapon kill tracking
		if killData.WeaponName then
			self:AddWeaponKill(player, killData.WeaponName, killData)
		end
	end
	
	saveQueue[player] = true
	return true
end

function DataStoreManager:RecordDeath(player)
	local data = playerData[player]
	if not data then return false end
	
	-- Reset kill streak
	data.MatchStats.KillStreak = 0
	data.MatchStats.Deaths = data.MatchStats.Deaths + 1
	data.Stats.TotalDeaths = data.Stats.TotalDeaths + 1
	
	saveQueue[player] = true
	return true
end

function DataStoreManager:RecordAssist(player)
	local data = playerData[player]
	if not data then return false end
	
	data.MatchStats.Assists = data.MatchStats.Assists + 1
	data.Stats.TotalAssists = data.Stats.TotalAssists + 1
	
	saveQueue[player] = true
	return true
end

function DataStoreManager:RecordObjectiveAction(player, actionType)
	local data = playerData[player]
	if not data then return false end
	
	if actionType == "capture" then
		data.MatchStats.ObjectivesCompleted = data.MatchStats.ObjectivesCompleted + 1
		data.Stats.ObjectiveCaptures = data.Stats.ObjectiveCaptures + 1
	elseif actionType == "defend" then
		data.Stats.ObjectiveDefends = data.Stats.ObjectiveDefends + 1
	end
	
	saveQueue[player] = true
	return true
end

function DataStoreManager:GetPlayerKDR(player)
	local data = playerData[player]
	if not data or not data.Stats then return 0 end
	
	local kills = data.Stats.TotalKills
	local deaths = data.Stats.TotalDeaths
	
	if deaths == 0 then
		return kills > 0 and kills or 0
	end
	
	return math.floor((kills / deaths) * 100) / 100
end

function DataStoreManager:GetMatchKDR(player)
	local data = playerData[player]
	if not data or not data.MatchStats then return 0 end
	
	local kills = data.MatchStats.Kills
	local deaths = data.MatchStats.Deaths
	
	if deaths == 0 then
		return kills > 0 and kills or 0
	end
	
	return math.floor((kills / deaths) * 100) / 100
end

-- Player Settings Functions
function DataStoreManager:GetPlayerSetting(player, settingName)
	local data = playerData[player]
	if not data or not data.Settings then return nil end
	
	return data.Settings[settingName]
end

function DataStoreManager:SetPlayerSetting(player, settingName, value)
	local data = playerData[player]
	if not data or not data.Settings then return false end
	
	data.Settings[settingName] = value
	saveQueue[player] = true
	return true
end

-- Session Management
function DataStoreManager:StartPlayerSession(player)
	local data = playerData[player]
	if not data then return false end
	
	data.SessionStats.LoginTime = os.time()
	data.SessionStats.MatchesPlayed = 0
	data.SessionStats.TotalKills = 0
	data.SessionStats.TotalDeaths = 0
	data.SessionStats.TotalXP = 0
	data.SessionStats.PlayTime = 0
	
	return true
end

function DataStoreManager:EndPlayerSession(player)
	local data = playerData[player]
	if not data then return false end
	
	if data.SessionStats.LoginTime then
		local sessionTime = os.time() - data.SessionStats.LoginTime
		data.Stats.PlayTime = data.Stats.PlayTime + sessionTime
	end
	
	saveQueue[player] = true
	return true
end

return DataStoreManager