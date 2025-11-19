--[[
	Day/Night Cycle System
	Slowly transitions between day and night
	Cycle duration: ~10-15 minutes
	Affects lighting, atmosphere, and gameplay
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local DayNightCycle = {}

-- Cycle settings
local CYCLE_DURATION = 600  -- 10 minutes for full day/night cycle
local TRANSITION_SPEED = 0.5  -- How fast lighting changes

-- Time of day states
local DAY_TIME = 12  -- 12:00 (noon)
local NIGHT_TIME = 0  -- 00:00 (midnight)
local SUNRISE_TIME = 6  -- 06:00
local SUNSET_TIME = 18  -- 18:00

-- Current state
local currentTime = DAY_TIME
local isDay = true

-- Lighting presets
local DAY_LIGHTING = {
	ClockTime = DAY_TIME,
	Brightness = 2,
	Ambient = Color3.fromRGB(140, 140, 140),
	OutdoorAmbient = Color3.fromRGB(180, 180, 180),
	ColorShift_Top = Color3.fromRGB(255, 255, 255),
	ColorShift_Bottom = Color3.fromRGB(200, 200, 200),
	FogColor = Color3.fromRGB(192, 192, 192),
	FogEnd = 100000,
	FogStart = 0
}

local NIGHT_LIGHTING = {
	ClockTime = NIGHT_TIME,
	Brightness = 0.5,
	Ambient = Color3.fromRGB(40, 40, 60),
	OutdoorAmbient = Color3.fromRGB(60, 60, 80),
	ColorShift_Top = Color3.fromRGB(50, 50, 100),
	ColorShift_Bottom = Color3.fromRGB(30, 30, 60),
	FogColor = Color3.fromRGB(20, 20, 40),
	FogEnd = 500,
	FogStart = 100
}

function DayNightCycle:Initialize()
	-- Set initial lighting to day
	self:ApplyLightingPreset(DAY_LIGHTING, 0)

	-- Start the cycle
	spawn(function()
		self:RunCycle()
	end)

	print("DayNightCycle initialized - Cycle duration:", CYCLE_DURATION, "seconds")
end

function DayNightCycle:RunCycle()
	while true do
		-- Gradually change time
		local timeIncrement = (24 / CYCLE_DURATION) * task.wait()
		currentTime = (currentTime + timeIncrement) % 24

		-- Update clock time
		Lighting.ClockTime = currentTime

		-- Check for day/night transitions
		if isDay and currentTime >= SUNSET_TIME then
			-- Transition to night
			self:TransitionToNight()
			isDay = false
		elseif not isDay and currentTime >= SUNRISE_TIME and currentTime < DAY_TIME then
			-- Transition to day
			self:TransitionToDay()
			isDay = true
		end

		-- Apply gradual lighting changes
		self:UpdateLighting()
	end
end

function DayNightCycle:TransitionToNight()
	print("Transitioning to NIGHT")

	-- Tween to night lighting
	self:ApplyLightingPreset(NIGHT_LIGHTING, 5)

	-- Broadcast night event
	local nightEvent = game:GetService("ReplicatedStorage"):FindFirstChild("FPSSystem")
		and game:GetService("ReplicatedStorage").FPSSystem.RemoteEvents:FindFirstChild("TimeOfDayChanged")

	if nightEvent then
		nightEvent:FireAllClients("Night")
	end
end

function DayNightCycle:TransitionToDay()
	print("Transitioning to DAY")

	-- Tween to day lighting
	self:ApplyLightingPreset(DAY_LIGHTING, 5)

	-- Broadcast day event
	local dayEvent = game:GetService("ReplicatedStorage"):FindFirstChild("FPSSystem")
		and game:GetService("ReplicatedStorage").FPSSystem.RemoteEvents:FindFirstChild("TimeOfDayChanged")

	if dayEvent then
		dayEvent:FireAllClients("Day")
	end
end

function DayNightCycle:ApplyLightingPreset(preset, tweenTime)
	if tweenTime > 0 then
		-- Tween lighting changes
		local tween = TweenService:Create(Lighting, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), preset)
		tween:Play()
	else
		-- Instant apply
		for property, value in pairs(preset) do
			Lighting[property] = value
		end
	end
end

function DayNightCycle:UpdateLighting()
	-- Gradual lighting adjustments based on time of day
	-- This creates smooth transitions between presets

	if currentTime >= SUNSET_TIME or currentTime < SUNRISE_TIME then
		-- Night time
		local nightIntensity = 1
		if currentTime >= SUNSET_TIME and currentTime < NIGHT_TIME then
			-- Sunset transition
			nightIntensity = (currentTime - SUNSET_TIME) / (24 - SUNSET_TIME)
		elseif currentTime < SUNRISE_TIME then
			-- Pre-sunrise
			nightIntensity = 1 - (currentTime / SUNRISE_TIME)
		end

		-- Apply night intensity
		Lighting.Brightness = 2 - (1.5 * nightIntensity)
	else
		-- Day time
		Lighting.Brightness = 2
	end
end

function DayNightCycle:GetCurrentTimeOfDay()
	if currentTime >= SUNSET_TIME or currentTime < SUNRISE_TIME then
		return "Night"
	else
		return "Day"
	end
end

function DayNightCycle:IsNight()
	return not isDay
end

function DayNightCycle:ForceTimeOfDay(timeOfDay)
	if timeOfDay == "Night" then
		currentTime = NIGHT_TIME
		self:TransitionToNight()
		isDay = false
	else
		currentTime = DAY_TIME
		self:TransitionToDay()
		isDay = true
	end
end

-- Console commands
_G.DayNightCommands = {
	setDay = function()
		DayNightCycle:ForceTimeOfDay("Day")
		print("Forced DAY time")
	end,

	setNight = function()
		DayNightCycle:ForceTimeOfDay("Night")
		print("Forced NIGHT time")
	end,

	getTime = function()
		print("Current time:", string.format("%.2f", currentTime), "(" .. DayNightCycle:GetCurrentTimeOfDay() .. ")")
	end,

	setCycleSpeed = function(duration)
		CYCLE_DURATION = tonumber(duration) or 600
		print("Cycle duration set to", CYCLE_DURATION, "seconds")
	end
}

-- Initialize
DayNightCycle:Initialize()

-- Make globally accessible
_G.DayNightCycle = DayNightCycle

return DayNightCycle
