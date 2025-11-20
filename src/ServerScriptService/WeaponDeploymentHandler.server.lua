-- Weapon Deployment Handler
-- Manages weapon deployment when players join teams

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Wait for FPSSystem
local FPSSystem = ReplicatedStorage:WaitForChild("FPSSystem")
local WeaponConfig = require(FPSSystem.Modules.WeaponConfig)

local WeaponDeploymentHandler = {}

-- Player loadouts
local playerLoadouts = {} -- [player] = {primary = "G36", secondary = "M9", melee = "PocketKnife", grenade = "M67"}

-- Default loadout
local defaultLoadout = {
    primary = "G36",
    secondary = "M9",
    melee = "PocketKnife",
    grenade = "M67",
    special = nil  -- Special weapons are optional
}

-- Get player's selected loadout
local function GetPlayerLoadout(player)
    return playerLoadouts[player] or defaultLoadout
end

-- Create weapon tool from ServerStorage
local function CreateWeaponTool(weaponName, weaponType)
    local weaponFolder = ServerStorage.Weapons:FindFirstChild(weaponName)

    -- If not found directly, try to find in categorized folders
    if not weaponFolder then
        if weaponType == "primary" then
            -- Try different primary weapon categories
            local categories = {"AssaultRifles", "SniperRifles", "LMGs", "DMRs", "BattleRifles", "Carbines", "SMGs", "PDWs", "Shotguns"}
            for _, category in ipairs(categories) do
                local categoryFolder = ServerStorage.Weapons.Primary:FindFirstChild(category)
                if categoryFolder then
                    weaponFolder = categoryFolder:FindFirstChild(weaponName)
                    if weaponFolder then break end
                end
            end
        elseif weaponType == "secondary" then
            -- Try secondary weapon categories
            local categories = {"Pistols", "Other"}
            for _, category in ipairs(categories) do
                local categoryFolder = ServerStorage.Weapons.Secondary:FindFirstChild(category)
                if categoryFolder then
                    weaponFolder = categoryFolder:FindFirstChild(weaponName)
                    if weaponFolder then break end
                end
            end
        elseif weaponType == "melee" then
            -- Try melee categories
            local categories = {"OneHandedBlades", "OneHandedBlunt", "TwoHandedBlades", "TwoHandedBlunt"}
            for _, category in ipairs(categories) do
                local categoryFolder = ServerStorage.Weapons.Melee:FindFirstChild(category)
                if categoryFolder then
                    weaponFolder = categoryFolder:FindFirstChild(weaponName)
                    if weaponFolder then break end
                end
            end
        elseif weaponType == "grenade" then
            -- Try grenade categories
            local categories = {"Explosive", "Smoke", "Flash", "Other"}
            for _, category in ipairs(categories) do
                local categoryFolder = ServerStorage.Weapons.Grenade:FindFirstChild(category)
                if categoryFolder then
                    weaponFolder = categoryFolder:FindFirstChild(weaponName)
                    if weaponFolder then break end
                end
            end
        end
    end

    if not weaponFolder then
        warn("Weapon folder not found: " .. weaponName .. " (type: " .. weaponType .. ")")
        return nil
    end

    -- Find scripts (server-side and/or client-side)
    local serverScript = weaponFolder:FindFirstChild("ServerScript.server") or
                        weaponFolder:FindFirstChild("ServerScript")
    local clientScript = weaponFolder:FindFirstChild("LocalScript.client") or
                        weaponFolder:FindFirstChild("LocalScript")

    -- Melee and Grenades typically only have client scripts, which is fine
    if not serverScript and not clientScript then
        warn("No scripts found for: " .. weaponName .. " (checked ServerScript.server, ServerScript, LocalScript.client, and LocalScript)")
        return nil
    end

    -- Create the tool
    local tool = Instance.new("Tool")
    tool.Name = weaponName
    tool.RequiresHandle = true

    -- Create handle (invisible for viewmodel weapons)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 4)
    handle.Material = Enum.Material.Plastic
    handle.BrickColor = BrickColor.new("Dark stone grey")
    handle.Transparency = 1  -- Make invisible since viewmodels will be used
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    handle.Parent = tool

    -- Clone and parent server script if it exists
    if serverScript then
        local clonedServerScript = serverScript:Clone()
        clonedServerScript.Parent = tool
    end

    -- Clone and parent client script if it exists
    if clientScript then
        local clonedClientScript = clientScript:Clone()
        clonedClientScript.Parent = tool
    end

    print("✓ Created tool: " .. weaponName .. " (Server: " .. tostring(serverScript ~= nil) .. ", Client: " .. tostring(clientScript ~= nil) .. ")")

    return tool
