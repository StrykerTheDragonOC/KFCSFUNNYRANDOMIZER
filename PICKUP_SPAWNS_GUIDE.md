# Pickup Spawn System Guide

## How to Create Pickup Spawns

The pickup system automatically scans Workspace and ServerStorage for specially named Parts that act as spawn points for pickups.

### Naming Convention
Parts should be named: `PickupSpawn_[PickupType]`

### Available Pickup Types

#### Medical Pickups
- `PickupSpawn_HealthPack` - Heals 50 HP, respawns in 30s
- `PickupSpawn_MedicalKit` - Heals 100 HP + removes status effects, respawns in 60s
- `PickupSpawn_Adrenaline` - Gives Adrenaline buff for 30s, respawns in 90s

#### Armor Pickups  
- `PickupSpawn_LightArmor` - Adds 25 armor, respawns in 45s
- `PickupSpawn_HeavyArmor` - Adds 50 armor, respawns in 90s
- `PickupSpawn_RiotArmor` - Adds 100 armor, respawns in 120s

#### Ammunition Pickups
- `PickupSpawn_PistolAmmo` - 30 rounds of 9mm, respawns in 20s
- `PickupSpawn_RifleAmmo` - 60 rounds of 5.56, respawns in 25s
- `PickupSpawn_SniperAmmo` - 20 rounds of 7.62, respawns in 40s
- `PickupSpawn_ShotgunShells` - 16 shells, respawns in 30s

#### Equipment Pickups
- `PickupSpawn_NightVision` - NVG equipment, respawns in 120s
- `PickupSpawn_ThermalScope` - Thermal scope, respawns in 150s
- `PickupSpawn_GhillieSuit` - Camouflage for 120s, respawns in 180s

#### Special Powerups
- `PickupSpawn_SpeedBoost` - Speed buff for 20s, respawns in 60s
- `PickupSpawn_DamageBoost` - Damage buff for 15s, respawns in 75s
- `PickupSpawn_ShieldGenerator` - Shield for 45s, respawns in 120s

## How to Place Spawns

1. Insert a Part into Workspace
2. Name it using the convention above (e.g., "PickupSpawn_HealthPack")
3. Position it where you want the pickup to spawn
4. The part will be invisible in-game, but the pickup will spawn at its position
5. Optionally, place it in a folder called "PickupSpawns" in ServerStorage to keep workspace clean

## Testing Setup

For quick testing near spawn, create these pickup spawns:
- One of each armor type
- One health pack
- One of each ammo type

Position them 10-20 studs from each team spawn for easy access during testing.

## Example Lua Script to Create Test Spawns

Run this in the command bar to create test spawns near position (0, 5, 0):

```lua
local pickupTypes = {"HealthPack", "LightArmor", "RifleAmmo", "PistolAmmo"}
for i, pickupType in ipairs(pickupTypes) do
    local part = Instance.new("Part")
    part.Name = "PickupSpawn_" .. pickupType
    part.Size = Vector3.new(2, 2, 2)
    part.Position = Vector3.new(i * 5, 5, 0)
    part.Anchored = true
    part.Transparency = 0.8
    part.CanCollide = false
    part.BrickColor = BrickColor.new("Bright green")
    part.Parent = workspace
end
print("Created " .. #pickupTypes .. " test pickup spawns")
```

## Notes

- The part itself doesn't need any scripts - the PickupHandler automatically detects it
- Parts can be any size, but smaller (2x2x2) is recommended for precision
- Consider making them transparent or removing them to ServerStorage after placement
- Respawn times are automatic based on pickup type
- Players can pick up items within 5 studs of the spawn point
