--[[
	Sound System Module
	Handles all 3D positional audio
	Material-based impact sounds, bullet whizz, etc.
]]

local SoundSystem = {}

-- Material-based impact sounds
local IMPACT_SOUNDS = {
	[Enum.Material.Concrete] = {
		Sounds = {"rbxassetid://4776173570", "rbxassetid://4776173570"},
		Volume = 0.5,
		PitchRange = {0.9, 1.1}
	},
	[Enum.Material.Metal] = {
		Sounds = {"rbxassetid://4776173570", "rbxassetid://4776173570"},
		Volume = 0.6,
		PitchRange = {1.0, 1.2}
	},
	[Enum.Material.Wood] = {
		Sounds = {"rbxassetid://4776173570", "rbxassetid://4776173570"},
		Volume = 0.4,
		PitchRange = {0.8, 1.0}
	},
	[Enum.Material.Glass] = {
		Sounds = {"rbxassetid://4776173570"},
		Volume = 0.7,
		PitchRange = {1.1, 1.3}
	},
	[Enum.Material.Grass] = {
		Sounds = {"rbxassetid://4776173570"},
		Volume = 0.3,
		PitchRange = {0.8, 1.0}
	},
	[Enum.Material.Water] = {
		Sounds = {"rbxassetid://4776173570"},
		Volume = 0.5,
		PitchRange = {0.7, 0.9}
	},
	[Enum.Material.Sand] = {
		Sounds = {"rbxassetid://4776173570"},
		Volume = 0.3,
		PitchRange = {0.8, 1.0}
	},
	Default = {
		Sounds = {"rbxassetid://4776173570"},
		Volume = 0.4,
		PitchRange = {0.95, 1.05}
	}
}

-- Bullet whizz sounds
local WHIZZ_SOUNDS = {
	"rbxassetid://4776173570",
	"rbxassetid://4776173570",
	"rbxassetid://4776173570"
}

-- Suppressed weapon detection ranges (for radar)
SoundSystem.SUPPRESSOR_RANGES = {
	None = 200, -- Full detection range
	Light = 60, -- Light suppressor
	Heavy = 30  -- Heavy suppressor
}

function SoundSystem:PlayImpactSound(position, material, volume)
	volume = volume or 1.0

	-- Get sound config for material
	local soundConfig = IMPACT_SOUNDS[material] or IMPACT_SOUNDS.Default

	-- Pick random sound
	local soundId = soundConfig.Sounds[math.random(1, #soundConfig.Sounds)]

	-- Create sound at impact position
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = soundConfig.Volume * volume
	sound.PlaybackSpeed = math.random(soundConfig.PitchRange[1] * 100, soundConfig.PitchRange[2] * 100) / 100

	-- Create attachment at position
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain

	sound.Parent = attachment

	-- 3D positional settings
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 20
	sound.RollOffMaxDistance = 150

	sound:Play()

	-- Cleanup
	game:GetService("Debris"):AddItem(attachment, 2)
end

function SoundSystem:PlayBulletWhizz(position, direction, speed)
	-- Only play if bullet passes near player
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer

	if not localPlayer or not localPlayer.Character then return end

	local rootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Check distance to player
	local distanceToPlayer = (position - rootPart.Position).Magnitude

	-- Only play whizz if bullet passes within 10 studs
	if distanceToPlayer > 10 then return end

	-- Pick random whizz sound
	local soundId = WHIZZ_SOUNDS[math.random(1, #WHIZZ_SOUNDS)]

	-- Create sound at bullet position
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.4
	sound.PlaybackSpeed = math.random(95, 105) / 100

	-- Create attachment
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain

	sound.Parent = attachment

	-- 3D positional
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 5
	sound.RollOffMaxDistance = 30

	sound:Play()

	-- Cleanup
	game:GetService("Debris"):AddItem(attachment, 1)
end

function SoundSystem:PlayWeaponFire(position, weaponType, isSuppressed)
	-- Get appropriate fire sound based on weapon type
	local soundId = "rbxassetid://4776173570" -- Placeholder

	-- Adjust volume based on suppressor
	local volume = isSuppressed and 0.3 or 0.7

	-- Create sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = math.random(98, 102) / 100

	-- Create attachment
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain

	sound.Parent = attachment

	-- 3D positional - suppressors have reduced range
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = isSuppressed and 20 or 50
	sound.RollOffMaxDistance = isSuppressed and 100 or 300

	sound:Play()

	-- Cleanup
	game:GetService("Debris"):AddItem(attachment, 2)
end

function SoundSystem:PlayExplosion(position, radius, intensity)
	intensity = intensity or 1.0

	-- Explosion sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://4776173570" -- Placeholder
	sound.Volume = 0.8 * intensity
	sound.PlaybackSpeed = math.random(90, 110) / 100

	-- Create attachment
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain

	sound.Parent = attachment

	-- Large radius for explosions
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = radius
	sound.RollOffMaxDistance = radius * 5

	sound:Play()

	-- Cleanup
	game:GetService("Debris"):AddItem(attachment, 3)
end

function SoundSystem:PlayReload(character, weaponType)
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Reload sounds are quieter and local
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://4776173570" -- Placeholder
	sound.Volume = 0.3
	sound.PlaybackSpeed = 1.0
	sound.Parent = rootPart

	-- Limited range
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 30

	sound:Play()

	game:GetService("Debris"):AddItem(sound, 3)
end

function SoundSystem:GetSuppressionRange(suppressorType)
	return self.SUPPRESSOR_RANGES[suppressorType] or self.SUPPRESSOR_RANGES.None
end

return SoundSystem
