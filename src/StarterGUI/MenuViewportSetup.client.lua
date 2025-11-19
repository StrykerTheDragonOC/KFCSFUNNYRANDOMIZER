--[[
	MenuViewportSetup - Handles ViewportFrame NPC and Camera Setup
	Separated from menu logic to keep it simple
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for menu to load
local mainMenu = playerGui:WaitForChild("FPSMainMenu", 10)
if not mainMenu then
	warn("FPSMainMenu not found - cannot setup viewport")
	return
end

-- Find CharacterViewport
local function findViewportFrame()
	-- Search in MainContainer > ContentArea > DeploySection
	local mainContainer = mainMenu:FindFirstChild("MainContainer")
	if not mainContainer then
		warn("MainContainer not found")
		return nil
	end

	local contentArea = mainContainer:FindFirstChild("ContentArea")
	if not contentArea then
		warn("ContentArea not found")
		return nil
	end

	local deploySection = contentArea:FindFirstChild("DeploySection")
	if not deploySection then
		warn("DeploySection not found")
		return nil
	end

	-- Look for CharacterViewport (new name)
	local viewport = deploySection:FindFirstChild("CharacterViewport")
	if not viewport then
		warn("CharacterViewport not found in DeploySection")
		return nil
	end

	return viewport
end

local viewportFrame = findViewportFrame()
if not viewportFrame then
	warn("Could not find CharacterViewport - menu character preview will not display")
	return
end

print("✓ Found ViewportFrame at:", viewportFrame:GetFullName())

-- Setup camera (CRITICAL: Must be done in specific order)
local camera = viewportFrame:FindFirstChildOfClass("Camera")
if not camera then
	camera = Instance.new("Camera")
	camera.Name = "ViewportCamera"
	camera.Parent = viewportFrame
	print("✓ Created new Camera for ViewportFrame")
else
	print("✓ Found existing Camera in ViewportFrame")
end

-- CRITICAL: Set the CurrentCamera (must be done AFTER camera is parented)
viewportFrame.CurrentCamera = camera
print("✓ Set ViewportFrame.CurrentCamera to:", camera:GetFullName())

-- Verify the camera is set
task.wait(0.1)
if viewportFrame.CurrentCamera ~= camera then
	warn("⚠ ViewportFrame.CurrentCamera didn't persist, retrying...")
	viewportFrame.CurrentCamera = camera
	task.wait(0.1)
	if viewportFrame.CurrentCamera ~= camera then
		warn("❌ ViewportFrame.CurrentCamera failed to set after retry")
	else
		print("✓ ViewportFrame.CurrentCamera set on retry")
	end
end

-- Find NPC model (look for any Model with a Humanoid in the viewport)
local npcModel = nil
local desk = nil
local worldModel = nil

for _, child in ipairs(viewportFrame:GetChildren()) do
	if child:IsA("WorldModel") then
		worldModel = child
		-- Check if character parts are directly in WorldModel (R6/R15 rig)
		if child:FindFirstChild("HumanoidRootPart") and child:FindFirstChildOfClass("Humanoid") then
			npcModel = child
			print("✓ Found NPC parts directly in WorldModel")
		else
			-- Look for a Model inside WorldModel
			local characterModel = child:FindFirstChildOfClass("Model")
			if characterModel and characterModel:FindFirstChildOfClass("Humanoid") then
				npcModel = characterModel
				print("✓ Found NPC model inside WorldModel:", characterModel.Name)
			end
		end
	elseif child:IsA("Model") then
		if child:FindFirstChildOfClass("Humanoid") then
			npcModel = child
			print("✓ Found NPC model:", child.Name)
		elseif child.Name:lower():find("desk") or child.Name:lower():find("table") or child.Name:lower():find("prop") then
			desk = child
			print("✓ Found desk/prop:", child.Name)
		end
	end
end

if not npcModel then
	warn("⚠ No NPC model found in CharacterViewport")
	warn("💡 TIP: Add a character model with a Humanoid to StarterGui > FPSMainMenu > ... > CharacterViewport")
else
	-- Configure NPC (anchor all parts)
	for _, part in ipairs(npcModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- Try to play idle animation
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Ensure the NPC model has a properly set HumanoidRootPart
		local rootPart = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Torso") or npcModel:FindFirstChild("UpperTorso")
		if rootPart and not npcModel.PrimaryPart then
			npcModel.PrimaryPart = rootPart
			print("✓ Set NPC PrimaryPart to:", rootPart.Name)
		end

		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
			print("✓ Created Animator for NPC")
		end

		-- FIXED: Wait longer for animator to fully initialize
		task.wait(0.5)

		-- Function to attempt playing animation with retry
		local function tryPlayAnimation(animation, animName)
			local maxRetries = 3
			local retryDelay = 0.2

			for attempt = 1, maxRetries do
				local success, track = pcall(function()
					return animator:LoadAnimation(animation)
				end)

				if success and track then
					-- FIXED: Wait for track to load before playing
					task.wait(0.1)

					track.Looped = true
					track.Priority = Enum.AnimationPriority.Idle

					-- Try to play
					local playSuccess = pcall(function()
						track:Play()
					end)

					if playSuccess then
						print("✓ Playing NPC idle animation:", animName, "- AnimationId:", animation.AnimationId)
						return true
					else
						warn("⚠ Failed to play animation on attempt", attempt)
					end
				else
					warn("⚠ Failed to load animation on attempt", attempt, "- Error:", track)
				end

				if attempt < maxRetries then
					task.wait(retryDelay)
				end
			end

			return false
		end

		-- Look for idle animation (can be in the NPC model or humanoid)
		local idleAnim = npcModel:FindFirstChild("Idle", true) or npcModel:FindFirstChild("IdleAnimation", true)
		local animationPlayed = false

		if idleAnim and idleAnim:IsA("Animation") then
			animationPlayed = tryPlayAnimation(idleAnim, idleAnim.Name)
		end

		if not animationPlayed then
			-- Try default Roblox idle animation as fallback
			local defaultIdleAnim = Instance.new("Animation")
			-- Detect if R6 or R15
			local isR15 = npcModel:FindFirstChild("UpperTorso") ~= nil
			if isR15 then
				defaultIdleAnim.AnimationId = "rbxassetid://507766388" -- Default R15 idle
			else
				defaultIdleAnim.AnimationId = "rbxassetid://180435571" -- Default R6 idle
			end

			animationPlayed = tryPlayAnimation(defaultIdleAnim, "DefaultIdle")

			if animationPlayed then
				print("✓ Playing default idle animation (no custom animation found)")
			else
				warn("⚠ No idle animation found and failed to load default animation after multiple retries")
			end
		end
	end
end

-- Configure desk/props
if desk then
	for _, part in ipairs(desk:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			-- Ensure visible
			if part.Transparency >= 1 then
				part.Transparency = 0
			end
		end
	end
	print("✓ Configured desk/props:", desk.Name)
end

-- Position camera to view NPC and desk
local function positionCamera()
	if npcModel then
		local rootPart = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Torso") or npcModel:FindFirstChild("Head")
		if rootPart then
			-- Calculate bounding box
			local cf, size = npcModel:GetBoundingBox()

			-- If desk exists, include it in framing
			if desk then
				local deskCf, deskSize = desk:GetBoundingBox()
				-- Calculate combined bounds
				local minX = math.min(cf.Position.X - size.X/2, deskCf.Position.X - deskSize.X/2)
				local maxX = math.max(cf.Position.X + size.X/2, deskCf.Position.X + deskSize.X/2)
				local minY = math.min(cf.Position.Y - size.Y/2, deskCf.Position.Y - deskSize.Y/2)
				local maxY = math.max(cf.Position.Y + size.Y/2, deskCf.Position.Y + deskSize.Y/2)
				local minZ = math.min(cf.Position.Z - size.Z/2, deskCf.Position.Z - deskSize.Z/2)
				local maxZ = math.max(cf.Position.Z + size.Z/2, deskCf.Position.Z + deskSize.Z/2)

				local center = Vector3.new((minX + maxX)/2, (minY + maxY)/2, (minZ + maxZ)/2)
				local extents = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
				local dist = math.max(extents.X, extents.Y, extents.Z) * 1.5

				camera.CFrame = CFrame.new(center + Vector3.new(0, extents.Y * 0.2, dist), center)
			else
				-- Just frame NPC (nice angle from front-right)
				local cameraOffset = Vector3.new(2, 1, 4)
				local cameraPosition = rootPart.Position + cameraOffset
				local lookAtPosition = rootPart.Position + Vector3.new(0, 1, 0)

				camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)

				-- CRITICAL: Rotate NPC to face the camera for better viewing angle
				-- Calculate direction from NPC to camera (on XZ plane only)
				local directionToCamera = (cameraPosition - rootPart.Position) * Vector3.new(1, 0, 1)
				if directionToCamera.Magnitude > 0 then
					-- Make NPC face TOWARD the camera (so we see their front)
					local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + directionToCamera)
					rootPart.CFrame = targetCFrame
					print("✓ NPC rotated to face camera (showing front)")
				end
			end

			camera.FieldOfView = 50
			print("✓ Camera positioned at:", tostring(camera.CFrame.Position))
		else
			warn("⚠ No root part found in NPC model")
		end
	elseif desk then
		-- Only desk, frame that
		local cf, size = desk:GetBoundingBox()
		local dist = math.max(size.X, size.Y, size.Z) * 1.5
		camera.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y * 0.3, dist), cf.Position)
		camera.FieldOfView = 70
		print("✓ Camera positioned for desk at:", camera.CFrame.Position)
	else
		-- No models found - set a default camera position looking at viewport center
		camera.CFrame = CFrame.new(0, 2, 5) * CFrame.Angles(math.rad(-15), 0, 0)
		camera.FieldOfView = 70
		warn("⚠ No NPC or desk found - using default camera position")
		warn("💡 TIP: Add a character model (R15/R6) with a Humanoid to the CharacterViewport")
	end
end

positionCamera()

-- Re-verify camera is still set after positioning
task.wait(0.1)
if viewportFrame.CurrentCamera ~= camera then
	warn("⚠ Camera was unset during positioning, re-setting...")
	viewportFrame.CurrentCamera = camera
end

-- Keep NPC and desk visible (prevent deletion)
if npcModel and npcModel ~= worldModel then
	-- Only re-parent if it's a Model, not the WorldModel itself
	npcModel.Parent = viewportFrame
end
if desk then
	desk.Parent = viewportFrame
end

print("✅ Menu viewport setup complete!")
if npcModel then
	print("✓ NPC character ready with animations")
else
	print("⚠ No NPC found - add a character model to CharacterViewport to see it in menu")
end