end

-- Give weapons to player
local function GiveWeaponsToPlayer(player)
    if not player or not player.Character then return end
    
    local loadout = GetPlayerLoadout(player)
    
    -- Clear existing tools
    -- Clear existing tools in Backpack and Character
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool:Destroy()
        end
    end

    if player.Character then
        for _, tool in pairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool:Destroy()
            end
        end
    end
    
    -- Give weapons in order: Primary, Secondary, Melee, Grenade, Special
    local weaponOrder = {"primary", "secondary", "melee", "grenade", "special"}
    
    -- Dedupe melees: ensure only one melee is granted
    local seenMelee = false
    for _, weaponType in pairs(weaponOrder) do
        local weaponName = loadout[weaponType]
        if not weaponName then
            -- nothing to give for this slot
        else
            if weaponType == "melee" then
                if seenMelee then
                    print("Skipping extra melee for " .. player.Name .. ": " .. tostring(weaponName))
                else
                    seenMelee = true
                    local tool = CreateWeaponTool(weaponName, weaponType)
                    if tool then
                        tool.Parent = player.Backpack
                        print("Gave " .. weaponName .. " to " .. player.Name)
                    end
                end
            else
                local tool = CreateWeaponTool(weaponName, weaponType)
                if tool then
                    tool.Parent = player.Backpack
                    print("Gave " .. weaponName .. " to " .. player.Name)
                end
            end
        end
    end
end

-- Handle loadout change
local function HandleLoadoutChange(player, loadoutData)
    if not player or not loadoutData then return end
    
    -- Validate loadout
    local validLoadout = {}
    for weaponType, weaponName in pairs(loadoutData) do
        if WeaponConfig:GetWeaponStats(weaponName) then
            validLoadout[weaponType] = weaponName
        else
            warn("Invalid weapon in loadout: " .. weaponName)
            validLoadout[weaponType] = defaultLoadout[weaponType]
        end
    end
    
    -- Store loadout
    playerLoadouts[player] = validLoadout
    
    -- If player is deployed, give new weapons
    if player.Team and player.Team ~= nil then
        GiveWeaponsToPlayer(player)
    end
    
    print(player.Name .. " updated loadout")
end

-- Handle deployment
local function HandlePlayerDeployment(player, teamName)
    if not player then return end
    
    -- Wait for character to exist
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Give weapons
    GiveWeaponsToPlayer(player)
    
    print(player.Name .. " deployed with weapons to team: " .. (teamName or "Unknown"))
end

-- Handle return to lobby
local function HandleReturnToLobby(player)
    if not player then return end
    
    -- Remove all weapons
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool:Destroy()
        end
    end
    
    for _, tool in pairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") then
            tool:Destroy()
        end
    end
    
    print(player.Name .. " returned to lobby - weapons removed")
end

-- Handle character respawn
local function OnCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end

    -- Give weapons after respawn (including Lobby team for testing)
    -- This allows players to test weapons in the menu/lobby before deploying
    wait(1) -- Wait for character to be ready
    GiveWeaponsToPlayer(player)
end

-- Initialize
function WeaponDeploymentHandler:Initialize()
    print("WeaponDeploymentHandler: Initializing...")
    
    -- Connect remote events
    local loadoutEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("LoadoutChanged")
    if loadoutEvent then
        loadoutEvent.OnServerEvent:Connect(HandleLoadoutChange)
    end

    -- Connect player events
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(OnCharacterAdded)
    end)

    -- Connect to team selection events
    local deployEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("DeployPlayer")
    if deployEvent then
        deployEvent.OnServerEvent:Connect(HandlePlayerDeployment)
    end

    local lobbyEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("ReturnToLobby")
    if lobbyEvent then
        lobbyEvent.OnServerEvent:Connect(HandleReturnToLobby)
    end
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(OnCharacterAdded)
    end
    
    print("WeaponDeploymentHandler: Ready!")
end

-- Public methods
function WeaponDeploymentHandler:GetPlayerLoadout(player)
    return GetPlayerLoadout(player)
end

function WeaponDeploymentHandler:SetPlayerLoadout(player, loadout)
    HandleLoadoutChange(player, loadout)
end

function WeaponDeploymentHandler:GiveWeaponsToPlayer(player)
    GiveWeaponsToPlayer(player)
end

-- Initialize
WeaponDeploymentHandler:Initialize()

return WeaponDeploymentHandler
