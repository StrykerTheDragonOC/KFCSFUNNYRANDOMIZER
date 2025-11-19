--[[
	Admin Handler
	Manages admin permissions and checks
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents

-- Admin list (UserIds)
local ADMINS = {
	-- Add admin UserIds here
	-- Example: 123456789,
}

-- Check if player is game creator
local function IsCreator(player)
	return player.UserId == game.CreatorId
end

-- Check if player is in admin list
local function IsInAdminList(player)
	for _, adminId in ipairs(ADMINS) do
		if player.UserId == adminId then
			return true
		end
	end
	return false
end

-- Main admin check function
local function IsPlayerAdmin(player)
	-- Creator is always admin
	if IsCreator(player) then
		return true
	end
	
	-- Check admin list
	if IsInAdminList(player) then
		return true
	end
	
	-- Check if AdminSystem exists (integration with existing admin system)
	if _G.AdminSystem then
		return _G.AdminSystem:IsAdmin(player)
	end
	
	return false
end

-- Setup RemoteFunction
local IsPlayerAdminFunction = RemoteEvents:FindFirstChild("IsPlayerAdmin")
if not IsPlayerAdminFunction then
	IsPlayerAdminFunction = Instance.new("RemoteFunction")
	IsPlayerAdminFunction.Name = "IsPlayerAdmin"
	IsPlayerAdminFunction.Parent = RemoteEvents
end

IsPlayerAdminFunction.OnServerInvoke = function(player)
	local isAdmin = IsPlayerAdmin(player)
	
	if isAdmin then
		print("✓", player.Name, "verified as ADMIN")
	end
	
	return isAdmin
end

-- Make globally accessible
_G.IsPlayerAdmin = IsPlayerAdmin

print("AdminHandler initialized")

-- Log admins on join
Players.PlayerAdded:Connect(function(player)
	if IsPlayerAdmin(player) then
		print("🔑 ADMIN JOINED:", player.Name, "(UserId:", player.UserId .. ")")
	end
end)






