--[[
	M4A1 Carbine Server Script
	Handles server-side weapon validation and damage
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local tool = script.Parent
local weaponName = "M4A1"

local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
if not weaponConfig then
	warn("No weapon config found for:", weaponName)
	return
end

print("M4A1 server script loaded")
