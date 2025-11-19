-- PerkSystem.lua
-- Comprehensive perk management system for the FPS game

local PerkSystem = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Available perks from Claude.md specifications
local AVAILABLE_PERKS = {
    Movement = {
        {
            id = "double_jump",
            name = "Double Jump",
            displayName = "Double Jump",
            description = "Jump twice in mid-air for enhanced mobility",
            category = "Movement",
            type = "permanent",
            level = 5,
            credits = 500,
            cooldown = 0,
            icon = "IconPlaceholder"
        },
        {
            id = "speed_boost",
            name = "Speed Boost",
            displayName = "Speed Boost",
            description = "Temporary speed increase for quick repositioning",
            category = "Movement",
            type = "active",
            level = 3,
            credits = 300,
            cooldown = 30,
            duration = 8,
            speedMultiplier = 1.5,
            icon = "IconPlaceholder"
        },
        {
            id = "slide_boost",
            name = "Slide Boost",
            displayName = "Enhanced Sliding",
            description = "Slide faster and further with improved control",
            category = "Movement",
            type = "passive",
            level = 7,
            credits = 400,
            cooldown = 0,
            slideMultiplier = 1.3,
            icon = "IconPlaceholder"
        }
    },
    Combat = {
        {
            id = "incendiary_rounds",
            name = "Incendiary Rounds",
            displayName = "Incendiary Rounds",
            description = "Special ammunition that sets enemies on fire",
            category = "Combat",
            type = "active",
            level = 10,
            credits = 800,
            cooldown = 45,
            duration = 30,
            statusEffect = "Burning",
            icon = "IconPlaceholder"
        },
        {
            id = "frostbite_rounds",
            name = "Frostbite Rounds",
            displayName = "Frostbite Rounds",
            description = "Special ammunition that slows and can freeze enemies",
            category = "Combat",
            type = "active",
            level = 12,
            credits = 900,
            cooldown = 45,
            duration = 30,
            statusEffect = "Frostbite",
            icon = "IconPlaceholder"
        },
        {
            id = "explosive_rounds",
            name = "Explosive Rounds",
            displayName = "Explosive Rounds",
            description = "Special ammunition that explodes on impact",
            category = "Combat",
            type = "active",
            level = 15,
            credits = 1200,
            cooldown = 60,
            duration = 20,
            statusEffect = "Explosive",
            icon = "IconPlaceholder"
        }
    },
    Utility = {
        {
            id = "night_vision",
            name = "Night Vision",
            displayName = "Night Vision Enhancement",
            description = "Improved visibility during night cycles",
            category = "Utility",
            type = "toggle",
            level = 8,
            credits = 600,
            cooldown = 0,
            icon = "IconPlaceholder"
        },
        {
            id = "radar_ping",
            name = "Radar Ping",
            displayName = "Advanced Radar",
            description = "Enhanced radar detection range and frequency",
            category = "Utility",
            type = "passive",
            level = 6,
            credits = 450,
            cooldown = 0,
            radarMultiplier = 1.5,
            icon = "IconPlaceholder"
        }
    }
}

-- Player perk data
local playerPerks = {
    unlockedPerks = {},
    equippedPerks = {
        Movement = nil,
        Combat = nil,
        Utility = nil
    },
    activeCooldowns = {},
    activeEffects = {},
    originalBrightness = nil
}

-- Perk effect tracking
local connections = {}
local activeAnimations = {}

function PerkSystem:Initialize()
    print("PerkSystem: Initializing...")

    -- Initialize default unlocked perks (if any)
    self:LoadPlayerPerks()

    -- Connect character respawn
    player.CharacterAdded:Connect(function(char)
        character = char
        humanoid = char:WaitForChild("Humanoid")
        self:ReapplyPassivePerks()
    end)

    -- Set up input handling for active perks
    self:SetupPerkInputs()

    print("PerkSystem: Initialized with", self:GetUnlockedPerkCount(), "available perks")
end

function PerkSystem:LoadPlayerPerks()
    -- Initialize with double_jump unlocked by default (free perk)
    -- This would normally load from server/datastore
    playerPerks.unlockedPerks = {
        double_jump = true  -- Free default perk
    }

    print("✓ PerkSystem: Double Jump unlocked by default")
end

function PerkSystem:GetAvailablePerks()
    return AVAILABLE_PERKS
end

function PerkSystem:GetPerksByCategory(category)
    local perks = {}

    if AVAILABLE_PERKS[category] then
        for _, perk in pairs(AVAILABLE_PERKS[category]) do
            table.insert(perks, {
                data = perk,
                unlocked = self:IsPerkUnlocked(perk.id),
                equipped = self:IsPerkEquipped(perk.id),
                onCooldown = self:IsPerkOnCooldown(perk.id)
            })
        end
    end

    return perks
end

function PerkSystem:GetPerkData(perkId)
    for category, perks in pairs(AVAILABLE_PERKS) do
        for _, perk in pairs(perks) do
            if perk.id == perkId then
                return perk
            end
        end
    end
    return nil
end

function PerkSystem:IsPerkUnlocked(perkId)
    return playerPerks.unlockedPerks[perkId] == true
