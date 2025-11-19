--[[
	Viewmodel Diagnostic Script
	Run this in Roblox Studio to see what's actually loaded
	Paste output in console and share with developer
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔍 VIEWMODEL DIAGNOSTIC REPORT")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- Check if FPSSystem exists
local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
if not fpsSystem then
	warn("❌ CRITICAL: FPSSystem folder not found in ReplicatedStorage!")
	warn("   Rojo might not be syncing properly")
	return
end
print("✓ FPSSystem found")

-- Check for Viewmodels folder (case-insensitive)
local viewmodelsFolder = fpsSystem:FindFirstChild("Viewmodels")
	or fpsSystem:FindFirstChild("ViewModels")
	or fpsSystem:FindFirstChild("viewmodels")

if not viewmodelsFolder then
	warn("❌ CRITICAL: Viewmodels folder not found!")
	warn("   Expected at: ReplicatedStorage.FPSSystem.Viewmodels")
	warn("")
	warn("Available folders in FPSSystem:")
	for _, child in ipairs(fpsSystem:GetChildren()) do
		print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
	end
	return
end
print("✓ Viewmodels folder found: " .. viewmodelsFolder.Name)

-- Function to print folder tree
local function printTree(instance, indent, maxDepth)
	if maxDepth <= 0 then return end

	for _, child in ipairs(instance:GetChildren()) do
		local icon = "📁"
		if child:IsA("Model") then
			icon = "🎮"
		elseif child:IsA("Tool") then
			icon = "🔧"
		elseif child:IsA("Part") then
			icon = "🧱"
		end

		print(indent .. icon .. " " .. child.Name .. " (" .. child.ClassName .. ")")

		-- Special check for viewmodel requirements
		if child:IsA("Model") and (child.Parent.Name == "AssaultRifles" or child.Parent.Name == "Pistols" or child.Parent.Name == "OneHandedBlades") then
			local cameraPart = child:FindFirstChild("CameraPart", true)
			if cameraPart then
				print(indent .. "  ✓ Has CameraPart")
			else
				print(indent .. "  ❌ Missing CameraPart!")
			end
		end

		if child:IsA("Folder") or child:IsA("Model") then
			printTree(child, indent .. "  ", maxDepth - 1)
		end
	end
end

-- Check category folders
local categories = {"Primary", "Secondary", "Melee", "Grenade"}
for _, category in ipairs(categories) do
	local categoryFolder = viewmodelsFolder:FindFirstChild(category)
	if categoryFolder then
		print("✓ " .. category .. " folder found")
	else
		warn("❌ " .. category .. " folder NOT found")
	end
end

print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("VIEWMODELS FOLDER STRUCTURE:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
printTree(viewmodelsFolder, "", 4)

print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("WEAPON CHECKS:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- Check specific weapons
local weaponPaths = {
	{name = "G36", path = {"Primary", "AssaultRifles"}},
	{name = "M9", path = {"Secondary", "Pistols"}},
	{name = "PocketKnife", path = {"Melee", "OneHandedBlades", "PocketKnife"}},
}

for _, weaponInfo in ipairs(weaponPaths) do
	print("")
	print("Checking: " .. weaponInfo.name)
	print("Path: Viewmodels → " .. table.concat(weaponInfo.path, " → "))

	local current = viewmodelsFolder
	local pathStr = "Viewmodels"
	local foundAll = true

	for i, folderName in ipairs(weaponInfo.path) do
		local next = current:FindFirstChild(folderName)
		if next then
			pathStr = pathStr .. "/" .. folderName
			current = next
			print("  ✓ Found: " .. folderName)
		else
			pathStr = pathStr .. "/" .. folderName
			warn("  ❌ NOT FOUND: " .. folderName)
			warn("     Expected at: " .. pathStr)
			foundAll = false
			break
		end
	end

	if foundAll then
		-- Check if weapon model exists
		local weaponModel = current:FindFirstChild(weaponInfo.name)
		if weaponModel then
			if weaponModel:IsA("Model") or weaponModel:IsA("Tool") then
				print("  ✓ " .. weaponInfo.name .. " model found! (" .. weaponModel.ClassName .. ")")

				-- Check for CameraPart
				local cameraPart = weaponModel:FindFirstChild("CameraPart", true)
				if cameraPart and cameraPart:IsA("BasePart") then
					print("    ✓ CameraPart found")
				else
					warn("    ❌ CameraPart MISSING or not a BasePart!")
					warn("       Viewmodel will not display without CameraPart")
				end
			else
				warn("  ❌ " .. weaponInfo.name .. " exists but is not a Model/Tool (" .. weaponModel.ClassName .. ")")
			end
		else
			warn("  ❌ " .. weaponInfo.name .. " model NOT FOUND in final folder")
			warn("     Available children:")
			for _, child in ipairs(current:GetChildren()) do
				print("       - " .. child.Name .. " (" .. child.ClassName .. ")")
			end
		end
	end
end

print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ DIAGNOSTIC COMPLETE")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("If you see ❌ errors above, those need to be fixed!")
print("Common fixes:")
print("1. Make sure Rojo is running and syncing")
print("2. Check that RBXM files exist in src/ folders")
print("3. Ensure RBXM files are valid Models with CameraPart")
print("")
print("Run this script again after fixes to verify.")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
