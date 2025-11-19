--[[
	Spicy Bee Stinger - Client Script
	Hybrid poison/mobility weapon
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")

-- Wait for FPSSystem
repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

-- Get weapon configuration
local CONFIG = WeaponConfig:GetWeaponConfig("SpicyBeeStinger") or {
	Damage = 35,
	Range = 8,
	DashDistance = 30,
	DashCooldown = 5,
	PoisonDamage = 5,
	PoisonDuration = 8,
	PoisonTickRate = 1,
	WalkSpeedMultiplier = 1.3,
}

-- State
local Equipped = false
local Attacking = false
local Cooldowns = {
	Attack = 0,
	Dash = 0,
	PoisonCloud = 0,
}

local OriginalWalkSpeed = 16
local Connections = {}

-- Cooldown helpers
local function IsOnCooldown(ability)
	return Cooldowns[ability] > tick()
end

local function SetCooldown(ability, duration)
	Cooldowns[ability] = tick() + duration
end

local function GetRemainingCooldown(ability)
	if not IsOnCooldown(ability) then return 0 end
	return Cooldowns[ability] - tick()
end

-- VFX Utilities
local function CreateSlashEffect()
	local slash = Instance.new("Part")
	slash.Name = "SlashEffect"
	slash.Size = Vector3.new(4, 0.2, 2)
	slash.Material = Enum.Material.Neon
	slash.Color = Color3.fromRGB(255, 200, 0)
	slash.Transparency = 0.3
	slash.CanCollide = false
	slash.Anchored = true
	slash.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, 0, math.rad(45))
	slash.Parent = workspace

	-- Fade out
	local tween = TweenService:Create(
		slash,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 1, Size = Vector3.new(5, 0.2, 3)}
	)
	tween:Play()
	tween.Completed:Connect(function()
		slash:Destroy()
	end)
end

local function CreateDashEffect()
	local trail = Instance.new("Part")
	trail.Name = "DashTrail"
	trail.Size = Vector3.new(2, 5, 1)
	trail.Material = Enum.Material.Neon
	trail.Color = Color3.fromRGB(255, 255, 0)
	trail.Transparency = 0.5
	trail.CanCollide = false
	trail.Anchored = true
	trail.CFrame = HumanoidRootPart.CFrame
	trail.Parent = workspace

	local tween = TweenService:Create(
		trail,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{Transparency = 1}
	)
	tween:Play()
	tween.Completed:Connect(function()
		trail:Destroy()
	end)
end

-- Primary Attack
local function PrimaryAttack()
	if not Equipped or Attacking or IsOnCooldown("Attack") then return end

	Attacking = true
	SetCooldown("Attack", 0.5)

	-- Play animation (if exists)
	local animator = Humanoid:FindFirstChild("Animator")
	if animator then
		-- Look for slash animation
		local animations = Tool:FindFirstChild("Animations")
		if animations and animations:FindFirstChild("Slash") then
			local slashAnim = animator:LoadAnimation(animations.Slash)
			slashAnim:Play()
		end
	end

	-- VFX
	CreateSlashEffect()

	-- Play sound
	local slashSound = Handle:FindFirstChild("SlashSound")
	if slashSound then
		slashSound:Play()
	end

	-- Fire server event for damage
	local attackEvent = RemoteEvents:FindFirstChild("SpicyBeeStingerAttack")
	if attackEvent then
		attackEvent:FireServer("PrimaryAttack")
	end

	task.wait(0.3)
	Attacking = false
end

-- Dash Ability (E key)
local function DashAbility()
	if not Equipped or IsOnCooldown("Dash") then
		if IsOnCooldown("Dash") then
			warn("Dash on cooldown:", math.ceil(GetRemainingCooldown("Dash")), "seconds")
		end
		return
	end

	SetCooldown("Dash", CONFIG.DashCooldown)

	-- Calculate dash direction
	local camera = workspace.CurrentCamera
	local lookVector = camera.CFrame.LookVector
	local dashDirection = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

	-- Apply dash
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = dashDirection * 80
	bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
	bodyVelocity.Parent = HumanoidRootPart

	-- VFX
	for i = 1, 5 do
		task.spawn(function()
			task.wait(i * 0.05)
			CreateDashEffect()
		end)
	end

	-- Play sound
	local dashSound = Handle:FindFirstChild("DashSound")
	if dashSound then
		dashSound:Play()
	end

	-- Remove velocity after dash
	task.wait(0.3)
	bodyVelocity:Destroy()

	print("Dashed forward!")
end

-- Poison Cloud (R key)
local function PoisonCloud()
	if not Equipped or IsOnCooldown("PoisonCloud") then
		if IsOnCooldown("PoisonCloud") then
			warn("Poison Cloud on cooldown:", math.ceil(GetRemainingCooldown("PoisonCloud")), "seconds")
		end
		return
	end

	SetCooldown("PoisonCloud", 12)

	-- Get target position (raycast forward)
	local camera = workspace.CurrentCamera
	local rayOrigin = camera.CFrame.Position
	local rayDirection = camera.CFrame.LookVector * 50

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	local targetPosition = rayResult and rayResult.Position or (rayOrigin + rayDirection)

	-- Fire server event
	local attackEvent = RemoteEvents:FindFirstChild("SpicyBeeStingerAttack")
	if attackEvent then
		attackEvent:FireServer("PoisonCloud", targetPosition)
	end

	-- Play throw animation
	local animator = Humanoid:FindFirstChild("Animator")
	if animator then
		local animations = Tool:FindFirstChild("Animations")
		if animations and animations:FindFirstChild("Throw") then
			local throwAnim = animator:LoadAnimation(animations.Throw)
			throwAnim:Play()
		end
	end

	print("Poison Cloud deployed at:", targetPosition)
end

-- Tool Events
Tool.Activated:Connect(function()
	PrimaryAttack()
end)

Tool.Equipped:Connect(function()
	Equipped = true
	Character = Player.Character
	Humanoid = Character:FindFirstChild("Humanoid")
	HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

	-- Apply movement speed boost
	if Humanoid then
		OriginalWalkSpeed = Humanoid.WalkSpeed
		Humanoid.WalkSpeed = OriginalWalkSpeed * CONFIG.WalkSpeedMultiplier
	end

	print("Spicy Bee Stinger equipped - Movement speed boosted!")
end)

Tool.Unequipped:Connect(function()
	Equipped = false
	Attacking = false

	-- Restore movement speed
	if Humanoid then
		Humanoid.WalkSpeed = OriginalWalkSpeed
	end

	-- Disconnect all connections
	for _, connection in pairs(Connections) do
		if connection then
			connection:Disconnect()
		end
	end
	Connections = {}
end)

-- Input handling
Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not Equipped then return end

	if input.KeyCode == Enum.KeyCode.E then
		DashAbility()
	elseif input.KeyCode == Enum.KeyCode.R then
		PoisonCloud()
	end
end)

print("Spicy Bee Stinger client loaded")
