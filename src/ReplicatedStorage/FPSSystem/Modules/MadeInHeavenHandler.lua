--[[
	Made in Heaven Handler Module
	Manages all Made in Heaven stand abilities, VFX, and mechanics
	Inspired by JoJo's Bizarre Adventure
]]--

local MadeInHeavenHandler = {}
MadeInHeavenHandler.__index = MadeInHeavenHandler

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
	-- Ascension
	ASCENSION_HEIGHT = 70,
	ASCENSION_DURATION = 3,
	GLITCH_DURATION = 2,
	GLITCH_INTENSITY = 0.5,
	SLAM_DAMAGE = 50,
	SLAM_RADIUS = 25,
	VOICELINE_DELAY = 30,

	-- Stand
	STAND_OFFSET = CFrame.new(0, 0, -3) * CFrame.Angles(0, 0, 0),
	STAND_TRANSPARENCY = 0.3,

	-- Moves
	BARRAGE_DURATION = 2,
	BARRAGE_HIT_RATE = 0.05, -- hits every 0.05 seconds
	BARRAGE_DAMAGE = 8,
	BARRAGE_RANGE = 10,

	HEAVY_PUNCH_DAMAGE = 40,
	HEAVY_PUNCH_RANGE = 12,
	HEART_RIP_HOLD_TIME = 2,
	HEART_RIP_HEALTH_PERCENT = 0.25,

	KNIFE_COUNT = 5,
	KNIFE_DAMAGE = 15,
	KNIFE_SPEED = 150,
	KNIFE_CHARGE_TIME = 4,
	KNIFE_MAX_DAMAGE = 125,

	DASH_SPEED = 100,
	DASH_DISTANCE = 40,
	DASH_COMBO_HITS = 8,
	DASH_HIT_DAMAGE = 12,

	BLOCK_THRESHOLD = 200,
	BLOCK_STUN_DURATION = 1.5,

	-- Cooldowns
	COOLDOWNS = {
		E = 4,
		R = 8,
		RHold = 20,
		T = 5,
		THold = 10,
		G = 15,
		F = 20,
		HPlus = 300, -- 5 minutes
	},

	-- Passives
	DEFLECT_CHANCE = 0.25,
	REGEN_MULTIPLIER = 1.25,

	-- Universe Reset
	UNIVERSE_RESET_DURATION = 60,
	TIME_ACCELERATION = 10,
	UNLOCK_DELAY = 90, -- 1.5 minutes before H+ available
}

-- References
local AbilitiesFolder = ReplicatedStorage:WaitForChild("Abilities")
local SFXFolder = AbilitiesFolder:FindFirstChild("SFX")
if not SFXFolder then
	-- Create SFX folder if it doesn't exist
	SFXFolder = Instance.new("Folder")
	SFXFolder.Name = "SFX"
	SFXFolder.Parent = AbilitiesFolder
	print("✓ Created SFX folder in Abilities")
end

-- Audio
local AUDIO = {
	Crucified = SFXFolder:FindFirstChild("Crucified"),
	Bible = SFXFolder:FindFirstChild("Bible"),
	MIHSummon = SFXFolder:FindFirstChild("MIHSummon"),
	Dash = SFXFolder:FindFirstChild("Dash"),
	UniverseReset = SFXFolder:FindFirstChild("UniverseReset"),
	HeavenSlice = SFXFolder:FindFirstChild("HeavenSlice"),
	PucchiVoiceline = SFXFolder:FindFirstChild("PucchiVoiceline"),
}

-- Constructor
function MadeInHeavenHandler.new(player, character)
	local self = setmetatable({}, MadeInHeavenHandler)

	self.Player = player
	self.Character = character
	self.Humanoid = character:WaitForChild("Humanoid")
	self.HumanoidRootPart = character:WaitForChild("HumanoidRootPart")

	self.StandSummoned = false
	self.StandModel = nil
	self.AbilityUnlocked = false
	self.UniverseResetAvailable = false

	self.Cooldowns = {}
	self.ActiveEffects = {}
	self.Connections = {}

	self.BlockActive = false
	self.BlockDamageAbsorbed = 0

	-- Set up health regen passive
	self:SetupHealthRegen()

	return self