end

function PerkSystem:IsPerkEquipped(perkId)
    for category, equippedPerk in pairs(playerPerks.equippedPerks) do
        if equippedPerk and equippedPerk.id == perkId then
            return true
        end
    end
    return false
end

function PerkSystem:IsPerkOnCooldown(perkId)
    return playerPerks.activeCooldowns[perkId] and playerPerks.activeCooldowns[perkId] > tick()
end

function PerkSystem:CanUnlockPerk(perkId, playerLevel, playerCredits)
    local perk = self:GetPerkData(perkId)
    if not perk then return false end

    return (playerLevel or 1) >= perk.level and (playerCredits or 0) >= perk.credits
end

function PerkSystem:UnlockPerk(perkId)
    if self:IsPerkUnlocked(perkId) then
        return false, "Perk already unlocked"
    end

    local perk = self:GetPerkData(perkId)
    if not perk then
        return false, "Perk not found"
    end

    -- This would normally validate with server and deduct credits
    playerPerks.unlockedPerks[perkId] = true

    print("Unlocked perk:", perk.displayName)
    return true, "Perk unlocked successfully"
end

function PerkSystem:EquipPerk(perkId)
    if not self:IsPerkUnlocked(perkId) then
        return false, "Perk not unlocked"
    end

    local perk = self:GetPerkData(perkId)
    if not perk then
        return false, "Perk not found"
    end

    -- Unequip current perk in this category
    if playerPerks.equippedPerks[perk.category] then
        self:UnequipPerk(playerPerks.equippedPerks[perk.category].id)
    end

    -- Equip new perk
    playerPerks.equippedPerks[perk.category] = perk

    -- Apply perk effects
    if perk.type == "permanent" or perk.type == "passive" then
        self:ApplyPerkEffect(perk)
    end

    print("Equipped perk:", perk.displayName)
    return true, "Perk equipped"
end

function PerkSystem:UnequipPerk(perkId)
    local perk = self:GetPerkData(perkId)
    if not perk then return false end

    -- Remove perk effects
    self:RemovePerkEffect(perk)

    -- Remove from equipped
    playerPerks.equippedPerks[perk.category] = nil

    print("Unequipped perk:", perk.displayName)
    return true
end

function PerkSystem:ActivatePerk(perkId)
    if not self:IsPerkEquipped(perkId) then
        return false, "Perk not equipped"
    end

    if self:IsPerkOnCooldown(perkId) then
        return false, "Perk on cooldown"
    end

    local perk = self:GetPerkData(perkId)
    if not perk or perk.type ~= "active" then
        return false, "Perk cannot be activated"
    end

    -- Apply perk effect
    self:ApplyPerkEffect(perk)

    -- Start cooldown
    if perk.cooldown > 0 then
        playerPerks.activeCooldowns[perkId] = tick() + perk.cooldown
    end

    -- Remove effect after duration
    if perk.duration then
        spawn(function()
            wait(perk.duration)
            self:RemovePerkEffect(perk)
        end)
    end

    print("Activated perk:", perk.displayName)
    return true, "Perk activated"
end

function PerkSystem:ApplyPerkEffect(perk)
    if not character or not humanoid then return end

    if perk.id == "double_jump" then
        self:ApplyDoubleJump(perk)
    elseif perk.id == "speed_boost" then
        self:ApplySpeedBoost(perk)
    elseif perk.id == "slide_boost" then
        self:ApplySlideBoost(perk)
    elseif perk.id == "night_vision" then
        self:ApplyNightVision(perk)
    elseif perk.id == "radar_ping" then
        self:ApplyRadarEnhancement(perk)
    elseif perk.statusEffect then
        self:ApplySpecialRounds(perk)
    end

    playerPerks.activeEffects[perk.id] = true
end

function PerkSystem:RemovePerkEffect(perk)
    if not perk then return end

    if perk.id == "double_jump" then
        self:RemoveDoubleJump(perk)
    elseif perk.id == "speed_boost" then
        self:RemoveSpeedBoost(perk)
    elseif perk.id == "slide_boost" then
        self:RemoveSlideBoost(perk)
    elseif perk.id == "night_vision" then
        self:RemoveNightVision(perk)
    elseif perk.statusEffect then
        self:RemoveSpecialRounds(perk)
    end

    playerPerks.activeEffects[perk.id] = nil
end

-- Specific perk implementations
function PerkSystem:ApplyDoubleJump(perk)
    local jumpCount = 0

    connections[perk.id] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.Space then
            if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and
               humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                jumpCount = 0
            else
                if jumpCount < 1 then
                    jumpCount = jumpCount + 1
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

                    -- Add extra jump force
                    local bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                    bodyVelocity.Velocity = Vector3.new(0, 50, 0)
                    bodyVelocity.Parent = character.HumanoidRootPart

                    spawn(function()
                        wait(0.3)
                        if bodyVelocity.Parent then
                            bodyVelocity:Destroy()
                        end
                    end)
                end
            end
        end
    end)

    -- Reset jump count when landing
    connections[perk.id .. "_reset"] = humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed then
            jumpCount = 0
        end
    end)
end

