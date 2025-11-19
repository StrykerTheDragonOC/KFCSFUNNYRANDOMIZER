--[[
	Perk Activation Controller
	Handles perk activation with keybinds
	Shows perk UI and cooldown indicators
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local ActivatePerkEvent = RemoteEvents:WaitForChild("ActivatePerk")
local PerkActivatedEvent = RemoteEvents:WaitForChild("PerkActivated")
local PerkDeactivatedEvent = RemoteEvents:WaitForChild("PerkDeactivated")

local PerkController = {}

-- Equipped perks (loaded from player data or settings)
local equippedPerks = {
	Slot1 = "double_jump",  -- Always active
	Slot2 = nil,  -- Keybind: E (activatable perk)
	Slot3 = nil  -- Reserved for future use
}

-- Current active perk (activated with E key)
local currentPerk = "speed_boost" -- Default perk for E key

-- Perk cooldowns (client-side tracking)
local perkCooldowns = {}

-- Perk UI
local perkUI = nil

function PerkController:Initialize()
	-- Create perk UI
	self:CreatePerkUI()

	-- Listen for keybinds
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- CRITICAL: Disable perks in Lobby
		if player.Team and player.Team.Name == "Lobby" then
			return -- Block all perk activations in lobby
		end

		-- Perk Activation: Key "E"
		if input.KeyCode == Enum.KeyCode.E and currentPerk then
			self:ActivatePerk(currentPerk)
		end
	end)

	-- Listen for perk activation broadcasts
	PerkActivatedEvent.OnClientEvent:Connect(function(activator, perkId, perkData)
		self:OnPerkActivated(activator, perkId, perkData)
	end)

	-- Listen for perk deactivation broadcasts
	PerkDeactivatedEvent.OnClientEvent:Connect(function(activator, perkId)
		self:OnPerkDeactivated(activator, perkId)
	end)

	-- Update cooldowns UI
	RunService.RenderStepped:Connect(function()
		self:UpdateCooldownUI()
	end)

	print("PerkActivationController initialized")
end

function PerkController:CreatePerkUI()
	perkUI = Instance.new("ScreenGui")
	perkUI.Name = "PerkUI"
	perkUI.ResetOnSpawn = false
	perkUI.DisplayOrder = 90
	perkUI.Parent = playerGui

	-- Container for perk display (hidden - perk shown in BattlefieldHUD)
	local container = Instance.new("Frame")
	container.Name = "PerkContainer"
	container.Size = UDim2.new(0, 250, 0, 80)
	container.Position = UDim2.new(1, -270, 1, -100)
	container.BackgroundTransparency = 1
	container.Visible = false -- Hidden since BattlefieldHUD shows perks
	container.Parent = perkUI

	-- Create 2 perk slots (Slot1 is double jump, always active)
	for i = 2, 3 do
		local slotName = "Slot" .. i
		local perkId = equippedPerks[slotName]

		if perkId then
			local slot = self:CreatePerkSlot(slotName, perkId, i - 1)
			slot.Parent = container
		end
	end
end

function PerkController:CreatePerkSlot(slotName, perkId, index)
	local slot = Instance.new("Frame")
	slot.Name = slotName
	slot.Size = UDim2.new(0, 110, 0, 70)
	slot.Position = UDim2.new(0, (index - 1) * 120, 0, 0)
	slot.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	slot.BackgroundTransparency = 0.3
	slot.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = slot

	-- Perk name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PerkName"
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = self:GetPerkDisplayName(perkId)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = slot

	-- Keybind indicator
	local keybind = Instance.new("TextLabel")
	keybind.Name = "Keybind"
	keybind.Size = UDim2.new(0, 25, 0, 25)
	keybind.Position = UDim2.new(1, -30, 0, 5)
	keybind.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	keybind.BackgroundTransparency = 0.3
	keybind.Text = tostring(index)
	keybind.TextColor3 = Color3.fromRGB(255, 255, 255)
	keybind.Font = Enum.Font.GothamBold
	keybind.TextSize = 14
	keybind.Parent = slot

	local keybindCorner = Instance.new("UICorner")
	keybindCorner.CornerRadius = UDim.new(0, 4)
	keybindCorner.Parent = keybind

	-- Cooldown overlay
	local cooldownOverlay = Instance.new("Frame")
	cooldownOverlay.Name = "CooldownOverlay"
	cooldownOverlay.Size = UDim2.new(1, 0, 0, 0)
	cooldownOverlay.Position = UDim2.new(0, 0, 1, 0)
	cooldownOverlay.AnchorPoint = Vector2.new(0, 1)
	cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cooldownOverlay.BackgroundTransparency = 0.5
	cooldownOverlay.BorderSizePixel = 0
	cooldownOverlay.ZIndex = 2
	cooldownOverlay.Parent = slot

	-- Cooldown text
	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Size = UDim2.new(1, 0, 1, 0)
	cooldownText.BackgroundTransparency = 1
	cooldownText.Text = ""
	cooldownText.TextColor3 = Color3.fromRGB(255, 100, 100)
	cooldownText.Font = Enum.Font.GothamBold
	cooldownText.TextSize = 24
	cooldownText.ZIndex = 3
	cooldownText.Parent = slot

	return slot
end

function PerkController:GetPerkDisplayName(perkId)
	local names = {
		speed_boost = "Speed Boost",
		incendiary_rounds = "Incendiary",
		frostbite_rounds = "Frostbite",
		explosive_rounds = "Explosive",
		double_jump = "Double Jump"
	}
	return names[perkId] or perkId
end

function PerkController:ActivatePerk(perkId)
	-- Check if on cooldown
	if self:IsOnCooldown(perkId) then
		local timeLeft = math.ceil(self:GetCooldownRemaining(perkId))
		print("Perk on cooldown:", perkId, "-", timeLeft, "seconds")
		return
	end

	-- Send activation request to server
	ActivatePerkEvent:FireServer(perkId)
	print("Requested perk activation:", perkId)
end

function PerkController:OnPerkActivated(activator, perkId, perkData)
	-- Visual feedback
	if activator == player then
		print("✓ Perk activated:", perkId)

		-- Flash the perk slot
		local slotName = self:GetSlotForPerk(perkId)
		if slotName and perkUI then
			local slot = perkUI.PerkContainer:FindFirstChild(slotName)
			if slot then
				local tween = TweenService:Create(slot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
					BackgroundColor3 = Color3.fromRGB(100, 255, 100)
				})
				tween:Play()
			end
		end

		-- Set cooldown
		if perkData.cooldown > 0 then
			perkCooldowns[perkId] = tick() + perkData.cooldown
		end

		-- Show notification
		self:ShowPerkNotification(perkId, perkData)
	end

	-- Apply visual effects for other players
	if activator ~= player then
		self:ShowPerkEffectOnPlayer(activator, perkId, perkData)
	end
