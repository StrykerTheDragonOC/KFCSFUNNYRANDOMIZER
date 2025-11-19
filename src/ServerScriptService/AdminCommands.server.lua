--[[
	Admin Commands System
	Provides developer/admin commands for testing and management
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local AdminCommands = {}

-- Admin user IDs (add your Roblox user ID here)
local ADMIN_USER_IDS = {
	-- Add your user ID here
	-- Example: 123456789,
}

-- Check if player is admin
function AdminCommands:IsAdmin(player)
	-- Game creator is always admin
	if player.UserId == game.CreatorId then
		return true
	end

	-- Check admin list
	for _, adminId in pairs(ADMIN_USER_IDS) do
		if player.UserId == adminId then
			return true
		end
	end

	return false
end

-- Give weapon to player
function AdminCommands:GiveWeapon(player, weaponName)
	if not player or not player.Character then
		warn("Player or character not found")
		return false
	end

	-- Find weapon in ServerStorage.Weapons
	local weaponsFolder = ServerStorage:FindFirstChild("Weapons")
	if not weaponsFolder then
		warn("Weapons folder not found in ServerStorage")
		return false
	end

	-- Get weapon config to find category/type
	local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
	if not weaponConfig then
		warn("No config found for weapon:", weaponName)
		return false
	end

	-- Build path: ServerStorage/Weapons/[Category]/[Type]/[WeaponName]
	local categoryFolder = weaponsFolder:FindFirstChild(weaponConfig.Category)
	if not categoryFolder then
		warn("Category folder not found:", weaponConfig.Category)
		return false
	end

	local typeFolder = categoryFolder:FindFirstChild(weaponConfig.Type)
	if not typeFolder then
		warn("Type folder not found:", weaponConfig.Type)
		return false
	end

	local weaponTool = typeFolder:FindFirstChild(weaponName)
	if weaponTool and weaponTool:IsA("Tool") then
		local clonedTool = weaponTool:Clone()
		clonedTool.Parent = player.Backpack
		print("✓ Gave", weaponName, "to", player.Name)
		return true
	else
		warn("Weapon tool not found:", weaponName)
		return false
	end
end

-- Give NTW-20 (special variant)
function AdminCommands:GiveNTW(player)
	if not self:IsAdmin(player) then
		warn(player.Name, "is not an admin")
		return
	end

	local success = self:GiveWeapon(player, "NTW-20")
	if success then
		print("✓ Gave NTW-20 to", player.Name)
	else
		warn("Failed to give NTW-20 to", player.Name)
	end
end

-- Give any weapon by name
function AdminCommands:GiveWeaponByName(player, weaponName)
	if not self:IsAdmin(player) then
		warn(player.Name, "is not an admin")
		return
	end

	local success = self:GiveWeapon(player, weaponName)
	if success then
		print("✓ Gave", weaponName, "to", player.Name)
	else
		warn("Failed to give", weaponName, "to", player.Name)
	end
end

-- Clear all weapons from player
function AdminCommands:ClearWeapons(player)
	if not player or not player.Character then return end

	-- Clear backpack
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	-- Clear equipped tools
	for _, tool in pairs(player.Character:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	print("✓ Cleared weapons from", player.Name)
end

-- Give max armor
function AdminCommands:GiveMaxArmor(player)
	if not self:IsAdmin(player) then
		warn(player.Name, "is not an admin")
		return
	end

	player:SetAttribute("Armor", 100)
	print("✓ Gave max armor to", player.Name)
end

-- Heal player
function AdminCommands:HealPlayer(player)
	if not self:IsAdmin(player) then
		warn(player.Name, "is not an admin")
		return
	end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
			print("✓ Healed", player.Name)
		end
	end
end

-- Give all weapons (for testing)
function AdminCommands:GiveAllWeapons(player)
	if not self:IsAdmin(player) then
		warn(player.Name, "is not an admin")
		return
	end

	-- Clear existing weapons first
	self:ClearWeapons(player)

	-- Give one of each type
	self:GiveWeapon(player, "G36")  -- Primary
	self:GiveWeapon(player, "M9")   -- Secondary
	self:GiveWeapon(player, "PocketKnife")  -- Melee
	self:GiveWeapon(player, "M67")  -- Grenade

	print("✓ Gave all default weapons to", player.Name)
end

-- Initialize
function AdminCommands:Initialize()
	-- Setup remote event for admin commands from client
	local adminCommandEvent = Instance.new("RemoteEvent")
	adminCommandEvent.Name = "AdminCommand"
	adminCommandEvent.Parent = ReplicatedStorage.FPSSystem.RemoteEvents

	adminCommandEvent.OnServerEvent:Connect(function(player, commandName, ...)
		if not self:IsAdmin(player) then
			warn(player.Name, "attempted to use admin command but is not admin")
			return
		end

		local args = {...}

		if commandName == "GiveNTW" then
			self:GiveNTW(player)
		elseif commandName == "GiveWeapon" then
			self:GiveWeaponByName(player, args[1])
		elseif commandName == "ClearWeapons" then
			self:ClearWeapons(player)
		elseif commandName == "GiveMaxArmor" then
			self:GiveMaxArmor(player)
		elseif commandName == "HealPlayer" then
			self:HealPlayer(player)
		elseif commandName == "GiveAllWeapons" then
			self:GiveAllWeapons(player)
		end
	end)

	print("AdminCommands initialized")
end

-- Make globally accessible via _G
_G.AdminCommands = AdminCommands

-- Also create easy-to-use global functions
_G.GiveNTW = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if player then
		AdminCommands:GiveNTW(player)
	else
		warn("Player not found:", playerName)
	end
end

_G.GiveWeapon = function(playerName, weaponName)
	local player = Players:FindFirstChild(playerName)
	if player then
		AdminCommands:GiveWeaponByName(player, weaponName)
	else
		warn("Player not found:", playerName)
	end
end

_G.ClearWeapons = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if player then
		AdminCommands:ClearWeapons(player)
	else
		warn("Player not found:", playerName)
	end
end

_G.GiveMaxArmor = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if player then
		AdminCommands:GiveMaxArmor(player)
	else
		warn("Player not found:", playerName)
	end
end

_G.HealPlayer = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if player then
		AdminCommands:HealPlayer(player)
	else
		warn("Player not found:", playerName)
	end
end

_G.GiveAllWeapons = function(playerName)
	local player = Players:FindChild(playerName)
	if player then
		AdminCommands:GiveAllWeapons(player)
	else
		warn("Player not found:", playerName)
	end
end

-- Print available commands
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📋 ADMIN COMMANDS LOADED")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Available commands (use in Server Console):")
print("")
print("  _G.GiveNTW(\"PlayerName\")")
print("  _G.GiveWeapon(\"PlayerName\", \"WeaponName\")")
print("  _G.GiveAllWeapons(\"PlayerName\")")
print("  _G.ClearWeapons(\"PlayerName\")")
print("  _G.GiveMaxArmor(\"PlayerName\")")
print("  _G.HealPlayer(\"PlayerName\")")
print("")
print("Examples:")
print("  _G.GiveNTW(\"StrykerOC\")")
print("  _G.GiveWeapon(\"StrykerOC\", \"G36\")")
print("  _G.GiveAllWeapons(\"StrykerOC\")")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- Initialize
AdminCommands:Initialize()

return AdminCommands
