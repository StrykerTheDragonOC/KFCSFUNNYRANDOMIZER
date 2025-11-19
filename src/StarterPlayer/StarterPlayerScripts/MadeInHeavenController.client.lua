--[[
	Made In Heaven Controller
	Client-side controller for Made In Heaven stand abilities
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Load MIH Handler
local MIHHandler = require(ReplicatedStorage.FPSSystem.Modules.MadeInHeavenHandler)

-- References
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local UseAbilityEvent = RemoteEvents:WaitForChild("UseAbility")

-- State
local mihInstance = nil
local standActive = false
local holdingKey = {}
local holdStartTime = {}

-- Constants
local HEART_RIP_HOLD_TIME = 2
local KNIFE_CHARGE_TIME = 4

-- Initialize when ability is activated
UseAbilityEvent.OnClientEvent:Connect(function(abilityName, action, data)
	if abilityName == "MadeInHeaven" and action == "Activated" then
		print("=== MADE IN HEAVEN ACTIVATED ===")
		
		-- Create MIH instance
		mihInstance = MIHHandler.new(player, character)
		
		-- Auto-summon stand
		task.wait(0.5)
		mihInstance:SummonStand()
		standActive = true
		
		-- Setup controls
		SetupControls()
		
		print("✓ Made In Heaven ready - Q to toggle, E/R/T/F/G/H for moves")
	end
end)

function SetupControls()
	if not mihInstance then return end
	
	-- Q - Toggle Stand
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.Q then
			if standActive then
				mihInstance:DismissStand()
				standActive = false
				print("Stand dismissed")
			else
				mihInstance:SummonStand()
				standActive = true
				print("Stand summoned")
			end
		end
	end)
	
	-- E - Barrage
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not standActive then return end
		
		if input.KeyCode == Enum.KeyCode.E then
			if not mihInstance:IsOnCooldown("E") then
				UseAbilityEvent:FireServer("MadeInHeaven", "Barrage")
				mihInstance:PlayBarrageAnimation()
				mihInstance:SetCooldown("E", 4)
			else
				warn("Barrage on cooldown:", math.ceil(mihInstance:GetRemainingCooldown("E")), "seconds")
			end
		end
	end)
	
	-- R - Heavy Punch / Heart Rip
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not standActive then return end
		
		if input.KeyCode == Enum.KeyCode.R then
			holdingKey["R"] = true
			holdStartTime["R"] = tick()
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.R and holdingKey["R"] then
			holdingKey["R"] = false
			
			local holdDuration = tick() - holdStartTime["R"]
			
			if holdDuration >= HEART_RIP_HOLD_TIME then
				-- Heart Rip (hold)
				if not mihInstance:IsOnCooldown("RHold") then
					UseAbilityEvent:FireServer("MadeInHeaven", "HeartRip")
					mihInstance:PlayPunchAnimation(true)
					mihInstance:SetCooldown("RHold", 20)
					print("Heart Rip!")
				else
					warn("Heart Rip on cooldown")
				end
			else
				-- Normal Heavy Punch
				if not mihInstance:IsOnCooldown("R") then
					UseAbilityEvent:FireServer("MadeInHeaven", "HeavyPunch")
					mihInstance:PlayPunchAnimation(true)
					mihInstance:SetCooldown("R", 8)
				else
					warn("Heavy Punch on cooldown")
				end
			end
		end
	end)
	
	-- T - Knife Throw / Charged Knives
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not standActive then return end
		
		if input.KeyCode == Enum.KeyCode.T then
			holdingKey["T"] = true
			holdStartTime["T"] = tick()
			
			-- Visual charging effect
			task.spawn(function()
				while holdingKey["T"] do
					local chargeDuration = tick() - holdStartTime["T"]
					if chargeDuration >= KNIFE_CHARGE_TIME then
						-- Max charge glow
						if character:FindFirstChild("HumanoidRootPart") then
							local hrp = character.HumanoidRootPart
							if not hrp:FindFirstChild("ChargeGlow") then
								local glow = Instance.new("PointLight")
								glow.Name = "ChargeGlow"
								glow.Brightness = 3
								glow.Range = 15
								glow.Color = Color3.fromRGB(255, 255, 100)
								glow.Parent = hrp
							end
						end
						break
					end
					task.wait(0.1)
				end
			end)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.T and holdingKey["T"] then
			holdingKey["T"] = false
			
			-- Remove charge glow
			if character:FindFirstChild("HumanoidRootPart") then
				local glow = character.HumanoidRootPart:FindFirstChild("ChargeGlow")
				if glow then glow:Destroy() end
			end
			
			local holdDuration = tick() - holdStartTime["T"]
			
			if holdDuration >= KNIFE_CHARGE_TIME then
				-- Charged Knives
				if not mihInstance:IsOnCooldown("THold") then
					UseAbilityEvent:FireServer("MadeInHeaven", "ChargedKnives")
					mihInstance:SetCooldown("THold", 10)
					print("Charged Knives!")
				else
					warn("Charged Knives on cooldown")
				end
			else
				-- Normal Knife Throw
				if not mihInstance:IsOnCooldown("T") then
					UseAbilityEvent:FireServer("MadeInHeaven", "KnifeThrow")
					mihInstance:SetCooldown("T", 5)
				else
					warn("Knife Throw on cooldown")
				end
			end
		end
	end)
	
	-- F - Block
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not standActive then return end
		
		if input.KeyCode == Enum.KeyCode.F then
			if not mihInstance:IsOnCooldown("F") then
				mihInstance.BlockActive = true
				mihInstance.BlockDamageAbsorbed = 0
				mihInstance:PlayBlockAnimation()
				UseAbilityEvent:FireServer("MadeInHeaven", "BlockStart")
				print("Blocking...")
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.F and mihInstance.BlockActive then
			mihInstance.BlockActive = false
			mihInstance:StopBlockAnimation()
			UseAbilityEvent:FireServer("MadeInHeaven", "BlockEnd")
			mihInstance:SetCooldown("F", 20)
			print("Block ended")
		end
	end)
	
	-- G - Dash Combo
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not standActive then return end
		
		if input.KeyCode == Enum.KeyCode.G then
			if not mihInstance:IsOnCooldown("G") then
				UseAbilityEvent:FireServer("MadeInHeaven", "DashCombo")
				mihInstance:SetCooldown("G", 15)
				
				-- Create afterimages during dash
				task.spawn(function()
					for i = 1, 8 do
						mihInstance:CreateAfterimage()
						task.wait(0.1)
					end
				end)
			else
				warn("Dash Combo on cooldown")
			end
		end
	end)
	
	-- H+ - Universe Reset (hold H)
	local hHoldStartTime = 0
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not standActive then return end
		
		if input.KeyCode == Enum.KeyCode.H then
			hHoldStartTime = tick()
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.H then
			local holdDuration = tick() - hHoldStartTime
			
			if holdDuration >= 1.5 then -- Must hold H for 1.5 seconds
				if not mihInstance:IsOnCooldown("HPlus") then
					UseAbilityEvent:FireServer("MadeInHeaven", "UniverseReset")
					mihInstance:SetCooldown("HPlus", 300) -- 5 minute cooldown
					print("=== UNIVERSE RESET ===")
				else
					warn("Universe Reset on cooldown:", math.ceil(mihInstance:GetRemainingCooldown("HPlus") / 60), "minutes")
				end
			end
		end
	end)
end

-- Cleanup on character reset
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	if mihInstance then
		mihInstance:Destroy()
		mihInstance = nil
	end
	standActive = false
end)

print("MadeInHeavenController loaded")

