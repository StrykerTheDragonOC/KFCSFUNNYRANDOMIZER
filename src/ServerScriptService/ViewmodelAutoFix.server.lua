--[[
	Viewmodel Auto-Fix Script
	Automatically creates missing viewmodel folder structure and placeholder models
	This ensures the game can run even if Rojo hasn't synced RBXM files properly
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔧 VIEWMODEL AUTO-FIX")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- Wait for FPSSystem
repeat wait(0.1) until ReplicatedStorage:FindFirstChild("FPSSystem")
local FPSSystem = ReplicatedStorage.FPSSystem

-- Check for Viewmodels folder
local viewmodelsFolder = FPSSystem:FindFirstChild("Viewmodels")
	or FPSSystem:FindFirstChild("ViewModels")
	or FPSSystem:FindFirstChild("viewmodels")

if not viewmodelsFolder then
	warn("⚠ Viewmodels folder not found - creating...")
	viewmodelsFolder = Instance.new("Folder")
	viewmodelsFolder.Name = "Viewmodels"
	viewmodelsFolder.Parent = FPSSystem
	print("✓ Created Viewmodels folder")
else
	print("✓ Found Viewmodels folder:", viewmodelsFolder.Name)
end

-- Function to create placeholder model with CameraPart
local function CreatePlaceholderViewModel(weaponName, category, type)
	print("Creating placeholder viewmodel for:", weaponName)

	-- Create Model
	local model = Instance.new("Model")
	model.Name = weaponName

	-- Create CameraPart
	local cameraPart = Instance.new("Part")
	cameraPart.Name = "CameraPart"
	cameraPart.Size = Vector3.new(0.2, 0.2, 0.2)
	cameraPart.Transparency = 1
	cameraPart.CanCollide = false
	cameraPart.Massless = true
	cameraPart.Anchored = false
	cameraPart.CastShadow = false
	cameraPart.Parent = model

	-- Create placeholder gun part (visible so you know it's a placeholder)
	local gunPart = Instance.new("Part")
	gunPart.Name = "Handle"
	gunPart.Size = Vector3.new(0.3, 0.3, 1)
	gunPart.Color = Color3.fromRGB(100, 100, 100)
	gunPart.Material = Enum.Material.SmoothPlastic
	gunPart.CanCollide = false
	gunPart.Massless = true
	gunPart.Anchored = false
	gunPart.CastShadow = false
	gunPart.CFrame = cameraPart.CFrame * CFrame.new(0.3, -0.2, -0.5)
	gunPart.Parent = model

	-- Weld gunPart to CameraPart
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = cameraPart
	weld.Part1 = gunPart
	weld.Parent = gunPart

	-- Set CameraPart as PrimaryPart
	model.PrimaryPart = cameraPart

	-- Add a StringValue to mark this as a placeholder
	local placeholder = Instance.new("StringValue")
	placeholder.Name = "PlaceholderViewmodel"
	placeholder.Value = "This is a placeholder - replace with proper RBXM model"
	placeholder.Parent = model

	print("✓ Created placeholder viewmodel:", weaponName, "(" .. category .. "/" .. type .. ")")
	return model
end

-- Function to ensure folder exists
local function EnsureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
		print("  Created folder:", name)
	end
	return folder
end

-- Define weapon structure
local weapons = {
	{Name = "G36", Category = "Primary", Type = "AssaultRifles"},
	{Name = "M9", Category = "Secondary", Type = "Pistols"},
	{Name = "PocketKnife", Category = "Melee", Type = "OneHandedBlades", HasSubfolder = true},
}

print("")
print("Checking and fixing weapon viewmodels...")
print("")

local fixedCount = 0
local alreadyExistCount = 0

for _, weaponInfo in ipairs(weapons) do
	print("Checking:", weaponInfo.Name)

	-- Ensure category folder exists
	local categoryFolder = EnsureFolder(viewmodelsFolder, weaponInfo.Category)

	-- Ensure type folder exists
	local typeFolder = EnsureFolder(categoryFolder, weaponInfo.Type)

	-- Check if weapon exists
	local weaponModel = nil

	if weaponInfo.HasSubfolder then
		-- PocketKnife special case: PocketKnife/PocketKnife.rbxm
		local weaponFolder = typeFolder:FindFirstChild(weaponInfo.Name)
		if not weaponFolder then
			weaponFolder = Instance.new("Folder")
			weaponFolder.Name = weaponInfo.Name
			weaponFolder.Parent = typeFolder
			print("  Created weapon folder:", weaponInfo.Name)
		end

		weaponModel = weaponFolder:FindFirstChild(weaponInfo.Name)
		if not weaponModel or not weaponModel:IsA("Model") then
			-- Create placeholder
			weaponModel = CreatePlaceholderViewModel(weaponInfo.Name, weaponInfo.Category, weaponInfo.Type)
			weaponModel.Parent = weaponFolder
			fixedCount = fixedCount + 1
		else
			-- Check if it has CameraPart
			local cameraPart = weaponModel:FindFirstChild("CameraPart", true)
			if not cameraPart or not cameraPart:IsA("BasePart") then
				warn("  ⚠ Viewmodel exists but missing CameraPart - adding one")
				local newCameraPart = Instance.new("Part")
				newCameraPart.Name = "CameraPart"
				newCameraPart.Size = Vector3.new(0.2, 0.2, 0.2)
				newCameraPart.Transparency = 1
				newCameraPart.CanCollide = false
				newCameraPart.Massless = true
				newCameraPart.Anchored = false
				newCameraPart.Parent = weaponModel
				weaponModel.PrimaryPart = newCameraPart
				fixedCount = fixedCount + 1
			else
				print("  ✓ Viewmodel already exists and has CameraPart")
				alreadyExistCount = alreadyExistCount + 1
			end
		end
	else
		-- Direct model (G36, M9)
		weaponModel = typeFolder:FindFirstChild(weaponInfo.Name)
		if not weaponModel or not (weaponModel:IsA("Model") or weaponModel:IsA("Tool")) then
			-- Create placeholder
			weaponModel = CreatePlaceholderViewModel(weaponInfo.Name, weaponInfo.Category, weaponInfo.Type)
			weaponModel.Parent = typeFolder
			fixedCount = fixedCount + 1
		else
			-- Check if it has CameraPart
			local cameraPart = weaponModel:FindFirstChild("CameraPart", true)
			if not cameraPart or not cameraPart:IsA("BasePart") then
				warn("  ⚠ Viewmodel exists but missing CameraPart - adding one")
				local newCameraPart = Instance.new("Part")
				newCameraPart.Name = "CameraPart"
				newCameraPart.Size = Vector3.new(0.2, 0.2, 0.2)
				newCameraPart.Transparency = 1
				newCameraPart.CanCollide = false
				newCameraPart.Massless = true
				newCameraPart.Anchored = false
				newCameraPart.Parent = weaponModel

				if weaponModel:IsA("Model") then
					weaponModel.PrimaryPart = newCameraPart
				end
				fixedCount = fixedCount + 1
			else
				print("  ✓ Viewmodel already exists and has CameraPart")
				alreadyExistCount = alreadyExistCount + 1
			end
		end
	end

	print("")
end

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ AUTO-FIX COMPLETE")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Viewmodels already correct:", alreadyExistCount)
print("Viewmodels created/fixed:", fixedCount)
print("")
if fixedCount > 0 then
	print("⚠ WARNING: Placeholder viewmodels were created!")
	print("These are temporary models with basic geometry.")
	print("Replace them with proper RBXM models for the final game.")
	print("")
	print("To replace placeholders:")
	print("1. Ensure Rojo is running: rojo serve")
	print("2. Delete placeholder models in Studio")
	print("3. Reconnect Rojo to sync proper RBXM files")
else
	print("✓ All viewmodels are properly configured!")
end
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
