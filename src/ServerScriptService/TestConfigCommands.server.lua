--[[
	TestConfigCommands.server.lua
	Admin commands for managing test configuration
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

repeat
	task.wait()
until ReplicatedStorage:FindFirstChild("FPSSystem")

local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)
local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)

-- Admin check function
local function isAdmin(player)
	return player.UserId == 1500556418 or player:GetAttribute("IsAdmin") == true
end

-- Create RemoteEvents
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents

local SetTestModeEvent = RemoteEvents:FindFirstChild("SetTestMode")
if not SetTestModeEvent then
	SetTestModeEvent = Instance.new("RemoteEvent")
	SetTestModeEvent.Name = "SetTestMode"
	SetTestModeEvent.Parent = RemoteEvents
end

local SetUnlockAllEvent = RemoteEvents:FindFirstChild("SetUnlockAll")
if not SetUnlockAllEvent then
	SetUnlockAllEvent = Instance.new("RemoteEvent")
	SetUnlockAllEvent.Name = "SetUnlockAll"
	SetUnlockAllEvent.Parent = RemoteEvents
end

local SetBypassCostsEvent = RemoteEvents:FindFirstChild("SetBypassCosts")
if not SetBypassCostsEvent then
	SetBypassCostsEvent = Instance.new("RemoteEvent")
	SetBypassCostsEvent.Name = "SetBypassCosts"
	SetBypassCostsEvent.Parent = RemoteEvents
end

local SetXPMultiplierEvent = RemoteEvents:FindFirstChild("SetXPMultiplier")
if not SetXPMultiplierEvent then
	SetXPMultiplierEvent = Instance.new("RemoteEvent")
	SetXPMultiplierEvent.Name = "SetXPMultiplier"
	SetXPMultiplierEvent.Parent = RemoteEvents
end

local SetStartingCreditsEvent = RemoteEvents:FindFirstChild("SetStartingCredits")
if not SetStartingCreditsEvent then
	SetStartingCreditsEvent = Instance.new("RemoteEvent")
	SetStartingCreditsEvent.Name = "SetStartingCredits"
	SetStartingCreditsEvent.Parent = RemoteEvents
end

local SetStartingLevelEvent = RemoteEvents:FindFirstChild("SetStartingLevel")
if not SetStartingLevelEvent then
	SetStartingLevelEvent = Instance.new("RemoteEvent")
	SetStartingLevelEvent.Name = "SetStartingLevel"
	SetStartingLevelEvent.Parent = RemoteEvents
end

local GetTestConfigEvent = RemoteEvents:FindFirstChild("GetTestConfig")
if not GetTestConfigEvent then
	GetTestConfigEvent = Instance.new("RemoteFunction")
	GetTestConfigEvent.Name = "GetTestConfig"
	GetTestConfigEvent.Parent = RemoteEvents
end

-- Helper function to update config values
local function updateConfigValue(path, value)
	local gameConfig = Workspace:FindFirstChild("GameConfig")
	if not gameConfig then
		warn("GameConfig not found in Workspace")
		return false
	end
	
	local testConfig = gameConfig:FindFirstChild("TestConfig")
	if not testConfig then
		warn("TestConfig not found in GameConfig")
		return false
	end
	
	local valueObject = testConfig:FindFirstChild(path)
	if valueObject then
		valueObject.Value = value
		return true
	else
		warn("Config value not found:", path)
		return false
	end
end

-- Remote Event Handlers
SetTestModeEvent.OnServerEvent:Connect(function(player, enabled)
	if not isAdmin(player) then
		warn(player.Name .. " attempted to set test mode without admin privileges")
		return
	end
	
	if updateConfigValue("TestMode", enabled) then
		print("Test mode", enabled and "enabled" or "disabled", "by", player.Name)
		
		-- Notify all players
		for _, plr in ipairs(Players:GetPlayers()) do
			local event = RemoteEvents:FindFirstChild("AdminSuccess")
			if event then
				event:FireClient(plr, "Test mode " .. (enabled and "enabled" or "disabled"))
			end
		end
	end
end)

