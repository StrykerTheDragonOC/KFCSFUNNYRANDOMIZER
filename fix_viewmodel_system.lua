--[[
	Fix Viewmodel System
	This script fixes the viewmodel system to work properly
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for FPSSystem
local FPSSystem = ReplicatedStorage:WaitForChild("FPSSystem")
local ViewModels = FPSSystem:WaitForChild("ViewModels")

print("🔧 Fixing Viewmodel System...")

-- 1. Fix folder name typo
local PrimaryFolder = ViewModels:FindFirstChild("Primary")
if PrimaryFolder then
	local AssaultRiflesFolder = PrimaryFolder:FindFirstChild("AssaultRIfles") -- Note the typo
	if AssaultRiflesFolder then
		-- Rename the folder to fix the typo
		AssaultRiflesFolder.Name = "AssaultRifles"
		print("✓ Fixed typo: AssaultRIfles -> AssaultRifles")
	end
end

-- 2. Create proper viewmodel structure for G36
local function createG36ViewModel()
	local PrimaryFolder = ViewModels:FindFirstChild("Primary")
	if not PrimaryFolder then
		PrimaryFolder = Instance.new("Folder")
		PrimaryFolder.Name = "Primary"
		PrimaryFolder.Parent = ViewModels
	end
	
	local AssaultRiflesFolder = PrimaryFolder:FindFirstChild("AssaultRifles")
	if not AssaultRiflesFolder then
		AssaultRiflesFolder = Instance.new("Folder")
		AssaultRiflesFolder.Name = "AssaultRifles"
		AssaultRiflesFolder.Parent = PrimaryFolder
	end
	
	local G36Folder = AssaultRiflesFolder:FindFirstChild("G36")
	if not G36Folder then
		G36Folder = Instance.new("Folder")
		G36Folder.Name = "G36"
		G36Folder.Parent = AssaultRiflesFolder
	end
	
	-- Create the actual viewmodel model
	local G36Model = Instance.new("Model")
	G36Model.Name = "G36"
	
	-- Create handle (main weapon part)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 0.2, 4)
	handle.Material = Enum.Material.Metal
	handle.Color = Color3.fromRGB(100, 100, 100)
	handle.CanCollide = false
	handle.Massless = true
	handle.CastShadow = false
	handle.Parent = G36Model
	
	-- Create barrel
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.1, 0.1, 3)
	barrel.Material = Enum.Material.Metal
	barrel.Color = Color3.fromRGB(80, 80, 80)
	barrel.CanCollide = false
	barrel.Massless = true
	barrel.CastShadow = false
	barrel.CFrame = handle.CFrame * CFrame.new(0, 0, -1.5)
	barrel.Parent = G36Model
	
	-- Create stock
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Size = Vector3.new(0.8, 0.3, 1.5)
	stock.Material = Enum.Material.Wood
	stock.Color = Color3.fromRGB(139, 69, 19)
	stock.CanCollide = false
	stock.Massless = true
	stock.CastShadow = false
	stock.CFrame = handle.CFrame * CFrame.new(0, 0, 1.2)
	stock.Parent = G36Model
	
	-- Create CameraPart (CRITICAL for viewmodel positioning)
	local cameraPart = Instance.new("Part")
	cameraPart.Name = "CameraPart"
	cameraPart.Size = Vector3.new(0.2, 0.2, 0.2)
	cameraPart.Transparency = 1
	cameraPart.CanCollide = false
	cameraPart.Massless = true
	cameraPart.CastShadow = false
	cameraPart.CFrame = handle.CFrame * CFrame.new(0.5, -0.3, -0.5)
	cameraPart.Parent = G36Model
	
	-- Weld all parts together
	local function weldParts(part1, part2)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part1
		weld.Part1 = part2
		weld.Parent = part1
	end
	
	weldParts(cameraPart, handle)
	weldParts(handle, barrel)
	weldParts(handle, stock)
	
	-- Set CameraPart as PrimaryPart
	G36Model.PrimaryPart = cameraPart
	
	-- Clone the model to the folder
	local G36Clone = G36Model:Clone()
	G36Clone.Parent = G36Folder
	
	print("✓ Created G36 viewmodel with proper structure")
end