end

function PerkController:OnPerkDeactivated(activator, perkId)
	if activator == player then
		print("Perk deactivated:", perkId)
	end
end

function PerkController:ShowPerkEffectOnPlayer(targetPlayer, perkId, perkData)
	-- Show visual effects on other players (e.g., speed boost particles)
	if perkId == "speed_boost" then
		local character = targetPlayer.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			-- Create speed effect particles
			local attachment = Instance.new("Attachment")
			attachment.Name = "SpeedBoostEffect"
			attachment.Parent = character.HumanoidRootPart

			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
			particles.Size = NumberSequence.new(0.3)
			particles.Lifetime = NumberRange.new(0.5)
			particles.Rate = 40
			particles.Speed = NumberRange.new(5)
			particles.Parent = attachment

			-- Remove after duration
			game:GetService("Debris"):AddItem(attachment, perkData.duration or 8)
		end
	end
end

function PerkController:ShowPerkNotification(perkId, perkData)
	-- Create temporary notification
	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(0, 300, 0, 50)
	notification.Position = UDim2.new(0.5, -150, 0.3, 0)
	notification.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	notification.BackgroundTransparency = 0.2
	notification.Text = "ACTIVATED: " .. self:GetPerkDisplayName(perkId)
	notification.TextColor3 = Color3.fromRGB(100, 255, 100)
	notification.Font = Enum.Font.GothamBold
	notification.TextSize = 20
	notification.Parent = perkUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification

	-- Fade out and remove
	local tween = TweenService:Create(notification, TweenInfo.new(2), {
		BackgroundTransparency = 1,
		TextTransparency = 1
	})
	tween:Play()

	game:GetService("Debris"):AddItem(notification, 2.5)
end

function PerkController:GetSlotForPerk(perkId)
	for slotName, equippedPerkId in pairs(equippedPerks) do
		if equippedPerkId == perkId then
			return slotName
		end
	end
	return nil
end

function PerkController:IsOnCooldown(perkId)
	if not perkCooldowns[perkId] then return false end
	return tick() < perkCooldowns[perkId]
end

function PerkController:GetCooldownRemaining(perkId)
	if not self:IsOnCooldown(perkId) then return 0 end
	return math.max(0, perkCooldowns[perkId] - tick())
end

function PerkController:UpdateCooldownUI()
	if not perkUI then return end

	for slotName, perkId in pairs(equippedPerks) do
		if slotName ~= "Slot1" then  -- Skip double jump (always active)
			local slot = perkUI.PerkContainer:FindFirstChild(slotName)
			if slot then
				local cooldownOverlay = slot:FindFirstChild("CooldownOverlay")
				local cooldownText = slot:FindFirstChild("CooldownText")

				if self:IsOnCooldown(perkId) then
					local remaining = self:GetCooldownRemaining(perkId)
					local percentage = remaining / 30  -- Assume max 30s cooldown for UI

					if cooldownOverlay then
						cooldownOverlay.Size = UDim2.new(1, 0, percentage, 0)
					end

					if cooldownText then
						cooldownText.Text = string.format("%.1f", remaining)
					end
				else
					if cooldownOverlay then
						cooldownOverlay.Size = UDim2.new(1, 0, 0, 0)
					end

					if cooldownText then
						cooldownText.Text = ""
					end
				end
			end
		end
	end
end

-- Initialize
PerkController:Initialize()

return PerkController
