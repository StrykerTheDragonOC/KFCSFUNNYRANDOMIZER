--[[
	Made In Heaven Server Handler
	Handles server-side validation and damage for all MIH abilities
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

-- References
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local UseAbilityEvent = RemoteEvents:WaitForChild("UseAbility")

-- Player states
local activeAbilities = {} -- {[player] = {ability = "MadeInHeaven", data = {}}}

-- Configuration (matches client)
local CONFIG = {
	BARRAGE_DAMAGE = 8,
	BARRAGE_HITS = 40,
	BARRAGE_RANGE = 10,
	
	HEAVY_PUNCH_DAMAGE = 40,
	HEAVY_PUNCH_RANGE = 12,
	HEAVY_PUNCH_KNOCKBACK = 50,
	
	HEART_RIP_HEALTH_PERCENT = 0.25,
	HEART_RIP_RANGE = 12,
	
	KNIFE_COUNT = 5,
	KNIFE_DAMAGE = 15,
	KNIFE_SPEED = 150,
	KNIFE_RANGE = 100,
	
	KNIFE_CHARGED_DAMAGE = 125,
	
	DASH_DAMAGE_PER_HIT = 12,
	DASH_COMBO_HITS = 8,
	DASH_RANGE = 40,
	DASH_SPEED = 100,
	
	SLAM_DAMAGE = 50,
	SLAM_RADIUS = 25,
	
	BLOCK_THRESHOLD = 200,
	BLOCK_STUN_DURATION = 1.5,
	
	UNIVERSE_RESET_DURATION = 60,
}

-- Utility Functions
local function GetCharacterFromPlayer(player)
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
			local character = GetCharacterFromPlayer(player)
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

local function DealDamage(humanoid, damage, damageType)
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(damage)
		return true
	end
	return false
end

local function ApplyKnockback(rootPart, direction, force)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = direction * force
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Parent = rootPart
	
	game:GetService("Debris"):AddItem(bodyVelocity, 0.3)
end

-- Ability Handlers
local function HandleBarrage(player)
	local character = GetCharacterFromPlayer(player)
	local rootPart = GetRootPart(character)
	if not rootPart then return end
	
	-- Get targets in range
	local targets = GetPlayersInRange(rootPart.Position + rootPart.CFrame.LookVector * 5, CONFIG.BARRAGE_RANGE, player)
	
	-- Deal damage over time
	task.spawn(function()
		for i = 1, CONFIG.BARRAGE_HITS do
			for _, target in ipairs(targets) do
				-- Re-check if still in range
				if target.RootPart then
					local distance = (target.RootPart.Position - rootPart.Position).Magnitude
					if distance <= CONFIG.BARRAGE_RANGE then
						DealDamage(target.Humanoid, CONFIG.BARRAGE_DAMAGE)
					end
				end
			end
			task.wait(0.05)
		end
	end)
	
	print(player.Name, "used Barrage on", #targets, "targets")
end

local function HandleHeavyPunch(player)
	local character = GetCharacterFromPlayer(player)
	local rootPart = GetRootPart(character)
	if not rootPart then return end
	
	-- Get target directly in front
	local targets = GetPlayersInRange(rootPart.Position + rootPart.CFrame.LookVector * 6, CONFIG.HEAVY_PUNCH_RANGE, player)
	
	if #targets > 0 then
		local target = targets[1] -- Hit first target
		DealDamage(target.Humanoid, CONFIG.HEAVY_PUNCH_DAMAGE)
		
		-- Apply knockback
		local direction = (target.RootPart.Position - rootPart.Position).Unit
		ApplyKnockback(target.RootPart, direction, CONFIG.HEAVY_PUNCH_KNOCKBACK)
		
		-- Ragdoll effect
		if target.Humanoid then
			target.Humanoid.PlatformStand = true
			task.delay(1, function()
				if target.Humanoid then
					target.Humanoid.PlatformStand = false
				end
			end)
		end
		
		print(player.Name, "Heavy Punched", target.Player.Name)
	end
end

local function HandleHeartRip(player)
	local character = GetCharacterFromPlayer(player)
	local rootPart = GetRootPart(character)
	if not rootPart then return end
	
	local targets = GetPlayersInRange(rootPart.Position + rootPart.CFrame.LookVector * 6, CONFIG.HEART_RIP_RANGE, player)
	
	if #targets > 0 then
		local target = targets[1]
		
		-- Reduce health to 25%
		local newHealth = target.Humanoid.MaxHealth * CONFIG.HEART_RIP_HEALTH_PERCENT
		target.Humanoid.Health = math.min(target.Humanoid.Health, newHealth)
		
		-- Massive knockback
		local direction = (target.RootPart.Position - rootPart.Position).Unit
		ApplyKnockback(target.RootPart, direction, 100)
		
		-- Ragdoll
		target.Humanoid.PlatformStand = true
		task.delay(2, function()
			if target.Humanoid then
				target.Humanoid.PlatformStand = false
			end
		end)
		
		print(player.Name, "ripped heart from", target.Player.Name)
	end
end

local function HandleKnifeThrow(player)
	local character = GetCharacterFromPlayer(player)
	local rootPart = GetRootPart(character)
	if not rootPart then return end
	
	-- Spawn knives
	for i = 1, CONFIG.KNIFE_COUNT do
		task.spawn(function()
			local knife = Instance.new("Part")
			knife.Name = "Knife"
			knife.Size = Vector3.new(0.5, 0.2, 2)
			knife.Material = Enum.Material.Metal
			knife.Color = Color3.fromRGB(200, 200, 200)
			knife.CanCollide = false
			knife.CFrame = rootPart.CFrame * CFrame.new((i-3) * 0.5, 0, -2)
			knife.Parent = workspace
			
			-- Add velocity
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = rootPart.CFrame.LookVector * CONFIG.KNIFE_SPEED
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Parent = knife
			
			-- Hit detection
			local touched = false
			knife.Touched:Connect(function(hit)
				if touched then return end
				
				local hitCharacter = hit.Parent
				local hitHumanoid = hitCharacter and hitCharacter:FindFirstChild("Humanoid")
				
				if hitHumanoid and hitHumanoid ~= GetHumanoid(character) then
					touched = true
					DealDamage(hitHumanoid, CONFIG.KNIFE_DAMAGE)
					knife:Destroy()
				end
			end)
			
			game:GetService("Debris"):AddItem(knife, 3)
		end)
		
		task.wait(0.05)
	end
	
	print(player.Name, "threw knives")
end

local function HandleChargedKnives(player)
	local character = GetCharacterFromPlayer(player)
	local rootPart = GetRootPart(character)
	if not rootPart then return end
	
	-- Spawn charged knives (glowing)
	for i = 1, CONFIG.KNIFE_COUNT do
		task.spawn(function()
			local knife = Instance.new("Part")
			knife.Name = "ChargedKnife"
			knife.Size = Vector3.new(0.7, 0.3, 2.5)
			knife.Material = Enum.Material.Neon
			knife.Color = Color3.fromRGB(255, 255, 100)
			knife.CanCollide = false
			knife.CFrame = rootPart.CFrame * CFrame.new((i-3) * 0.5, 0, -2)
			knife.Parent = workspace
			
			-- Glow
			local glow = Instance.new("PointLight")
			glow.Brightness = 2
			glow.Range = 10
			glow.Color = Color3.fromRGB(255, 255, 100)
			glow.Parent = knife
			
			-- Add velocity
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = rootPart.CFrame.LookVector * (CONFIG.KNIFE_SPEED * 1.5)
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Parent = knife
			
			-- Hit detection
			local touched = false
			knife.Touched:Connect(function(hit)
				if touched then return end
				
				local hitCharacter = hit.Parent
				local hitHumanoid = hitCharacter and hitCharacter:FindFirstChild("Humanoid")
				
				if hitHumanoid and hitHumanoid ~= GetHumanoid(character) then
					touched = true
					DealDamage(hitHumanoid, CONFIG.KNIFE_CHARGED_DAMAGE)
					knife:Destroy()
				end
			end)
			
			game:GetService("Debris"):AddItem(knife, 3)
		end)
		
		task.wait(0.05)
	end
	
	print(player.Name, "threw CHARGED knives")
end

local function HandleDashCombo(player)
	local character = GetCharacterFromPlayer(player)
	local rootPart = GetRootPart(character)
	local humanoid = GetHumanoid(character)
	if not rootPart or not humanoid then return end
	
	-- Find target
	local targets = GetPlayersInRange(rootPart.Position + rootPart.CFrame.LookVector * 10, CONFIG.DASH_RANGE, player)
	
	if #targets > 0 then
		local target = targets[1]
		
		-- Dash to target
		local startPos = rootPart.Position
		local targetPos = target.RootPart.Position
		
		-- Launch target upward
		ApplyKnockback(target.RootPart, Vector3.new(0, 1, 0), 50)
		
		-- Deal combo damage
		task.spawn(function()
			for i = 1, CONFIG.DASH_COMBO_HITS do
				DealDamage(target.Humanoid, CONFIG.DASH_DAMAGE_PER_HIT)
				task.wait(0.1)
			end
		end)
		
		print(player.Name, "Dash Combo on", target.Player.Name)
	end
end

local function HandleUniverseReset(player)
	print("=== UNIVERSE RESET BY", player.Name, "===")
	
	-- Play audio for all players
	local AbilitiesFolder = ReplicatedStorage:WaitForChild("Abilities")
	local SFXFolder = AbilitiesFolder:FindFirstChild("SFX")
	if not SFXFolder then
		-- Create SFX folder if it doesn't exist
		SFXFolder = Instance.new("Folder")
		SFXFolder.Name = "SFX"
		SFXFolder.Parent = AbilitiesFolder
		print("✓ Created SFX folder in Abilities")
	end
	local UniverseResetSound = SFXFolder:FindFirstChild("UniverseReset")
	
	if UniverseResetSound then
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = GetCharacterFromPlayer(plr)
			local hrp = GetRootPart(char)
			if hrp then
				local sound = UniverseResetSound:Clone()
				sound.Parent = hrp
				sound:Play()
				game:GetService("Debris"):AddItem(sound, sound.TimeLength)
			end
		end
	end
	
	-- Randomize everyone's loadout
	task.spawn(function()
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = GetCharacterFromPlayer(plr)
			if char then
				-- Destroy current tools
				for _, tool in ipairs(char:GetChildren()) do
					if tool:IsA("Tool") then
						tool:Destroy()
					end
				end
				
				-- Give random weapons
				local weaponsFolder = ServerStorage:FindFirstChild("Weapons")
				if weaponsFolder then
					local allWeapons = {}
					
					-- Collect all weapons
					for _, category in ipairs(weaponsFolder:GetChildren()) do
						if category:IsA("Folder") then
							for _, subcategory in ipairs(category:GetChildren()) do
								if subcategory:IsA("Folder") then
									for _, weapon in ipairs(subcategory:GetChildren()) do
										if weapon:IsA("Tool") or weapon:IsA("Folder") then
											table.insert(allWeapons, weapon)
										end
									end
								end
							end
						end
					end
					
					-- Give 3 random weapons
					for i = 1, 3 do
						if #allWeapons > 0 then
							local randomWeapon = allWeapons[math.random(1, #allWeapons)]
							local weaponClone = randomWeapon:Clone()
							weaponClone.Parent = char
						end
					end
				end
			end
		end
	end)
	
	-- Accelerate day/night cycle
	local Lighting = game:GetService("Lighting")
	task.spawn(function()
		for i = 1, CONFIG.UNIVERSE_RESET_DURATION do
			Lighting.ClockTime = Lighting.ClockTime + 1
			task.wait(1)
		end
	end)
	
	print("Universe reset complete")
end

-- Event Handler
UseAbilityEvent.OnServerEvent:Connect(function(player, abilityName, action, data)
	if abilityName == "MadeInHeaven" then
		if action == "Activate" then
			activeAbilities[player] = {ability = "MadeInHeaven", unlockTime = tick()}
			print(player.Name, "activated Made In Heaven")
			
			-- Notify client
			UseAbilityEvent:FireClient(player, "MadeInHeaven", "Activated")
			
		elseif action == "Barrage" then
			HandleBarrage(player)
			
		elseif action == "HeavyPunch" then
			HandleHeavyPunch(player)
			
		elseif action == "HeartRip" then
			HandleHeartRip(player)
			
		elseif action == "KnifeThrow" then
			HandleKnifeThrow(player)
			
		elseif action == "ChargedKnives" then
			HandleChargedKnives(player)
			
		elseif action == "DashCombo" then
			HandleDashCombo(player)
			
		elseif action == "UniverseReset" then
			-- Check if enough time has passed (90 seconds)
			local abilityData = activeAbilities[player]
			if abilityData and (tick() - abilityData.unlockTime) >= 90 then
				HandleUniverseReset(player)
			else
				warn(player.Name, "tried to use Universe Reset too early")
			end
			
		elseif action == "BlockStart" then
			-- Store block state
			if not activeAbilities[player] then
				activeAbilities[player] = {}
			end
			activeAbilities[player].blocking = true
			activeAbilities[player].blockDamage = 0
			
		elseif action == "BlockEnd" then
			if activeAbilities[player] then
				activeAbilities[player].blocking = false
			end
		end
	end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	activeAbilities[player] = nil
end)

print("Made In Heaven Server loaded")

