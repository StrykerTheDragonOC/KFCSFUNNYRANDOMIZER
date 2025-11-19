--[[
	Bible Tool - Client Script
	Activates Made In Heaven stand ability
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

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
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents

-- Remote Events
local UseAbilityEvent = RemoteEvents:WaitForChild("UseAbility")

-- Audio
local BibleSound = SFXFolder:FindFirstChild("Bible")
local CrucifiedMusic = SFXFolder:FindFirstChild("Crucified")
local PucchiVoiceline = SFXFolder:FindFirstChild("PucchiVoiceline")

-- State
local activated = false
local activating = false

-- Config
local ASCENSION_HEIGHT = 70
local ASCENSION_DURATION = 3
local VOICELINE_DELAY = 30
local GLITCH_DURATION = 2

function CreateAscensionVFX()
	-- Create particle burst
	local particle = Instance.new("ParticleEmitter")
	particle.Name = "AscensionParticles"
	particle.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200))
	particle.Size = NumberSequence.new(2, 0)
	particle.Lifetime = NumberRange.new(1, 2)
	particle.Rate = 100
	particle.Speed = NumberRange.new(10, 20)
	particle.SpreadAngle = Vector2.new(360, 360)
	particle.Parent = humanoidRootPart
	
	game:GetService("Debris"):AddItem(particle, 5)
	
	-- Create glow effect
	local glow = Instance.new("PointLight")
	glow.Brightness = 5
	glow.Range = 30
	glow.Color = Color3.fromRGB(255, 255, 200)
	glow.Parent = humanoidRootPart
	
	-- Fade glow
	task.spawn(function()
		for i = 1, 20 do
			glow.Brightness = glow.Brightness * 0.9
			task.wait(0.1)
		end
		glow:Destroy()
	end)
end

function CreateGlitchEffect()
	-- Vibrate character rapidly
	local originalCFrame = humanoidRootPart.CFrame
	
	task.spawn(function()
		for i = 1, GLITCH_DURATION * 60 do
			local offset = Vector3.new(
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10
			)
			humanoidRootPart.CFrame = originalCFrame * CFrame.new(offset)
			task.wait(1/60)
		end
		humanoidRootPart.CFrame = originalCFrame
	end)
end

function ActivateBible()
	if activated or activating then
		return
	end
	
	activating = true
	
	-- Play Bible use sound
	if BibleSound then
		local sound = BibleSound:Clone()
		sound.Parent = humanoidRootPart
		sound:Play()
		game:GetService("Debris"):AddItem(sound, sound.TimeLength)
	end
	
	-- Make player invincible
	local forceField = Instance.new("ForceField")
	forceField.Visible = false
	forceField.Parent = character
	
	-- Disable movement
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	
	-- Start ascension
	local startPos = humanoidRootPart.Position
	local targetPos = startPos + Vector3.new(0, ASCENSION_HEIGHT, 0)
	
	-- Ascend smoothly
	local ascendTween = TweenService:Create(
		humanoidRootPart,
		TweenInfo.new(ASCENSION_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = CFrame.new(targetPos) * humanoidRootPart.CFrame.Rotation}
	)
	ascendTween:Play()
	
	-- Play music at quarter ascension
	task.delay(ASCENSION_DURATION / 4, function()
		if CrucifiedMusic then
			local music = CrucifiedMusic:Clone()
			music.Parent = humanoidRootPart
			music.Looped = true
			music:Play()
			
			-- Play voiceline after 30 seconds
			task.delay(VOICELINE_DELAY, function()
				if PucchiVoiceline then
					local voiceline = PucchiVoiceline:Clone()
					voiceline.Parent = humanoidRootPart
					voiceline:Play()
				end
			end)
		end
		
		-- Create VFX burst
		CreateAscensionVFX()
	end)
	
	-- Wait for ascension to complete
	ascendTween.Completed:Wait()
	
	-- Start glitch effect
	CreateGlitchEffect()
	
	-- Wait for glitch to complete
	task.wait(GLITCH_DURATION)
	
	-- Slam down with shockwave
	local slamTween = TweenService:Create(
		humanoidRootPart,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{CFrame = CFrame.new(startPos) * humanoidRootPart.CFrame.Rotation}
	)
	slamTween:Play()
	slamTween.Completed:Wait()
	
	-- Create shockwave effect
	local shockwave = Instance.new("Part")
	shockwave.Name = "Shockwave"
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.Size = Vector3.new(0.5, 5, 5)
	shockwave.Transparency = 0.5
	shockwave.CanCollide = false
	shockwave.Anchored = true
	shockwave.Material = Enum.Material.Neon
	shockwave.Color = Color3.fromRGB(255, 255, 200)
	shockwave.CFrame = CFrame.new(startPos) * CFrame.Angles(0, 0, math.rad(90))
	shockwave.Parent = workspace
	
	-- Expand shockwave
	local expandTween = TweenService:Create(
		shockwave,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(0.5, 50, 50), Transparency = 1}
	)
	expandTween:Play()
	expandTween.Completed:Wait()
	shockwave:Destroy()
	
	-- Restore movement
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	forceField:Destroy()
	
	-- Activate Made In Heaven
	UseAbilityEvent:FireServer("MadeInHeaven", "Activate")
	
	activated = true
	activating = false
	
	-- Remove Bible tool
	task.wait(0.5)
	tool:Destroy()
	
	print("✓ Made In Heaven activated!")
end

-- Tool activation
tool.Activated:Connect(function()
	if not activated and not activating then
		ActivateBible()
	end
end)

print("Bible tool loaded - Click to activate Made In Heaven")