-- 3. Create M9 viewmodel
local function createM9ViewModel()
	local SecondaryFolder = ViewModels:FindFirstChild("Secondary")
	if not SecondaryFolder then
		SecondaryFolder = Instance.new("Folder")
		SecondaryFolder.Name = "Secondary"
		SecondaryFolder.Parent = ViewModels
	end
	
	local PistolsFolder = SecondaryFolder:FindFirstChild("Pistols")
	if not PistolsFolder then
		PistolsFolder = Instance.new("Folder")
		PistolsFolder.Name = "Pistols"
		PistolsFolder.Parent = SecondaryFolder
	end
	
	local M9Folder = PistolsFolder:FindFirstChild("M9")
	if not M9Folder then
		M9Folder = Instance.new("Folder")
		M9Folder.Name = "M9"
		M9Folder.Parent = PistolsFolder
	end
	
	-- Create the actual viewmodel model
	local M9Model = Instance.new("Model")
	M9Model.Name = "M9"
	
	-- Create handle (main weapon part)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 0.1, 1.5)
	handle.Material = Enum.Material.Metal
	handle.Color = Color3.fromRGB(100, 100, 100)
	handle.CanCollide = false
	handle.Massless = true
	handle.CastShadow = false
	handle.Parent = M9Model
	
	-- Create barrel
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.05, 0.05, 1)
	barrel.Material = Enum.Material.Metal
	barrel.Color = Color3.fromRGB(80, 80, 80)
	barrel.CanCollide = false
	barrel.Massless = true
	barrel.CastShadow = false
	barrel.CFrame = handle.CFrame * CFrame.new(0, 0, -0.5)
	barrel.Parent = M9Model
	
	-- Create grip
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Size = Vector3.new(0.2, 0.3, 0.8)
	grip.Material = Enum.Material.Plastic
	grip.Color = Color3.fromRGB(50, 50, 50)
	grip.CanCollide = false
	grip.Massless = true
	grip.CastShadow = false
	grip.CFrame = handle.CFrame * CFrame.new(0, -0.1, 0.2)
	grip.Parent = M9Model
	
	-- Create CameraPart (CRITICAL for viewmodel positioning)
	local cameraPart = Instance.new("Part")
	cameraPart.Name = "CameraPart"
	cameraPart.Size = Vector3.new(0.2, 0.2, 0.2)
	cameraPart.Transparency = 1
	cameraPart.CanCollide = false
	cameraPart.Massless = true
	cameraPart.CastShadow = false
	cameraPart.CFrame = handle.CFrame * CFrame.new(0.3, -0.3, -0.8)
	cameraPart.Parent = M9Model
	
	-- Weld all parts together
	local function weldParts(part1, part2)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part1
		weld.Part1 = part2
		weld.Parent = part1
	end
	
	weldParts(cameraPart, handle)
	weldParts(handle, barrel)
	weldParts(handle, grip)
	
	-- Set CameraPart as PrimaryPart
	M9Model.PrimaryPart = cameraPart
	
	-- Clone the model to the folder
	local M9Clone = M9Model:Clone()
	M9Clone.Parent = M9Folder
	
	print("✓ Created M9 viewmodel with proper structure")
end