function PerkSystem:RemoveDoubleJump(perk)
    if connections[perk.id] then
        connections[perk.id]:Disconnect()
        connections[perk.id] = nil
    end
    if connections[perk.id .. "_reset"] then
        connections[perk.id .. "_reset"]:Disconnect()
        connections[perk.id .. "_reset"] = nil
    end
end

function PerkSystem:ApplySpeedBoost(perk)
    if humanoid then
        local originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = originalSpeed * (perk.speedMultiplier or 1.5)

        -- Create speed effect
        self:CreateSpeedEffect(character.HumanoidRootPart)
    end
end

function PerkSystem:RemoveSpeedBoost(perk)
    if humanoid then
        -- Reset to default speed (would need to track original speed properly)
        humanoid.WalkSpeed = 16
    end

    -- Remove speed effect
    self:RemoveSpeedEffect(character.HumanoidRootPart)
end

function PerkSystem:CreateSpeedEffect(rootPart)
    if not rootPart then return end

    local speedEffect = Instance.new("Attachment")
    speedEffect.Name = "SpeedEffect"
    speedEffect.Parent = rootPart

    -- Add particle effect for speed boost
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "SpeedParticles"
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Color = ColorSequence.new(Color3.fromRGB(0, 206, 209))
    particles.Size = NumberSequence.new(0.2)
    particles.Lifetime = NumberRange.new(0.5)
    particles.Rate = 50
    particles.Speed = NumberRange.new(5)
    particles.Parent = speedEffect
end

function PerkSystem:RemoveSpeedEffect(rootPart)
    if rootPart then
        local speedEffect = rootPart:FindFirstChild("SpeedEffect")
        if speedEffect then
            speedEffect:Destroy()
        end
    end
end

function PerkSystem:ApplySpecialRounds(perk)
    -- This would integrate with the weapon system to modify bullet effects
    print("Applied special rounds:", perk.statusEffect)

    -- Store active special rounds effect
    playerPerks.activeSpecialRounds = perk.statusEffect
end

function PerkSystem:RemoveSpecialRounds(perk)
    playerPerks.activeSpecialRounds = nil
    print("Removed special rounds:", perk.statusEffect)
end

function PerkSystem:ApplyNightVision(perk)
    -- This would modify lighting/camera effects
    local lighting = game:GetService("Lighting")

    -- Store original brightness
    if not playerPerks.originalBrightness then
        playerPerks.originalBrightness = lighting.Brightness
    end

    -- Enhance lighting
    lighting.Brightness = math.max(lighting.Brightness, 2)

    print("Night vision activated")
end

function PerkSystem:RemoveNightVision(perk)
    local lighting = game:GetService("Lighting")

    if playerPerks.originalBrightness then
        lighting.Brightness = playerPerks.originalBrightness
        playerPerks.originalBrightness = nil
    end

    print("Night vision deactivated")
end

function PerkSystem:ApplyRadarEnhancement(perk)
    -- This would integrate with radar system
    print("Radar enhancement applied, multiplier:", perk.radarMultiplier)
end

function PerkSystem:ApplySlideBoost(perk)
    -- This would integrate with movement system
    print("Slide boost applied, multiplier:", perk.slideMultiplier)
end

function PerkSystem:RemoveSlideBoost(perk)
    print("Slide boost removed")
end

function PerkSystem:SetupPerkInputs()
    -- Set up default keybinds for activating perks
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- P key to activate equipped perks (placeholder keybind)
        if input.KeyCode == Enum.KeyCode.P then
            for category, equippedPerk in pairs(playerPerks.equippedPerks) do
                if equippedPerk and equippedPerk.type == "active" then
                    self:ActivatePerk(equippedPerk.id)
                    break -- Only activate first active perk found
                end
            end
        end
    end)
end

function PerkSystem:ReapplyPassivePerks()
    -- Reapply passive and permanent perks after respawn
    for category, equippedPerk in pairs(playerPerks.equippedPerks) do
        if equippedPerk and (equippedPerk.type == "permanent" or equippedPerk.type == "passive") then
            spawn(function()
                wait(1) -- Wait for character to fully load
                self:ApplyPerkEffect(equippedPerk)
            end)
        end
    end
end

function PerkSystem:GetEquippedPerks()
    return playerPerks.equippedPerks
end

function PerkSystem:GetUnlockedPerkCount()
    local count = 0
    for perkId, unlocked in pairs(playerPerks.unlockedPerks) do
        if unlocked then count = count + 1 end
    end
    return count
end

function PerkSystem:GetPerkCooldownTime(perkId)
    if not playerPerks.activeCooldowns[perkId] then return 0 end
    return math.max(0, playerPerks.activeCooldowns[perkId] - tick())
end

function PerkSystem:GetActiveSpecialRounds()
    return playerPerks.activeSpecialRounds
end

function PerkSystem:GetPlayerPerkData()
    return {
        unlockedPerks = playerPerks.unlockedPerks,
        equippedPerks = playerPerks.equippedPerks,
        activeCooldowns = playerPerks.activeCooldowns,
        activeEffects = playerPerks.activeEffects
    }
end

return PerkSystem