end

-- Health Regen Passive
function MadeInHeavenHandler:SetupHealthRegen()
	-- Apply 1.25x health regen when stand is active
	local regenConnection = RunService.Heartbeat:Connect(function()
		if self.StandSummoned and self.Humanoid and self.Humanoid.Health > 0 then
			local maxHealth = self.Humanoid.MaxHealth
			local currentHealth = self.Humanoid.Health

			-- Apply regen (1.25x normal regen rate)
			-- Normal regen is about 1% max health per second
			local baseRegenRate = maxHealth * 0.01
			local mihRegenRate = baseRegenRate * CONFIG.REGEN_MULTIPLIER
			local regenAmount = mihRegenRate / 60 -- Per frame (assuming 60 FPS)

			if currentHealth < maxHealth then
				self.Humanoid.Health = math.min(currentHealth + regenAmount, maxHealth)
			end
		end
	end)

	table.insert(self.Connections, regenConnection)
end

-- Stand Management
function MadeInHeavenHandler:CreateStand()
	-- Find the MadeInHeaven stand model in ReplicatedStorage
	local standsFolder = AbilitiesFolder:FindFirstChild("Stands")
	if not standsFolder then
		standsFolder = Instance.new("Folder")
		standsFolder.Name = "Stands"
		standsFolder.Parent = AbilitiesFolder
		warn("Created Stands folder - please add MadeInHeaven model to ReplicatedStorage.Abilities.Stands")
	end
	
	local mihFolder = standsFolder:FindFirstChild("MadeInHeaven")
	local standTemplate = mihFolder and mihFolder:FindFirstChild("MadeInHeaven")
	
	if standTemplate and standTemplate:IsA("Model") then
		local stand = standTemplate:Clone()
		
		-- Ensure all parts are properly configured
		for _, part in ipairs(stand:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Anchored = false
			end
		end
		
		-- Find the main body part (usually Torso, UpperTorso, or HumanoidRootPart)
		local primaryPart = stand:FindFirstChild("Torso") or stand:FindFirstChild("UpperTorso") or stand:FindFirstChild("HumanoidRootPart")
		
		if primaryPart then
			stand.PrimaryPart = primaryPart
			print("✓ Using MadeInHeaven stand model from workspace, PrimaryPart:", primaryPart.Name)
		else
			-- If no standard parts found, use first BasePart
			for _, part in ipairs(stand:GetChildren()) do
				if part:IsA("BasePart") then
					stand.PrimaryPart = part
					print("✓ Using MadeInHeaven stand model, PrimaryPart set to:", part.Name)
					break
				end
			end
		end
		
		return stand
	else
		warn("⚠ MadeInHeaven stand model not found in workspace!")
		warn("💡 Please ensure there's a Model named 'MadeInHeaven' in workspace")
		
		-- Fallback: Create basic stand rig
		local stand = Instance.new("Model")
		stand.Name = "MadeInHeaven_Fallback"

		local base = Instance.new("Part")
		base.Name = "Base"
		base.Size = Vector3.new(2, 5, 1)
		base.Transparency = CONFIG.STAND_TRANSPARENCY
		base.CanCollide = false
		base.Anchored = false
		base.Material = Enum.Material.Neon
		base.Color = Color3.fromRGB(200, 200, 255)
		base.Parent = stand

		local glow = Instance.new("Part")
		glow.Name = "Glow"
		glow.Size = Vector3.new(2.2, 5.2, 1.2)
		glow.Transparency = 0.6
		glow.CanCollide = false
		glow.Anchored = false
		glow.Material = Enum.Material.Neon
		glow.Color = Color3.fromRGB(255, 255, 200)
		glow.Parent = stand

		-- Weld glow to base
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = base
		weld.Part1 = glow
		weld.Parent = base

		stand.PrimaryPart = base

		return stand
	end
end

function MadeInHeavenHandler:SummonStand()
	if self.StandSummoned then return end

	self.StandModel = self:CreateStand()
	self.StandModel.Parent = workspace

	-- Check if stand has AnimationController and play idle if available
	local animController = self.StandModel:FindFirstChildOfClass("AnimationController")
	if animController then
		print("✓ Stand has AnimationController")
		
		-- Look for idle animation in the stand model
		local idleAnim = self.StandModel:FindFirstChild("Idle", true) or self.StandModel:FindFirstChild("IdleAnimation", true)
		if idleAnim and idleAnim:IsA("Animation") then
			local animator = animController:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = animController
			end
			
			local success, track = pcall(function()
				return animator:LoadAnimation(idleAnim)
			end)
			
			if success and track then
				track.Looped = true
				track.Priority = Enum.AnimationPriority.Idle
				track:Play()
				print("✓ Playing stand idle animation")
			end
		end
	end

	-- Attach stand to player
	local motor = Instance.new("Motor6D")
	motor.Name = "StandMotor"
	motor.Part0 = self.HumanoidRootPart
	motor.Part1 = self.StandModel.PrimaryPart
	motor.C1 = CONFIG.STAND_OFFSET
	motor.Parent = self.HumanoidRootPart

	-- Add aura effect
	self:AddStandAura()

	-- Play summon sound
	if AUDIO.MIHSummon then
		local sound = AUDIO.MIHSummon:Clone()
		sound.Parent = self.HumanoidRootPart
		sound:Play()
		game:GetService("Debris"):AddItem(sound, sound.TimeLength)
	end

	self.StandSummoned = true
	print("✓ Made In Heaven stand summoned!")
end

function MadeInHeavenHandler:DismissStand()
	if not self.StandSummoned then return end

	if self.StandModel then
		self.StandModel:Destroy()
		self.StandModel = nil
	end

	self.StandSummoned = false
end

function MadeInHeavenHandler:AddStandAura()
	if not self.StandModel or not self.StandModel.PrimaryPart then return end

	-- Clone aura from Yona VFX Pack
	local vfxPack = workspace:FindFirstChild("Yona VFX Pack")
	if vfxPack then
		local playerVFX = vfxPack:FindFirstChild("Player-VFX")
		if playerVFX then
			local healthDummy = playerVFX:FindFirstChild("Health Dummy")
			if healthDummy and healthDummy:FindFirstChild("Torso") then
				for _, child in ipairs(healthDummy.Torso:GetDescendants()) do
					if child:IsA("ParticleEmitter") and child.Name == "Aura" then
						local aura = child:Clone()
						aura.Parent = self.StandModel.PrimaryPart
						-- Recolor to white/yellow
						aura.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200))
						break
					end
				end
			end
		end
	end
