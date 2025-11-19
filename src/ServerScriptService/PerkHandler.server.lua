--[[
	Perk Handler (Server)
	Manages perk activation, cooldowns, and effects
	Validates perk usage and broadcasts to clients
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents

-- Create remote events for perks
local ActivatePerkEvent = RemoteEvents:FindFirstChild("ActivatePerk") or Instance.new("RemoteEvent", RemoteEvents)
ActivatePerkEvent.Name = "ActivatePerk"

local PerkActivatedEvent = RemoteEvents:FindFirstChild("PerkActivated") or Instance.new("RemoteEvent", RemoteEvents)
PerkActivatedEvent.Name = "PerkActivated"

local PerkDeactivatedEvent = RemoteEvents:FindFirstChild("PerkDeactivated") or Instance.new("RemoteEvent", RemoteEvents)
PerkDeactivatedEvent.Name = "PerkDeactivated"

local PerkHandler = {}

-- Active perks: {userId = {perkId = {startTime, endTime, data}}}
local activePerks = {}

-- Perk cooldowns: {userId = {perkId = cooldownEndTime}}
local perkCooldowns = {}

-- Perk definitions (matches PerkSystem.lua)
local PERKS = {
	double_jump = {
		cooldown = 0,
		duration = 0,  -- Permanent
		type = "permanent"
	},
	speed_boost = {
		cooldown = 30,
		duration = 8,
		speedMultiplier = 1.5,
		type = "active"
	},
	incendiary_rounds = {
		cooldown = 45,
		duration = 30,
		statusEffect = "Burning",
		type = "active"
	},
	frostbite_rounds = {
		cooldown = 45,
		duration = 30,
		statusEffect = "Frostbite",
		type = "active"
	},
	explosive_rounds = {
		cooldown = 60,
		duration = 20,
		statusEffect = "Explosive",
		type = "active"
	}
}

function PerkHandler:Initialize()
	-- Listen for perk activation requests
	ActivatePerkEvent.OnServerEvent:Connect(function(player, perkId)
		self:ProcessPerkActivation(player, perkId)
	end)

	-- Update active perks (remove expired ones)
	spawn(function()
		while true do
			task.wait(1)
			self:UpdateActivePerks()
		end
	end)

	-- Clean up on player leave
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerData(player)
	end)

	print("PerkHandler initialized")
end

function PerkHandler:ProcessPerkActivation(player, perkId)
	local perkData = PERKS[perkId]
	if not perkData then
		warn("Invalid perk:", perkId)
		return
	end

	-- Check cooldown
	if self:IsOnCooldown(player, perkId) then
		local timeLeft = self:GetCooldownRemaining(player, perkId)
		warn(player.Name .. " perk on cooldown:", perkId, "-", math.ceil(timeLeft), "seconds left")
		return
	end

	-- Activate perk
	local userId = player.UserId

	if not activePerks[userId] then
		activePerks[userId] = {}
	end

	local startTime = tick()
	local endTime = perkData.duration > 0 and (startTime + perkData.duration) or 0

	activePerks[userId][perkId] = {
		startTime = startTime,
		endTime = endTime,
		data = perkData
	}

	-- Set cooldown
	if perkData.cooldown > 0 then
		if not perkCooldowns[userId] then
			perkCooldowns[userId] = {}
		end
		perkCooldowns[userId][perkId] = startTime + perkData.cooldown
	end

	-- Broadcast to all clients (so they can see effects on other players)
	PerkActivatedEvent:FireAllClients(player, perkId, perkData)

	-- Apply server-side effects
	self:ApplyPerkEffects(player, perkId, perkData)

	print(player.Name .. " activated perk:", perkId)

	-- Auto-deactivate after duration
	if perkData.duration > 0 then
		spawn(function()
			task.wait(perkData.duration)
			self:DeactivatePerk(player, perkId)
		end)
	end
end

function PerkHandler:DeactivatePerk(player, perkId)
	local userId = player.UserId

	if activePerks[userId] and activePerks[userId][perkId] then
		activePerks[userId][perkId] = nil

		-- Broadcast deactivation
		PerkDeactivatedEvent:FireAllClients(player, perkId)

		-- Remove server-side effects
		self:RemovePerkEffects(player, perkId)

		print(player.Name .. " deactivated perk:", perkId)
	end
end

function PerkHandler:ApplyPerkEffects(player, perkId, perkData)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Speed boost
	if perkId == "speed_boost" then
		local originalSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = originalSpeed * (perkData.speedMultiplier or 1.5)

		-- Store original speed for restoration
		player:SetAttribute("OriginalWalkSpeed", originalSpeed)
		player:SetAttribute("SpeedBoostActive", true)
	end

	-- Special rounds (set player attribute for weapon system to check)
	if perkData.statusEffect then
		player:SetAttribute("ActiveSpecialRounds", perkData.statusEffect)
	end
end

function PerkHandler:RemovePerkEffects(player, perkId)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Remove speed boost
	if perkId == "speed_boost" then
		local originalSpeed = player:GetAttribute("OriginalWalkSpeed") or 16
		humanoid.WalkSpeed = originalSpeed
		player:SetAttribute("SpeedBoostActive", false)
	end

	-- Remove special rounds
	local perkData = PERKS[perkId]
	if perkData and perkData.statusEffect then
		player:SetAttribute("ActiveSpecialRounds", nil)
	end
end

function PerkHandler:IsOnCooldown(player, perkId)
	local userId = player.UserId
	if not perkCooldowns[userId] then return false end
	if not perkCooldowns[userId][perkId] then return false end

	return tick() < perkCooldowns[userId][perkId]
end

function PerkHandler:GetCooldownRemaining(player, perkId)
	local userId = player.UserId
	if not self:IsOnCooldown(player, perkId) then return 0 end

	return math.max(0, perkCooldowns[userId][perkId] - tick())
end

function PerkHandler:IsPerkActive(player, perkId)
	local userId = player.UserId
	if not activePerks[userId] then return false end
	return activePerks[userId][perkId] ~= nil
end

function PerkHandler:UpdateActivePerks()
	local currentTime = tick()

	for userId, perks in pairs(activePerks) do
		for perkId, perkInstance in pairs(perks) do
			-- Check if duration expired
			if perkInstance.endTime > 0 and currentTime >= perkInstance.endTime then
				local player = Players:GetPlayerByUserId(userId)
				if player then
					self:DeactivatePerk(player, perkId)
				else
					-- Player left, clean up
					activePerks[userId][perkId] = nil
				end
			end
		end
	end
end

function PerkHandler:CleanupPlayerData(player)
	local userId = player.UserId
	activePerks[userId] = nil
	perkCooldowns[userId] = nil
end

function PerkHandler:GetActivePerks(player)
	return activePerks[player.UserId] or {}
end

-- Console commands for testing
_G.PerkCommands = {
	activatePerk = function(playerName, perkId)
		local player = Players:FindFirstChild(playerName)
		if player then
			PerkHandler:ProcessPerkActivation(player, perkId)
			print("Activated", perkId, "for", playerName)
		else
			print("Player not found:", playerName)
		end
	end,

	listActive = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player then
			local active = PerkHandler:GetActivePerks(player)
			print("Active perks for", playerName .. ":")
			for perkId, data in pairs(active) do
				local timeLeft = data.endTime > 0 and math.ceil(data.endTime - tick()) or "Permanent"
				print("- " .. perkId .. " (Time left: " .. tostring(timeLeft) .. ")")
			end
		else
			print("Player not found:", playerName)
		end
	end,

	clearCooldowns = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player then
			perkCooldowns[player.UserId] = {}
			print("Cleared all cooldowns for", playerName)
		else
			print("Player not found:", playerName)
		end
	end
}

-- Initialize
PerkHandler:Initialize()

return PerkHandler