SetUnlockAllEvent.OnServerEvent:Connect(function(player, enabled)
	if not isAdmin(player) then
		warn(player.Name .. " attempted to set unlock all without admin privileges")
		return
	end
	
	if updateConfigValue("UnlockAll", enabled) then
		print("Unlock all", enabled and "enabled" or "disabled", "by", player.Name)
		
		-- Notify all players
		for _, plr in ipairs(Players:GetPlayers()) do
			local event = RemoteEvents:FindFirstChild("AdminSuccess")
			if event then
				event:FireClient(plr, "Unlock all " .. (enabled and "enabled" or "disabled"))
			end
		end
	end
end)

SetBypassCostsEvent.OnServerEvent:Connect(function(player, enabled)
	if not isAdmin(player) then
		warn(player.Name .. " attempted to set bypass costs without admin privileges")
		return
	end
	
	if updateConfigValue("BypassCosts", enabled) then
		print("Bypass costs", enabled and "enabled" or "disabled", "by", player.Name)
		
		-- Notify all players
		for _, plr in ipairs(Players:GetPlayers()) do
			local event = RemoteEvents:FindFirstChild("AdminSuccess")
			if event then
				event:FireClient(plr, "Bypass costs " .. (enabled and "enabled" or "disabled"))
			end
		end
	end
end)

SetXPMultiplierEvent.OnServerEvent:Connect(function(player, multiplier)
	if not isAdmin(player) then
		warn(player.Name .. " attempted to set XP multiplier without admin privileges")
		return
	end
	
	if updateConfigValue("XPMultiplier", multiplier) then
		print("XP multiplier set to", multiplier, "by", player.Name)
		
		-- Notify all players
		for _, plr in ipairs(Players:GetPlayers()) do
			local event = RemoteEvents:FindFirstChild("AdminSuccess")
			if event then
				event:FireClient(plr, "XP multiplier set to " .. multiplier .. "x")
			end
		end
	end
end)

SetStartingCreditsEvent.OnServerEvent:Connect(function(player, credits)
	if not isAdmin(player) then
		warn(player.Name .. " attempted to set starting credits without admin privileges")
		return
	end
	
	if updateConfigValue("StartingCredits", credits) then
		print("Starting credits set to", credits, "by", player.Name)
		
		-- Notify all players
		for _, plr in ipairs(Players:GetPlayers()) do
			local event = RemoteEvents:FindFirstChild("AdminSuccess")
			if event then
				event:FireClient(plr, "Starting credits set to " .. credits)
			end
		end
	end
end)

SetStartingLevelEvent.OnServerEvent:Connect(function(player, level)
	if not isAdmin(player) then
		warn(player.Name .. " attempted to set starting level without admin privileges")
		return
	end
	
	if updateConfigValue("StartingLevel", level) then
		print("Starting level set to", level, "by", player.Name)
		
		-- Notify all players
		for _, plr in ipairs(Players:GetPlayers()) do
			local event = RemoteEvents:FindFirstChild("AdminSuccess")
			if event then
				event:FireClient(plr, "Starting level set to " .. level)
			end
		end
	end
end)

-- Remote Function Handlers
GetTestConfigEvent.OnServerInvoke = function(player)
	if not isAdmin(player) then
		return nil
	end
	
	return {
		TestMode = GameConfig:IsTestMode(),
		UnlockAll = GameConfig:IsUnlockAllEnabled(),
		BypassCosts = GameConfig:IsBypassCostsEnabled(),
		XPMultiplier = GameConfig:GetXPMultiplier(),
		StartingCredits = GameConfig:GetTestStartingCredits(),
		StartingLevel = GameConfig:GetTestStartingLevel()
	}
end

print("TestConfigCommands initialized")