end

-- Cooldown Management
function MadeInHeavenHandler:IsOnCooldown(moveKey)
	return self.Cooldowns[moveKey] and self.Cooldowns[moveKey] > tick()
end

function MadeInHeavenHandler:SetCooldown(moveKey, duration)
	self.Cooldowns[moveKey] = tick() + duration
end

function MadeInHeavenHandler:GetRemainingCooldown(moveKey)
	if not self:IsOnCooldown(moveKey) then return 0 end
	return self.Cooldowns[moveKey] - tick()
end

-- VFX Utilities
function MadeInHeavenHandler:GetVFXFromPack(category, effectName)
	local vfxPack = workspace:FindFirstChild("Yona VFX Pack")
	if not vfxPack then return nil end

	local categoryFolder = vfxPack:FindFirstChild(category)
	if not categoryFolder then return nil end

	return categoryFolder:FindFirstChild(effectName)
end

function MadeInHeavenHandler:CreateHitEffect(position, effectType)
	effectType = effectType or "Hit-01"

	local hitEffect = self:GetVFXFromPack("Combat-VFX", effectType)
	if hitEffect then
		local effect = hitEffect:Clone()
		effect.Parent = workspace

		if effect:IsA("Model") and effect.PrimaryPart then
			effect:SetPrimaryPartCFrame(CFrame.new(position))
		elseif effect:IsA("BasePart") then
			effect.Position = position
		end

		-- Emit particles and destroy
		task.delay(0.1, function()
			for _, desc in ipairs(effect:GetDescendants()) do
				if desc:IsA("ParticleEmitter") then
					desc:Emit(desc:GetAttribute("EmitCount") or 10)
				end
			end
		end)

		game:GetService("Debris"):AddItem(effect, 2)
		return effect
	end
