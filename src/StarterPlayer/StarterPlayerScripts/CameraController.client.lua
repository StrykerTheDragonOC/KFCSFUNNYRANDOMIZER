--[[
	Camera Controller
	Handles first-person camera and mouse lock
	Ensures proper camera behavior for FPS gameplay
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for FPS System to load
repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local CameraController = {}

-- Camera state
local isFirstPerson = false
local isMouseLocked = false
local originalCameraType = camera.CameraType
local originalCameraSubject = camera.CameraSubject

function CameraController:Initialize()
	-- Set up camera for FPS gameplay
	self:SetupFPS()
	
	-- Handle character spawning
	player.CharacterAdded:Connect(function(character)
		self:OnCharacterSpawned(character)
	end)
	
	-- Handle input for mouse lock
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Left click to lock mouse (only in first-person)
			if not isMouseLocked and self:IsInFirstPersonView() then
				self:LockMouse()
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			-- Escape to unlock mouse
			if isMouseLocked then
				self:UnlockMouse()
			end
		end
	end)

	-- Monitor camera zoom to unlock mouse in third-person
	game:GetService("RunService").RenderStepped:Connect(function()
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			-- Check if camera is zoomed out (third-person)
			if (humanoid.RootPart.Position - camera.CFrame.Position).Magnitude > 2 then
				-- In third-person, unlock mouse
				if isMouseLocked then
					self:UnlockMouse()
				end
			else
				-- In first-person, lock mouse (only if player has clicked)
				-- Don't auto-lock, wait for player interaction
			end
		end
	end)

	print("CameraController initialized")
end

function CameraController:IsInFirstPersonView()
	-- Check if camera is close to character (first-person)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local distance = (player.Character.HumanoidRootPart.Position - camera.CFrame.Position).Magnitude
		return distance < 2
	end
	return false
end

function CameraController:SetupFPS()
	-- Set camera to first person
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")
	
	-- Enable mouse lock
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	
	print("FPS camera setup complete")
end

function CameraController:OnCharacterSpawned(character)
	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		-- Set camera subject to humanoid
		camera.CameraSubject = humanoid

		-- Don't auto-lock mouse - let player decide camera mode first
		-- Mouse will lock automatically when they click (if in first-person)

		print("Camera set to character:", character.Name)
	else
		warn("CameraController: Could not find Humanoid in character")
	end
end

function CameraController:LockMouse()
	if isMouseLocked then return end
	
	-- Lock mouse to center
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	isMouseLocked = true
	
	-- Hide mouse cursor
	UserInputService.MouseIconEnabled = false
	
	print("Mouse locked")
end

function CameraController:UnlockMouse()
	if not isMouseLocked then return end
	
	-- Unlock mouse
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	isMouseLocked = false
	
	-- Show mouse cursor
	UserInputService.MouseIconEnabled = true
	
	print("Mouse unlocked")
end

function CameraController:IsMouseLocked()
	return isMouseLocked
end

function CameraController:IsFirstPerson()
	return isFirstPerson
end

-- Initialize
CameraController:Initialize()

-- Make globally accessible
_G.CameraController = CameraController

return CameraController
