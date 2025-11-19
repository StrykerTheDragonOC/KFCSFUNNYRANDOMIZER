--[[
	CreatePickupSpawns - Creates pickup spawn points for testing
	This script creates basic pickup spawn points near team spawns
	Run this once to set up the pickup system
]]

local Workspace = game:GetService("Workspace")

-- Wait for map to load
local map = Workspace:WaitForChild("Map", 10)
if not map then
	warn("Map not found in workspace")
	return
end

-- Create Spawns folder if it doesn't exist
local spawnsFolder = map:FindFirstChild("Spawns")
if not spawnsFolder then
	spawnsFolder = Instance.new("Folder")
	spawnsFolder.Name = "Spawns"
	spawnsFolder.Parent = map
	print("✓ Created Spawns folder")
end

-- Pickup types to create (from PickupHandler)
local pickupTypes = {
	-- Medical pickups
	{Name = "PickupSpawn_HealthPack", Position = Vector3.new(10, 1, 10), Color = Color3.fromRGB(0, 255, 0)},
	{Name = "PickupSpawn_MedicalKit", Position = Vector3.new(15, 1, 10), Color = Color3.fromRGB(0, 200, 0)},
	{Name = "PickupSpawn_Adrenaline", Position = Vector3.new(20, 1, 10), Color = Color3.fromRGB(255, 200, 0)},

	-- Armor pickups
	{Name = "PickupSpawn_LightArmor", Position = Vector3.new(10, 1, 15), Color = Color3.fromRGB(100, 100, 255)},
	{Name = "PickupSpawn_HeavyArmor", Position = Vector3.new(15, 1, 15), Color = Color3.fromRGB(50, 50, 200)},
	{Name = "PickupSpawn_RiotArmor", Position = Vector3.new(20, 1, 15), Color = Color3.fromRGB(100, 50, 200)},

	-- Ammo pickups
	{Name = "PickupSpawn_RifleAmmo", Position = Vector3.new(10, 1, 20), Color = Color3.fromRGB(255, 150, 0)},
	{Name = "PickupSpawn_PistolAmmo", Position = Vector3.new(15, 1, 20), Color = Color3.fromRGB(200, 100, 0)},
	{Name = "PickupSpawn_ShotgunAmmo", Position = Vector3.new(20, 1, 20), Color = Color3.fromRGB(150, 50, 0)},

	-- Equipment pickups
	{Name = "PickupSpawn_NVG", Position = Vector3.new(10, 1, 25), Color = Color3.fromRGB(0, 255, 150)},
}

-- Create pickup spawn points
local createdCount = 0
for _, pickupData in ipairs(pickupTypes) do
	-- Check if spawn already exists
	local existingSpawn = spawnsFolder:FindFirstChild(pickupData.Name)
	if existingSpawn then
		print("✓ Pickup spawn already exists:", pickupData.Name)
		createdCount = createdCount + 1
	else
		-- Create spawn part
		local spawnPart = Instance.new("Part")
		spawnPart.Name = pickupData.Name
		spawnPart.Size = Vector3.new(2, 1, 2)
		spawnPart.Position = pickupData.Position
		spawnPart.Anchored = true
		spawnPart.CanCollide = false
		spawnPart.Transparency = 0.5
		spawnPart.Color = pickupData.Color
		spawnPart.Material = Enum.Material.Neon
		spawnPart.Parent = spawnsFolder

		-- Add a tag to identify as pickup spawn
		local tag = Instance.new("StringValue")
		tag.Name = "PickupSpawn"
		tag.Value = pickupData.Name:gsub("PickupSpawn_", "")
		tag.Parent = spawnPart

		print("✓ Created pickup spawn:", pickupData.Name)
		createdCount = createdCount + 1
	end
end

print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✓ PICKUP SPAWN SETUP COMPLETE")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Created/Found " .. createdCount .. " pickup spawn points")
print("Location: workspace.Map.Spawns")
print("")
print("Pickup types available:")
print("  - Health Pack, Medical Kit, Adrenaline")
print("  - Light Armor, Heavy Armor, Riot Armor")
print("  - Rifle Ammo, Pistol Ammo, Shotgun Ammo")
print("  - Night Vision Goggles (NVG)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("NOTE: You can disable this script after first run")
print("or delete the pickup spawns to recreate them")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
