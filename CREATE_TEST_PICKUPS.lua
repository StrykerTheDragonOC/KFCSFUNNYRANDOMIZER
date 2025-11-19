--[[
    QUICK PICKUP SPAWN CREATOR
    
    HOW TO USE:
    1. Copy this entire script
    2. Open Roblox Studio
    3. Open Command Bar (View > Command Bar)
    4. Paste and run this script
    
    This will create test pickup spawns near (0, 5, 0) for quick testing.
]]

local function createTestPickupSpawns()
    -- Create a folder to organize spawns
    local spawnsFolder = Instance.new("Folder")
    spawnsFolder.Name = "TestPickupSpawns"
    spawnsFolder.Parent = workspace
    
    -- Define test pickups (one of each category for testing)
    local testPickups = {
        {Type = "HealthPack", Color = Color3.fromRGB(255, 100, 100), Pos = Vector3.new(0, 5, 0)},
        {Type = "LightArmor", Color = Color3.fromRGB(100, 100, 255), Pos = Vector3.new(5, 5, 0)},
        {Type = "RifleAmmo", Color = Color3.fromRGB(255, 200, 100), Pos = Vector3.new(10, 5, 0)},
        {Type = "PistolAmmo", Color = Color3.fromRGB(255, 200, 100), Pos = Vector3.new(15, 5, 0)},
        {Type = "HeavyArmor", Color = Color3.fromRGB(100, 100, 255), Pos = Vector3.new(0, 5, 5)},
        {Type = "MedicalKit", Color = Color3.fromRGB(255, 100, 100), Pos = Vector3.new(5, 5, 5)},
        {Type = "SpeedBoost", Color = Color3.fromRGB(100, 255, 255), Pos = Vector3.new(10, 5, 5)},
        {Type = "NightVision", Color = Color3.fromRGB(100, 255, 100), Pos = Vector3.new(15, 5, 5)},
    }
    
    for i, pickup in ipairs(testPickups) do
        local part = Instance.new("Part")
        part.Name = "PickupSpawn_" .. pickup.Type
        part.Size = Vector3.new(2, 2, 2)
        part.Position = pickup.Pos
        part.Anchored = true
        part.Transparency = 0.5  -- Semi-transparent so you can see them
        part.CanCollide = false
        part.Color = pickup.Color
        part.Material = Enum.Material.Neon
        part.Parent = spawnsFolder
        
        -- Add a text label above it
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(0, 100, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.Parent = part
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = pickup.Type
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextStrokeTransparency = 0
        textLabel.Parent = billboardGui
        
        print("✓ Created pickup spawn:", pickup.Type, "at", tostring(pickup.Pos))
    end
    
    print("========================================")
    print("✓ Created " .. #testPickups .. " test pickup spawns!")
    print("📍 Location: workspace.TestPickupSpawns")
    print("========================================")
    print("The pickups will automatically spawn in-game.")
    print("Players can pick them up within 5 studs.")
    print("")
    print("To move them:")
    print("1. Select the part in Workspace > TestPickupSpawns")
    print("2. Use the Move tool to reposition")
    print("")
    print("To create more spawns:")
    print("1. Duplicate a part (Ctrl+D)")
    print("2. Rename it: PickupSpawn_[Type]")
    print("3. Move to desired location")
    print("")
    print("Available types: See PICKUP_SPAWNS_GUIDE.md")
end

-- Run the function
local success, err = pcall(createTestPickupSpawns)
if not success then
    warn("Error creating pickup spawns:", err)
else
    print("✅ Pickup spawns created successfully!")
end
