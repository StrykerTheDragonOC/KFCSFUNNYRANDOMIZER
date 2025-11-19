--[[
	Loadout Manager (Server)
	Manages player loadout customization
	Saves/loads loadouts from DataStore
	Validates weapon/attachment/perk selections
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local SaveLoadoutEvent = RemoteEvents:FindFirstChild("SaveLoadout") or Instance.new("RemoteEvent", RemoteEvents)
SaveLoadoutEvent.Name = "SaveLoadout"

local RequestLoadoutEvent = RemoteEvents:FindFirstChild("RequestLoadout") or Instance.new("RemoteEvent", RemoteEvents)
RequestLoadoutEvent.Name = "RequestLoadout"

local LoadoutUpdatedEvent = RemoteEvents:FindFirstChild("LoadoutUpdated") or Instance.new("RemoteEvent", RemoteEvents)
LoadoutUpdatedEvent.Name = "LoadoutUpdated"

local LoadoutManager = {}

-- Default loadout structure
local DEFAULT_LOADOUT = {
	Primary = {
		Weapon = "G36",
		Attachments = {
			Sight = "IronSights",
			Barrel = nil,
			Underbarrel = nil,
			Other = nil
		},
		AmmoType = "Standard",
		Skin = nil
	},
	Secondary = {
		Weapon = "M9",
		Attachments = {
			Sight = "IronSights",
			Barrel = nil,
			Underbarrel = nil,
			Other = nil
		},
		AmmoType = "Standard",
		Skin = nil
	},
	Melee = {
		Weapon = "PocketKnife",
		Skin = nil
	},
	Grenade = {
		Weapon = "M67",
		Skin = nil
	},
	Perks = {
		Slot1 = "double_jump",
		Slot2 = "speed_boost",
		Slot3 = "incendiary_rounds"
	},
	Special = nil
}

-- Player loadouts (cached)
local playerLoadouts = {}

function LoadoutManager:Initialize()
	-- Handle save requests
	SaveLoadoutEvent.OnServerEvent:Connect(function(player, loadoutData)
		self:SaveLoadout(player, loadoutData)
	end)

	-- Handle loadout requests
	RequestLoadoutEvent.OnServerEvent:Connect(function(player)
		self:SendLoadout(player)
	end)

	-- Setup player loadouts on join
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerLoadout(player)
	end)

	-- Clear cache on leave
	Players.PlayerRemoving:Connect(function(player)
		playerLoadouts[player.UserId] = nil
	end)

	print("LoadoutManager initialized")
end

function LoadoutManager:LoadPlayerLoadout(player)
	local playerData = DataStoreManager:GetPlayerData(player)

	if playerData and playerData.loadout then
		-- Use saved loadout
		playerLoadouts[player.UserId] = playerData.loadout
		print("Loaded saved loadout for:", player.Name)
	else
		-- Use default loadout
		playerLoadouts[player.UserId] = self:DeepCopy(DEFAULT_LOADOUT)
		print("Using default loadout for:", player.Name)
	end

	-- Send to client
	self:SendLoadout(player)
end

function LoadoutManager:SaveLoadout(player, loadoutData)
	-- Validate loadout
	local isValid, errorMessage = self:ValidateLoadout(player, loadoutData)

	if not isValid then
		warn("Invalid loadout from", player.Name, ":", errorMessage)
		return
	end

	-- Save to cache
	playerLoadouts[player.UserId] = loadoutData

	-- Save to DataStore
	local playerData = DataStoreManager:GetPlayerData(player)
	if playerData then
		playerData.loadout = loadoutData
		DataStoreManager.SavePlayerData(player, playerData)
		print("Saved loadout for:", player.Name)

		-- Broadcast success
		LoadoutUpdatedEvent:FireClient(player, true, "Loadout saved successfully")
	else
		warn("Failed to save loadout for:", player.Name)
		LoadoutUpdatedEvent:FireClient(player, false, "Save failed")
	end
end

function LoadoutManager:SendLoadout(player)
	local loadout = playerLoadouts[player.UserId] or self:DeepCopy(DEFAULT_LOADOUT)
	LoadoutUpdatedEvent:FireClient(player, true, "Loadout loaded", loadout)
end

function LoadoutManager:ValidateLoadout(player, loadout)
	-- Check primary weapon
	if loadout.Primary and loadout.Primary.Weapon then
		local weaponConfig = WeaponConfig:GetWeaponConfig(loadout.Primary.Weapon)
		if not weaponConfig then
			return false, "Invalid primary weapon: " .. tostring(loadout.Primary.Weapon)
		end

		-- Check if player owns weapon
		if not self:PlayerOwnsWeapon(player, loadout.Primary.Weapon) then
			return false, "Player doesn't own: " .. loadout.Primary.Weapon
		end

		-- Validate attachments
		if loadout.Primary.Attachments then
			for slot, attachment in pairs(loadout.Primary.Attachments) do
				if attachment and attachment ~= "IronSights" then
					if not self:ValidateAttachment(player, loadout.Primary.Weapon, slot, attachment) then
						return false, "Invalid attachment: " .. tostring(attachment)
					end
				end
			end
		end
	end

	-- Check secondary weapon
	if loadout.Secondary and loadout.Secondary.Weapon then
		local weaponConfig = WeaponConfig:GetWeaponConfig(loadout.Secondary.Weapon)
		if not weaponConfig then
			return false, "Invalid secondary weapon: " .. tostring(loadout.Secondary.Weapon)
		end

		if not self:PlayerOwnsWeapon(player, loadout.Secondary.Weapon) then
			return false, "Player doesn't own: " .. loadout.Secondary.Weapon
		end
	end

	-- Check melee weapon
	if loadout.Melee and loadout.Melee.Weapon then
		if not self:PlayerOwnsWeapon(player, loadout.Melee.Weapon) then
			return false, "Player doesn't own: " .. loadout.Melee.Weapon
		end
	end

	-- Check grenade
	if loadout.Grenade and loadout.Grenade.Weapon then
		if not self:PlayerOwnsWeapon(player, loadout.Grenade.Weapon) then
			return false, "Player doesn't own: " .. loadout.Grenade.Weapon
		end
	end

	-- Validate skins
	if loadout.Primary and loadout.Primary.Skin then
		if not self:PlayerOwnsSkin(player, loadout.Primary.Skin) then
			return false, "Player doesn't own skin: " .. loadout.Primary.Skin
		end
	end

	return true, nil
end

function LoadoutManager:ValidateAttachment(player, weaponName, slot, attachmentName)
	local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
	if not weaponConfig or not weaponConfig.AttachmentSlots then
		return false
	end

	-- Check compatibility
	local slotData = weaponConfig.AttachmentSlots[slot]
	if not slotData or not slotData.Compatible then
		return false
	end

	if not table.find(slotData.Compatible, attachmentName) then
		return false
	end

	-- Check ownership
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.UnlockedAttachments then
		return false
	end

	local weaponAttachments = playerData.UnlockedAttachments[weaponName]
	if not weaponAttachments or not table.find(weaponAttachments, attachmentName) then
		return false
	end

	return true
end

function LoadoutManager:PlayerOwnsWeapon(player, weaponName)
	local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
	if not weaponConfig then return false end

	-- Default weapons are always available
	if weaponConfig.IsDefault or weaponConfig.UnlockLevel == 0 then
		return true
	end

	-- Check if unlocked
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.UnlockedWeapons then
		return false
	end

	return table.find(playerData.UnlockedWeapons, weaponName) ~= nil
end

function LoadoutManager:PlayerOwnsSkin(player, skinId)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.ownedSkins then
		return false
	end

	return table.find(playerData.ownedSkins, skinId) ~= nil
end

function LoadoutManager:GetPlayerLoadout(player)
	return playerLoadouts[player.UserId] or self:DeepCopy(DEFAULT_LOADOUT)
end

function LoadoutManager:DeepCopy(tbl)
	local copy = {}
	for key, value in pairs(tbl) do
		if type(value) == "table" then
			copy[key] = self:DeepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

function LoadoutManager:GetAvailableWeapons(player, category)
	local available = {}
	local playerData = DataStoreManager:GetPlayerData(player)

	for weaponName, config in pairs(WeaponConfig:GetAllConfigs()) do
		if config.Category == category then
			-- Check if default or owned
			local isOwned = config.IsDefault or config.UnlockLevel == 0

			if not isOwned and playerData and playerData.UnlockedWeapons then
				isOwned = table.find(playerData.UnlockedWeapons, weaponName) ~= nil
			end

			if isOwned then
				table.insert(available, {
					Name = weaponName,
					Config = config
				})
			end
		end
	end

	return available
end

-- Admin commands
_G.LoadoutCommands = {
	getLoadout = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if not player then
			warn("Player not found:", playerName)
			return
		end

		local loadout = LoadoutManager:GetPlayerLoadout(player)
		print("=== LOADOUT:", playerName, "===")
		print("Primary:", loadout.Primary.Weapon, "- Sight:", loadout.Primary.Attachments.Sight)
		print("Secondary:", loadout.Secondary.Weapon)
		print("Melee:", loadout.Melee.Weapon)
		print("Grenade:", loadout.Grenade.Weapon)
		print("Perks:", loadout.Perks.Slot1, loadout.Perks.Slot2, loadout.Perks.Slot3)
	end,

	resetLoadout = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if not player then
			warn("Player not found:", playerName)
			return
		end

		playerLoadouts[player.UserId] = LoadoutManager:DeepCopy(DEFAULT_LOADOUT)
		LoadoutManager:SendLoadout(player)
		print("Reset loadout for:", playerName)
	end,

	listAvailableWeapons = function(playerName, category)
		local player = Players:FindFirstChild(playerName)
		if not player then
			warn("Player not found:", playerName)
			return
		end

		local available = LoadoutManager:GetAvailableWeapons(player, category)
		print("=== AVAILABLE", category, "WEAPONS:", playerName, "===")
		for _, weaponData in ipairs(available) do
			print("-", weaponData.Name, "(Level " .. weaponData.Config.UnlockLevel .. ")")
		end
	end
}

-- Initialize
LoadoutManager:Initialize()

-- Make globally accessible
_G.LoadoutManager = LoadoutManager

return LoadoutManager