-- 4. Create PocketKnife viewmodel
local function createPocketKnifeViewModel()
	local MeleeFolder = ViewModels:FindFirstChild("Melee")
	if not MeleeFolder then
		MeleeFolder = Instance.new("Folder")
		MeleeFolder.Name = "Melee"
		MeleeFolder.Parent = ViewModels
	end
	
	local OneHandedBladesFolder = MeleeFolder:FindFirstChild("OneHandedBlades")
	if not OneHandedBladesFolder then
		OneHandedBladesFolder = Instance.new("Folder")
		OneHandedBladesFolder.Name = "OneHandedBlades"
		OneHandedBladesFolder.Parent = MeleeFolder
	end
	
	local PocketKnifeFolder = OneHandedBladesFolder:FindFirstChild("PocketKnife")
	if not PocketKnifeFolder then
		PocketKnifeFolder = Instance.new("Folder")
		PocketKnifeFolder.Name = "PocketKnife"
		PocketKnifeFolder.Parent = OneHandedBladesFolder
	end
	
	-- Create the actual viewmodel model
	local PocketKnifeModel = Instance.new("Model")
	PocketKnifeModel.Name = "PocketKnife"
	
	-- Create handle (main weapon part)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.1, 0.1, 0.8)
	handle.Material = Enum.Material.Plastic
	handle.Color = Color3.fromRGB(139, 69, 19)
	handle.CanCollide = false
	handle.Massless = true
	handle.CastShadow = false
	handle.Parent = PocketKnifeModel
	
	-- Create blade
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.05, 0.05, 0.6)
	blade.Material = Enum.Material.Metal
	blade.Color = Color3.fromRGB(200, 200, 200)
	blade.CanCollide = false
	blade.Massless = true
	blade.CastShadow = false
	blade.CFrame = handle.CFrame * CFrame.new(0, 0, -0.3)
	blade.Parent = PocketKnifeModel
	
	-- Create CameraPart (CRITICAL for viewmodel positioning)
	local cameraPart = Instance.new("Part")
	cameraPart.Name = "CameraPart"
	cameraPart.Size = Vector3.new(0.2, 0.2, 0.2)
	cameraPart.Transparency = 1
	cameraPart.CanCollide = false
	cameraPart.Massless = true
	cameraPart.CastShadow = false
	cameraPart.CFrame = handle.CFrame * CFrame.new(0.2, -0.4, -0.6)
	cameraPart.Parent = PocketKnifeModel
	
	-- Weld all parts together
	local function weldParts(part1, part2)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part1
		weld.Part1 = part2
		weld.Parent = part1
	end
	
	weldParts(cameraPart, handle)
	weldParts(handle, blade)
	
	-- Set CameraPart as PrimaryPart
	PocketKnifeModel.PrimaryPart = cameraPart
	
	-- Clone the model to the folder
	local PocketKnifeClone = PocketKnifeModel:Clone()
	PocketKnifeClone.Parent = PocketKnifeFolder
	
	print("✓ Created PocketKnife viewmodel with proper structure")
end

-- 5. Create M67 Grenade viewmodel
local function createM67ViewModel()
	local GrenadeFolder = ViewModels:FindFirstChild("Grenade")
	if not GrenadeFolder then
		GrenadeFolder = Instance.new("Folder")
		GrenadeFolder.Name = "Grenade"
		GrenadeFolder.Parent = ViewModels
	end
	
	local FragFolder = GrenadeFolder:FindFirstChild("Frag")
	if not FragFolder then
		FragFolder = Instance.new("Folder")
		FragFolder.Name = "Frag"
		FragFolder.Parent = GrenadeFolder
	end
	
	local M67Folder = FragFolder:FindFirstChild("M67")
	if not M67Folder then
		M67Folder = Instance.new("Folder")
		M67Folder.Name = "M67"
		M67Folder.Parent = FragFolder
	end
	
	-- Create the actual viewmodel model
	local M67Model = Instance.new("Model")
	M67Model.Name = "M67"
	
	-- Create main body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(0.4, 0.4, 0.4)
	body.Shape = Enum.PartType.Ball
	body.Material = Enum.Material.Metal
	body.Color = Color3.fromRGB(100, 100, 100)
	body.CanCollide = false
	body.Massless = true
	body.CastShadow = false
	body.Parent = M67Model
	
	-- Create CameraPart (CRITICAL for viewmodel positioning)
	local cameraPart = Instance.new("Part")
	cameraPart.Name = "CameraPart"
	cameraPart.Size = Vector3.new(0.2, 0.2, 0.2)
	cameraPart.Transparency = 1
	cameraPart.CanCollide = false
	cameraPart.Massless = true
	cameraPart.CastShadow = false
	cameraPart.CFrame = body.CFrame * CFrame.new(0.4, -0.2, -0.7)
	cameraPart.Parent = M67Model
	
	-- Weld CameraPart to body
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = cameraPart
	weld.Part1 = body
	weld.Parent = cameraPart
	
	-- Set CameraPart as PrimaryPart
	M67Model.PrimaryPart = cameraPart
	
	-- Clone the model to the folder
	local M67Clone = M67Model:Clone()
	M67Clone.Parent = M67Folder
	
	print("✓ Created M67 viewmodel with proper structure")
end

-- Run all creation functions
createG36ViewModel()
createM9ViewModel()
createPocketKnifeViewModel()
createM67ViewModel()

print("\n✅ Viewmodel System Fixed!")
print("📊 Summary:")
print("  - Fixed folder name typo (AssaultRIfles -> AssaultRifles)")
print("  - Created G36 viewmodel with proper CameraPart")
print("  - Created M9 viewmodel with proper CameraPart")
print("  - Created PocketKnife viewmodel with proper CameraPart")
print("  - Created M67 viewmodel with proper CameraPart")
print("\n🎮 Viewmodels should now work correctly!")
print("\n🔧 Test with: _G.DebugViewmodel('G36')")