end

function MadeInHeavenHandler:CreateExplosionEffect(position, effectType)
	effectType = effectType or "Explosion-02"

	local explosionEffect = self:GetVFXFromPack("Explosion-VFX", effectType)
	if explosionEffect then
		local effect = explosionEffect:Clone()
		effect.Parent = workspace

		if effect:IsA("Model") and effect.PrimaryPart then
			effect:SetPrimaryPartCFrame(CFrame.new(position))
		elseif effect:IsA("BasePart") then
			effect.Position = position
		end

		task.delay(0.1, function()
			for _, desc in ipairs(effect:GetDescendants()) do
				if desc:IsA("ParticleEmitter") then
					desc:Emit(desc:GetAttribute("EmitCount") or 20)
				end
			end
		end)

		game:GetService("Debris"):AddItem(effect, 3)
		return effect
	end
end

-- Damage Utilities
function MadeInHeavenHandler:DealDamage(targetHumanoid, damage, damageType)
	if targetHumanoid and targetHumanoid.Health > 0 then
		targetHumanoid:TakeDamage(damage)
		return true
	end
	return false
end

function MadeInHeavenHandler:GetPlayersInRadius(position, radius, excludeSelf)
	local players = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if not (excludeSelf and player == self.Player) then
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")

				if hrp and humanoid and humanoid.Health > 0 then
					local distance = (hrp.Position - position).Magnitude
					if distance <= radius then
						table.insert(players, {
							Player = player,
							Character = character,
							Humanoid = humanoid,
							HumanoidRootPart = hrp,
							Distance = distance
						})
					end
				end
			end
		end
	end

	return players
end

-- Move Methods (Client-side visualizations)
function MadeInHeavenHandler:PlayBarrageAnimation()
	if not self.StandModel or not self.StandModel.PrimaryPart then return end

	-- Rapid punch animation (visual only)
	local stand = self.StandModel.PrimaryPart

	task.spawn(function()
		for i = 1, 40 do -- 2 second barrage
			-- Alternate punch positions
			local offset = i % 2 == 0 and CFrame.new(0.5, 0, -1) or CFrame.new(-0.5, 0, -1)

			local motor = self.HumanoidRootPart:FindFirstChild("StandMotor")
			if motor then
				motor.C1 = CONFIG.STAND_OFFSET * offset
			end

			task.wait(0.05)
		end

		-- Reset position
		local motor = self.HumanoidRootPart:FindFirstChild("StandMotor")
		if motor then
			motor.C1 = CONFIG.STAND_OFFSET
		end
	end)
end

function MadeInHeavenHandler:PlayPunchAnimation(heavy)
	if not self.StandModel or not self.StandModel.PrimaryPart then return end

	local motor = self.HumanoidRootPart:FindFirstChild("StandMotor")
	if not motor then return end

	-- Wind up
	local windupTween = TweenService:Create(
		motor,
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{C1 = CONFIG.STAND_OFFSET * CFrame.new(0, 0, 1)}
	)
	windupTween:Play()
	windupTween.Completed:Wait()

	-- Punch forward
	local punchForce = heavy and 3 or 2
	local punchTween = TweenService:Create(
		motor,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{C1 = CONFIG.STAND_OFFSET * CFrame.new(0, 0, -punchForce)}
	)
	punchTween:Play()
	punchTween.Completed:Wait()

	task.wait(0.3)

	-- Return to position
	local returnTween = TweenService:Create(
		motor,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{C1 = CONFIG.STAND_OFFSET}
	)
	returnTween:Play()
end

