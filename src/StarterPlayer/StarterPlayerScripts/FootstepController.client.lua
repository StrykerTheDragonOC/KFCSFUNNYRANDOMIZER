--[[
	Footstep Controller (Client)
	Plays 3D positional footstep audio
	Enemy footsteps are audible for tactical gameplay
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local FootstepController = {}

-- Footstep sound configurations by material
local FOOTSTEP_SOUNDS = {
	[Enum.Material.Grass] = {
		SoundIds = {
			"rbxassetid://4776173570",
			"rbxassetid://4776173570",
			"rbxassetid://4776173570"
		},
		Volume = 0.3,
		PitchRange = {0.9, 1.1}
	},
	[Enum.Material.Concrete] = {
		SoundIds = {
			"rbxassetid://4776173570",
			"rbxassetid://4776173570",
			"rbxassetid://4776173570"
		},
		Volume = 0.5,
		PitchRange = {0.95, 1.05}
	},
	[Enum.Material.Metal] = {
		SoundIds = {
			"rbxassetid://4776173570",
			"rbxassetid://4776173570"
		},
		Volume = 0.6,
		PitchRange = {1.0, 1.2}
	},
	[Enum.Material.Wood] = {
		SoundIds = {
			"rbxassetid://4776173570",
			"rbxassetid://4776173570"
		},
		Volume = 0.4,
		PitchRange = {0.9, 1.0}
	},
	[Enum.Material.Water] = {
		SoundIds = {
			"rbxassetid://4776173570",
			"rbxassetid://4776173570"
		},
		Volume = 0.5,
		PitchRange = {0.8, 1.0}
	},
	-- Default for unmapped materials
	Default = {
		SoundIds = {
			"rbxassetid://4776173570"
		},
		Volume = 0.4,
		PitchRange = {0.95, 1.05}
	}
}

-- Player tracking
local trackedPlayers = {}

function FootstepController:Initialize()
	-- Setup for existing players
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			self:TrackPlayer(otherPlayer)
		end
	end

	-- Track new players
	Players.PlayerAdded:Connect(function(otherPlayer)
		if otherPlayer ~= player then
			self:TrackPlayer(otherPlayer)
		end
	end)

	-- Stop tracking when players leave
	Players.PlayerRemoving:Connect(function(otherPlayer)
		self:UntrackPlayer(otherPlayer)
	end)

	print("FootstepController initialized")
end

function FootstepController:TrackPlayer(otherPlayer)
	otherPlayer.CharacterAdded:Connect(function(character)
		self:SetupCharacterFootsteps(otherPlayer, character)
	end)

	if otherPlayer.Character then
		self:SetupCharacterFootsteps(otherPlayer, otherPlayer.Character)
	end
end

function FootstepController:SetupCharacterFootsteps(otherPlayer, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)

	if not humanoid or not rootPart then return end

	-- Create footstep sound emitter
	local footstepEmitter = Instance.new("Part")
	footstepEmitter.Name = "FootstepEmitter"
	footstepEmitter.Size = Vector3.new(0.1, 0.1, 0.1)
	footstepEmitter.Transparency = 1
	footstepEmitter.CanCollide = false
	footstepEmitter.Anchored = false
	footstepEmitter.Parent = character

	-- Weld to root part
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = footstepEmitter
	weld.Parent = footstepEmitter

	-- Track player data
	trackedPlayers[otherPlayer.UserId] = {
		Player = otherPlayer,
		Character = character,
		Humanoid = humanoid,
		RootPart = rootPart,
		Emitter = footstepEmitter,
		LastStepTime = 0,
		IsMoving = false
	}

	-- Start footstep loop
	self:StartFootstepLoop(otherPlayer.UserId)

	print("Tracking footsteps for:", otherPlayer.Name)
end

function FootstepController:StartFootstepLoop(userId)
	local playerData = trackedPlayers[userId]
	if not playerData then return end

	spawn(function()
		while playerData.Character and playerData.Character.Parent do
			local humanoid = playerData.Humanoid
			local rootPart = playerData.RootPart

			if humanoid and rootPart then
				-- Check if player is moving
				local moveVector = humanoid.MoveVector
				local isMoving = moveVector.Magnitude > 0.1
				local speed = rootPart.AssemblyLinearVelocity.Magnitude

				-- Check if on ground
				local rayResult = Workspace:Raycast(
					rootPart.Position,
					Vector3.new(0, -5, 0),
					RaycastParams.new()
				)

				local isOnGround = rayResult ~= nil

				if isMoving and isOnGround and speed > 1 then
					local currentTime = tick()

					-- Calculate step interval based on speed
					local stepInterval = 0.5 / math.clamp(speed / 16, 0.5, 2)

					if currentTime - playerData.LastStepTime >= stepInterval then
						self:PlayFootstep(playerData, rayResult)
						playerData.LastStepTime = currentTime
					end
				end
			end

			task.wait(0.1)
		end

		-- Cleanup
		trackedPlayers[userId] = nil
	end)
end

function FootstepController:PlayFootstep(playerData, rayResult)
	if not playerData.Emitter or not playerData.Emitter.Parent then return end

	-- Determine material
	local material = rayResult and rayResult.Material or Enum.Material.Plastic
	local soundConfig = FOOTSTEP_SOUNDS[material] or FOOTSTEP_SOUNDS.Default

	-- Pick random sound from material's sound set
	local soundId = soundConfig.SoundIds[math.random(1, #soundConfig.SoundIds)]

	-- Create sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = soundConfig.Volume
	sound.PlaybackSpeed = math.random(soundConfig.PitchRange[1] * 100, soundConfig.PitchRange[2] * 100) / 100
	sound.Parent = playerData.Emitter

	-- Make it 3D positional
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 50

	sound:Play()

	-- Cleanup after playing
	game:GetService("Debris"):AddItem(sound, 2)

	-- Check if enemy (for tactical audio cue)
	if player.Team and playerData.Player.Team and player.Team ~= playerData.Player.Team then
		-- Enemy footstep - slightly louder
		sound.Volume = sound.Volume * 1.2
	end
end

function FootstepController:UntrackPlayer(otherPlayer)
	trackedPlayers[otherPlayer.UserId] = nil
end

-- Initialize
FootstepController:Initialize()

return FootstepController
