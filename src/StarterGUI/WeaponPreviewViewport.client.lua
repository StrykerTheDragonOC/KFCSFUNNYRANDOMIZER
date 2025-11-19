--[[
	Weapon Preview Viewport System
	Creates rotating 3D weapon previews in Shop and Loadout menus
	Handles viewport cameras and model loading
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WeaponPreviewViewport = {}

-- Active viewport previews
local activeViewports = {}

function WeaponPreviewViewport:CreateWeaponPreview(viewportFrame, weaponName)
	if not viewportFrame or not viewportFrame:IsA("ViewportFrame") then
		warn("Invalid ViewportFrame provided")
		return nil
	end

	-- Find weapon model
	local weaponModel = self:FindWeaponModel(weaponName)
	if not weaponModel then
		-- Silently fail for missing models (this is common during development)
		return nil
	end

	-- Clone the weapon model
	local previewModel = weaponModel:Clone()

	-- Prepare model for viewport
	for _, part in ipairs(previewModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- Create or find camera
	local camera = viewportFrame:FindFirstChildOfClass("Camera")
	if not camera then
		camera = Instance.new("Camera")
		camera.Name = "WeaponPreviewCamera"
		camera.Parent = viewportFrame
	end

	-- Set the camera
	viewportFrame.CurrentCamera = camera

	-- Parent model to viewport
	previewModel.Parent = viewportFrame

	-- Position camera to frame weapon
	self:FrameWeapon(camera, previewModel)

	-- Store viewport data
	local viewportData = {
		ViewportFrame = viewportFrame,
		Camera = camera,
		Model = previewModel,
		WeaponName = weaponName,
		RotationSpeed = 0.5,
		IsRotating = true
	}

	table.insert(activeViewports, viewportData)

	-- Start rotation
	self:StartRotation(viewportData)

	print("Created weapon preview for:", weaponName)
	return viewportData
end

function WeaponPreviewViewport:FindWeaponModel(weaponName)
	-- Search in WeaponModels folder
	local weaponModelsFolder = ReplicatedStorage.FPSSystem:FindFirstChild("WeaponModels")
	if not weaponModelsFolder then
		warn("WeaponModels folder not found")
		return nil
	end

	-- Search all categories
	for _, category in ipairs(weaponModelsFolder:GetChildren()) do
		if category:IsA("Folder") then
			for _, subcategory in ipairs(category:GetChildren()) do
				if subcategory:IsA("Folder") then
					local model = subcategory:FindFirstChild(weaponName)
					if model then
						return model
					end
				end
			end
		end
	end

	-- Fallback: search in ViewModels
	local viewmodelsFolder = ReplicatedStorage.FPSSystem:FindFirstChild("ViewModels")
	if viewmodelsFolder then
		for _, category in ipairs(viewmodelsFolder:GetChildren()) do
			if category:IsA("Folder") then
				for _, subcategory in ipairs(category:GetChildren()) do
					if subcategory:IsA("Folder") then
						local weaponFolder = subcategory:FindFirstChild(weaponName)
						if weaponFolder and weaponFolder:IsA("Folder") then
							-- Return the actual weapon model inside
							for _, child in ipairs(weaponFolder:GetChildren()) do
								if child:IsA("Model") then
									return child
								end
							end
						end
					end
				end
			end
		end
	end

	return nil
end

function WeaponPreviewViewport:FrameWeapon(camera, weaponModel)
	-- Get weapon bounding box - handle both Model and Folder
	local cf, size
	if weaponModel:IsA("Model") then
		cf, size = weaponModel:GetBoundingBox()
	elseif weaponModel:IsA("Folder") then
		-- For folders, calculate bounding box from all parts
		local parts = {}
		for _, child in pairs(weaponModel:GetDescendants()) do
			if child:IsA("BasePart") then
				table.insert(parts, child)
			end
		end
		if #parts > 0 then
			cf, size = workspace:GetBoundingBox(parts)
		else
			-- Fallback if no parts found
			cf = weaponModel:GetPivot()
			size = Vector3.new(4, 4, 4)
		end
	else
		-- Fallback for other types
		cf = weaponModel:GetPivot()
		size = Vector3.new(4, 4, 4)
	end

	-- Calculate distance based on size
	local maxDimension = math.max(size.X, size.Y, size.Z)
	local distance = maxDimension * 2.5

	-- Position camera at an angle
	local cameraPosition = cf.Position + Vector3.new(distance * 0.7, distance * 0.3, distance)
	camera.CFrame = CFrame.new(cameraPosition, cf.Position)
	camera.FieldOfView = 50

	print("Camera positioned for weapon at distance:", distance)
end

function WeaponPreviewViewport:StartRotation(viewportData)
	-- Create rotation connection
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not viewportData.IsRotating or not viewportData.Model or not viewportData.Model.Parent then
			connection:Disconnect()
			return
		end

		-- Rotate model
		if viewportData.Model.PrimaryPart then
			viewportData.Model.PrimaryPart.CFrame = viewportData.Model.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(viewportData.RotationSpeed * 60 * dt), 0)
		else
			-- Rotate all parts if no primary part
			for _, part in ipairs(viewportData.Model:GetChildren()) do
				if part:IsA("BasePart") then
					part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(viewportData.RotationSpeed * 60 * dt), 0)
					break -- Only rotate first part
				end
			end
		end
	end)

	viewportData.RotationConnection = connection
end

function WeaponPreviewViewport:StopRotation(viewportData)
	if viewportData.RotationConnection then
		viewportData.RotationConnection:Disconnect()
		viewportData.RotationConnection = nil
	end
	viewportData.IsRotating = false
end

function WeaponPreviewViewport:ClearViewport(viewportFrame)
	-- Find and remove viewport data
	for i, viewportData in ipairs(activeViewports) do
		if viewportData.ViewportFrame == viewportFrame then
			self:StopRotation(viewportData)

			if viewportData.Model then
				viewportData.Model:Destroy()
			end

			table.remove(activeViewports, i)
			print("Cleared viewport")
			return
		end
	end
end

function WeaponPreviewViewport:ClearAllViewports()
	for _, viewportData in ipairs(activeViewports) do
		self:StopRotation(viewportData)
		if viewportData.Model then
			viewportData.Model:Destroy()
		end
	end
	table.clear(activeViewports)
	print("Cleared all viewports")
end

function WeaponPreviewViewport:SetRotationSpeed(viewportFrame, speed)
	for _, viewportData in ipairs(activeViewports) do
		if viewportData.ViewportFrame == viewportFrame then
			viewportData.RotationSpeed = speed
			return
		end
	end
end

function WeaponPreviewViewport:PauseRotation(viewportFrame)
	for _, viewportData in ipairs(activeViewports) do
		if viewportData.ViewportFrame == viewportFrame then
			viewportData.IsRotating = false
			return
		end
	end
end

function WeaponPreviewViewport:ResumeRotation(viewportFrame)
	for _, viewportData in ipairs(activeViewports) do
		if viewportData.ViewportFrame == viewportFrame then
			if not viewportData.IsRotating then
				viewportData.IsRotating = true
				self:StartRotation(viewportData)
			end
			return
		end
	end
end

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(playerWhoLeft)
	if playerWhoLeft == player then
		WeaponPreviewViewport:ClearAllViewports()
	end
end)

-- Make globally accessible
_G.WeaponPreviewViewport = WeaponPreviewViewport

print("WeaponPreviewViewport system loaded")

return WeaponPreviewViewport