function MadeInHeavenHandler:PlayBlockAnimation()
	if not self.StandModel or not self.StandModel.PrimaryPart then return end

	local motor = self.HumanoidRootPart:FindFirstChild("StandMotor")
	if not motor then return end

	-- Move stand in front of player
	local blockTween = TweenService:Create(
		motor,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{C1 = CONFIG.STAND_OFFSET * CFrame.new(0, 0, -2) * CFrame.Angles(0, 0, math.rad(10))}
	)
	blockTween:Play()

	-- Add barrier effect
	local barrier = Instance.new("Part")
	barrier.Name = "Barrier"
	barrier.Size = Vector3.new(6, 6, 0.2)
	barrier.Transparency = 0.7
	barrier.CanCollide = false
	barrier.Anchored = true
	barrier.Material = Enum.Material.ForceField
	barrier.Color = Color3.fromRGB(100, 200, 255)
	barrier.Parent = workspace

	-- Position in front of player
	table.insert(self.ActiveEffects, barrier)

	-- Update barrier position
	local updateConnection = RunService.Heartbeat:Connect(function()
		if barrier and barrier.Parent then
			barrier.CFrame = self.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
		end
	end)
	table.insert(self.Connections, updateConnection)

	return barrier, updateConnection
end

function MadeInHeavenHandler:StopBlockAnimation()
	if not self.StandModel then return end

	local motor = self.HumanoidRootPart:FindFirstChild("StandMotor")
	if motor then
		-- Return to normal position
		local returnTween = TweenService:Create(
			motor,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{C1 = CONFIG.STAND_OFFSET}
		)
		returnTween:Play()
	end

	-- Remove barrier
	for i, effect in ipairs(self.ActiveEffects) do
		if effect and effect.Name == "Barrier" then
			effect:Destroy()
			table.remove(self.ActiveEffects, i)
			break
		end
	end
end

function MadeInHeavenHandler:CreateAfterimage()
	if not self.Character then return end

	local clone = Instance.new("Model")
	clone.Name = "Afterimage"
	clone.Parent = workspace

	for _, part in ipairs(self.Character:GetChildren()) do
		if part:IsA("BasePart") then
			local partClone = part:Clone()
			partClone.Transparency = 0.7
			partClone.CanCollide = false
			partClone.Anchored = true
			partClone.Color = Color3.fromRGB(200, 200, 255)

			-- Remove unnecessary children
			for _, child in ipairs(partClone:GetChildren()) do
				if not child:IsA("SpecialMesh") and not child:IsA("Decal") then
					child:Destroy()
				end
			end

			partClone.Parent = clone
		end
	end

	-- Fade out
	task.spawn(function()
		for i = 1, 10 do
			for _, part in ipairs(clone:GetChildren()) do
				if part:IsA("BasePart") then
					part.Transparency = part.Transparency + 0.03
				end
			end
			task.wait(0.03)
		end
		clone:Destroy()
	end)

	game:GetService("Debris"):AddItem(clone, 0.5)
end

-- Projectile Deflection (Passive)
function MadeInHeavenHandler:TryDeflectProjectile(projectile, sourcePlayer)
	if not self.StandSummoned then return false end

	-- 25% chance to deflect
	if math.random() > CONFIG.DEFLECT_CHANCE then return false end

	-- Play deflect animation
	if self.StandModel and self.StandModel.PrimaryPart then
		local motor = self.HumanoidRootPart:FindFirstChild("StandMotor")
		if motor then
			-- Quick punch toward projectile
			local originalC1 = motor.C1
			motor.C1 = CONFIG.STAND_OFFSET * CFrame.new(0, 0, -1)

			task.delay(0.1, function()
				motor.C1 = originalC1
			end)
		end

		-- Create hit VFX
		self:CreateHitEffect(projectile.Position, "Hit-01")
	end

	-- Reverse projectile direction
	if projectile:IsA("BasePart") then
		local bodyVelocity = projectile:FindFirstChildOfClass("BodyVelocity")
		if bodyVelocity then
			bodyVelocity.Velocity = -bodyVelocity.Velocity
		end
	end

	return true
end

-- Cleanup
function MadeInHeavenHandler:Destroy()
	for _, connection in pairs(self.Connections) do
		if connection then
			connection:Disconnect()
		end
	end

	if self.StandModel then
		self.StandModel:Destroy()
	end

	for _, effect in pairs(self.ActiveEffects) do
		if effect and effect.Parent then
			effect:Destroy()
		end
	end

	self.Connections = {}
	self.ActiveEffects = {}
end

return MadeInHeavenHandler
