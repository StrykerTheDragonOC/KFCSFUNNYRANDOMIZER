--[[
	Quickswap Controller
	Handles quick weapon swapping:
	- G: Quickswap to grenade (throw and return to previous weapon)
	- F: Quickswap to melee (attack and return to previous weapon)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local QuickswapController = {}

local lastEquippedTool = nil
local isQuickswapping = false
local quickswapCooldown = 0.5
local lastQuickswap = 0

-- Get tool by category
local function getToolByCategory(category)
	local backpack = player:WaitForChild("Backpack")

	-- Search in backpack
	for _, tool in pairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			-- Check if tool has a config that specifies its category
			local config = tool:FindFirstChild("Config")
			if config and config:FindFirstChild("Category") then
				if config.Category.Value == category then
					return tool
				end
			elseif tool.Name:find(category) or tool:FindFirstChild(category) then
				return tool
			end
		end
	end

	-- Also check equipped tool
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool then
		local config = equippedTool:FindFirstChild("Config")
		if config and config:FindFirstChild("Category") then
			if config.Category.Value == category then
				return equippedTool
			end
		elseif equippedTool.Name:find(category) or equippedTool:FindFirstChild(category) then
			return equippedTool
		end
	end

	return nil
end

-- Get current equipped tool
local function getCurrentTool()
	return character:FindFirstChildOfClass("Tool")
end

-- Equip tool
local function equipTool(tool)
	if not tool then return false end

	-- If tool is in backpack, equip it
	if tool.Parent == player.Backpack then
		humanoid:EquipTool(tool)
		return true
	elseif tool.Parent == character then
		-- Already equipped
		return true
	end

	return false
end

-- Unequip current tool
local function unequipTool()
	local currentTool = getCurrentTool()
	if currentTool then
		humanoid:UnequipTools()
	end
end

-- Quickswap to grenade
function QuickswapController:QuickswapGrenade()
	if isQuickswapping then return end
	if tick() - lastQuickswap < quickswapCooldown then return end

	local grenadeTool = getToolByCategory("Grenade")
	if not grenadeTool then
		warn("No grenade found in inventory")
		return
	end

	isQuickswapping = true
	lastQuickswap = tick()

	-- Store current tool
	local previousTool = getCurrentTool()
	lastEquippedTool = previousTool

	-- Equip grenade
	equipTool(grenadeTool)

	print("✓ Quickswapped to grenade")

	-- Wait for grenade to be thrown (listen for tool unequipped)
	local grenadeEquipped = true
	local grenadeUnequipped
	grenadeUnequipped = grenadeTool.Unequipped:Connect(function()
		grenadeEquipped = false
		grenadeUnequipped:Disconnect()
	end)

	-- Timeout after 5 seconds
	spawn(function()
		wait(5)
		if grenadeEquipped then
			grenadeEquipped = false
			grenadeUnequipped:Disconnect()
		end
	end)

	-- Wait for grenade to be unequipped
	while grenadeEquipped do
		wait(0.1)
	end

	-- Return to previous tool
	wait(0.2)
	if lastEquippedTool and lastEquippedTool.Parent then
		equipTool(lastEquippedTool)
	end

	isQuickswapping = false
end

-- Quickswap to melee
function QuickswapController:QuickswapMelee()
	if isQuickswapping then return end
	if tick() - lastQuickswap < quickswapCooldown then return end

	local meleeTool = getToolByCategory("Melee")
	if not meleeTool then
		warn("No melee found in inventory")
		return
	end

	isQuickswapping = true
	lastQuickswap = tick()

	-- Store current tool
	local previousTool = getCurrentTool()
	lastEquippedTool = previousTool

	-- Equip melee
	equipTool(meleeTool)

	print("✓ Quickswapped to melee")

	-- Auto-attack with melee (trigger activated event)
	if meleeTool.Activated then
		meleeTool:Activate()
	end

	-- Return to previous tool after attack animation (~0.5 seconds)
	wait(0.6)
	if lastEquippedTool and lastEquippedTool.Parent then
		equipTool(lastEquippedTool)
	else
		-- No previous tool, just unequip melee
		unequipTool()
	end

	isQuickswapping = false
end

-- Setup input handling
function QuickswapController:Initialize()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.G then
			-- Quickswap to grenade
			self:QuickswapGrenade()
		elseif input.KeyCode == Enum.KeyCode.F then
			-- Quickswap to melee
			self:QuickswapMelee()
		end
	end)

	print("✓ QuickswapController initialized (G=Grenade, F=Melee)")
end

-- Initialize on character spawn
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	isQuickswapping = false
	lastEquippedTool = nil
end)

-- Initialize
QuickswapController:Initialize()

return QuickswapController
