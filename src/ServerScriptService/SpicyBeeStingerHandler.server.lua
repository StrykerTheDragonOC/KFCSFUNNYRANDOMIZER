--[[
	Spicy Bee Stinger Server Handler
	Handles damage, poison effects, and poison cloud
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

-- Get weapon configuration
local CONFIG = WeaponConfig:GetWeaponConfig("SpicyBeeStinger") or {
	Damage = 35,
	Range = 8,
	PoisonDamage = 5,
	PoisonDuration = 8,
	PoisonTickRate = 1,
	HeadshotMultiplier = 1.5,
	BodyMultiplier = 1.0,
	LimbMultiplier = 0.8,
}

-- Poison tracking
local PoisonedPlayers = {} -- {[player] = {EndTime = tick() + duration, DamagePerTick = 5, TickRate = 1}}

-- Utility functions
local function GetCharacter(player)
	return player.Character
end

local function GetHumanoid(character)
	return character and character:FindFirstChild("Humanoid")
end

local function GetRootPart(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function GetPlayersInRange(position, range, excludePlayer)
	local targets = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= excludePlayer then
			local character = GetCharacter(player)
			local humanoid = GetHumanoid(character)
			local rootPart = GetRootPart(character)

			if humanoid and humanoid.Health > 0 and rootPart then
				local distance = (rootPart.Position - position).Magnitude
				if distance <= range then
					table.insert(targets, {
						Player = player,
						Character = character,
						Humanoid = humanoid,
						RootPart = rootPart,
						Distance = distance
					})
				end
			end
		end
	end

	return targets
end

local function DealDamage(humanoid, damage)
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(damage)
		return true
	end
	return false
end

-- Poison system
local function ApplyPoison(player, attacker)
	if PoisonedPlayers[player] then
		-- Refresh poison duration
		PoisonedPlayers[player].EndTime = tick() + CONFIG.PoisonDuration
		print(player.Name, "poison refreshed by", attacker.Name)
	else
		-- New poison
		PoisonedPlayers[player] = {
			EndTime = tick() + CONFIG.PoisonDuration,
			DamagePerTick = CONFIG.PoisonDamage,
			TickRate = CONFIG.PoisonTickRate,
			Attacker = attacker
		}

		-- Add poison visual effect
		local character = GetCharacter(player)
		if character then
			local rootPart = GetRootPart(character)
			if rootPart then
				-- Create poison particles
				local poisonParticles = Instance.new("ParticleEmitter")
				poisonParticles.Name = "PoisonEffect"
				poisonParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
				poisonParticles.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
				poisonParticles.Size = NumberSequence.new(0.5, 1)
				poisonParticles.Lifetime = NumberRange.new(1, 2)
				poisonParticles.Rate = 20
				poisonParticles.Speed = NumberRange.new(1, 2)
				poisonParticles.SpreadAngle = Vector2.new(30, 30)
				poisonParticles.Parent = rootPart

				-- Remove particles when poison ends
				task.delay(CONFIG.PoisonDuration, function()
					if poisonParticles and poisonParticles.Parent then
						poisonParticles:Destroy()
					end
				end)
			end
		end

		print(player.Name, "poisoned by", attacker.Name)
	end
end

-- Poison tick loop
task.spawn(function()
	while true do
		task.wait(1) -- Check every second

		for player, poisonData in pairs(PoisonedPlayers) do
			if tick() >= poisonData.EndTime then
				-- Poison expired
				PoisonedPlayers[player] = nil
				print(player.Name, "poison expired")
			else
				-- Deal poison damage
				local character = GetCharacter(player)
				local humanoid = GetHumanoid(character)
				if humanoid and humanoid.Health > 0 then
					DealDamage(humanoid, poisonData.DamagePerTick)
				else
					-- Player died, remove poison
					PoisonedPlayers[player] = nil
				end
			end
		end
	end
end)

-- Attack handlers
local function HandlePrimaryAttack(attacker)
	local character = GetCharacter(attacker)
	local rootPart = GetRootPart(character)
	if not rootPart then return end

	-- Find targets in melee range
	local targets = GetPlayersInRange(rootPart.Position + rootPart.CFrame.LookVector * 4, CONFIG.Range, attacker)

	if #targets > 0 then
		for _, target in ipairs(targets) do
			-- Deal damage
			DealDamage(target.Humanoid, CONFIG.Damage)

			-- Apply poison
			ApplyPoison(target.Player, attacker)

			print(attacker.Name, "slashed", target.Player.Name, "with poison")
		end
	end
end

local function HandlePoisonCloud(attacker, targetPosition)
	local character = GetCharacter(attacker)
	if not character then return end

	print(attacker.Name, "created poison cloud at", targetPosition)

	-- Create poison cloud part
	local cloud = Instance.new("Part")
	cloud.Name = "PoisonCloud"
	cloud.Size = Vector3.new(15, 8, 15)
	cloud.Shape = Enum.PartType.Ball
	cloud.Material = Enum.Material.Neon
	cloud.Color = Color3.fromRGB(100, 255, 100)
	cloud.Transparency = 0.7
	cloud.CanCollide = false
	cloud.Anchored = true
	cloud.Position = targetPosition
	cloud.Parent = workspace

	-- Add glow
	local glow = Instance.new("PointLight")
	glow.Brightness = 2
	glow.Range = 20
	glow.Color = Color3.fromRGB(100, 255, 100)
	glow.Parent = cloud

	-- Add particles
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
	particles.Size = NumberSequence.new(2, 3)
	particles.Lifetime = NumberRange.new(2, 4)
	particles.Rate = 50
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = cloud

	-- Damage players inside cloud
	task.spawn(function()
		local cloudDuration = 6
		local cloudStartTime = tick()

		while tick() - cloudStartTime < cloudDuration do
			local targets = GetPlayersInRange(cloud.Position, 10, attacker)

			for _, target in ipairs(targets) do
				-- Apply poison to all players in cloud
				ApplyPoison(target.Player, attacker)
			end

			task.wait(0.5)
		end

		-- Remove cloud
		cloud:Destroy()
	end)

	Debris:AddItem(cloud, 6.5)
end

-- Set up RemoteEvent
local attackEvent = RemoteEvents:FindFirstChild("SpicyBeeStingerAttack")
if not attackEvent then
	attackEvent = Instance.new("RemoteEvent")
	attackEvent.Name = "SpicyBeeStingerAttack"
	attackEvent.Parent = RemoteEvents
	print("Created SpicyBeeStingerAttack RemoteEvent")
end

attackEvent.OnServerEvent:Connect(function(player, action, ...)
	if action == "PrimaryAttack" then
		HandlePrimaryAttack(player)
	elseif action == "PoisonCloud" then
		local targetPosition = ...
		HandlePoisonCloud(player, targetPosition)
	end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	PoisonedPlayers[player] = nil
end)

print("Spicy Bee Stinger Handler loaded")
