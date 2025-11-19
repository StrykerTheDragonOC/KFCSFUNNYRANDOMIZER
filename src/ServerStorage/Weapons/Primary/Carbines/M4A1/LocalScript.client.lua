--[[
	M4A1 Carbine Client Script
	Handles client-side weapon functionality
	Based on G36 template
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

-- Modules
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local ViewmodelSystem = require(ReplicatedStorage.FPSSystem.Modules.ViewmodelSystem)

-- Remote Events
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponFired = RemoteEvents:WaitForChild("WeaponFired")
local WeaponReloaded = RemoteEvents:WaitForChild("WeaponReloaded")
local WeaponEquipped = RemoteEvents:WaitForChild("WeaponEquipped")
local WeaponUnequipped = RemoteEvents:WaitForChild("WeaponUnequipped")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local tool = script.Parent
local weaponName = "M4A1" -- Weapon name

-- Get weapon config
local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
if not weaponConfig then
	warn("No weapon config found for:", weaponName)
	return
end

-- Weapon state
local currentAmmo = weaponConfig.MaxAmmo or 30
local reserveAmmo = weaponConfig.MaxReserveAmmo or 120
local isReloading = false
local canFire = true
local lastFireTime = 0
local isEquipped = false
local isFiring = false
local currentFireMode = weaponConfig.DefaultFireMode or "Auto"
local currentAmmoType = weaponConfig.DefaultAmmoType or "Standard"
local consecutiveShots = 0

-- Viewmodel
local viewmodel = nil
local viewmodelMotor = nil

-- Fire weapon
local function FireWeapon()
	if not canFire or isReloading or currentAmmo <= 0 then
		return
	end

	local fireRate = weaponConfig.FireRate or 800
	local timeBetweenShots = 60 / fireRate

	if tick() - lastFireTime < timeBetweenShots then
		return
	end

	lastFireTime = tick()
	currentAmmo = currentAmmo - 1
	consecutiveShots = consecutiveShots + 1

	-- Fire to server
	local mousePosition = mouse.Hit.Position
	WeaponFired:FireServer(weaponName, mousePosition, currentAmmoType)

	-- Play fire animation
	if viewmodel then
		-- Viewmodel recoil
		local recoil = weaponConfig.Recoil or {Vertical = 0.8, Horizontal = 0.4}
		local recoilX = (math.random() - 0.5) * recoil.Horizontal * 0.5
		local recoilY = -recoil.Vertical * 0.3

		Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(recoilY), math.rad(recoilX), 0)
	end

	-- Check if out of ammo
	if currentAmmo <= 0 then
		canFire = false
		task.wait(0.2)
		Reload()
	end
end

-- Reload
function Reload()
	if isReloading or reserveAmmo <= 0 or currentAmmo == weaponConfig.MaxAmmo then
		return
	end

	isReloading = true
	canFire = false

	local reloadTime = (currentAmmo == 0) and weaponConfig.EmptyReloadTime or weaponConfig.ReloadTime
	print("Reloading", weaponName, "-", reloadTime, "seconds")

	WeaponReloaded:FireServer(weaponName)

	task.wait(reloadTime)

	-- Calculate ammo transfer
	local ammoNeeded = weaponConfig.MaxAmmo - currentAmmo
	local ammoToAdd = math.min(ammoNeeded, reserveAmmo)

	currentAmmo = currentAmmo + ammoToAdd
	reserveAmmo = reserveAmmo - ammoToAdd

	isReloading = false
	canFire = true
	consecutiveShots = 0

	print("Reload complete -", currentAmmo, "/", reserveAmmo)
end

-- Switch fire mode
local function SwitchFireMode()
	if not weaponConfig.FireModes or #weaponConfig.FireModes <= 1 then
		return
	end

	local currentIndex = table.find(weaponConfig.FireModes, currentFireMode)
	if currentIndex then
		local nextIndex = (currentIndex % #weaponConfig.FireModes) + 1
		currentFireMode = weaponConfig.FireModes[nextIndex]
		print("Fire mode:", currentFireMode)
	end
end

-- Equip
tool.Equipped:Connect(function()
	isEquipped = true

	-- Lock to first person
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMaxZoomDistance = 0.5

	-- Load viewmodel
	viewmodel = ViewmodelSystem:LoadViewmodel(weaponName, weaponConfig)

	-- Notify server
	WeaponEquipped:FireServer(weaponName)

	print("Equipped:", weaponName)
end)

-- Unequip
tool.Unequipped:Connect(function()
	isEquipped = false
	isFiring = false

	-- Unlock camera
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 128

	-- Unload viewmodel
	if viewmodel then
		viewmodel:Destroy()
		viewmodel = nil
	end

	-- Notify server
	WeaponUnequipped:FireServer(weaponName)

	print("Unequipped:", weaponName)
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not isEquipped or gameProcessed then return end

	-- Fire
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isFiring = true

		if currentFireMode == "Auto" then
			while isFiring and isEquipped do
				FireWeapon()
				task.wait()
			end
		elseif currentFireMode == "Semi" then
			FireWeapon()
		elseif currentFireMode == "Burst" then
			local burstCount = weaponConfig.BurstCount or 3
			for i = 1, burstCount do
				if not isFiring or not isEquipped then break end
				FireWeapon()
				task.wait(0.08)
			end
		end
	end

	-- Reload
	if input.KeyCode == Enum.KeyCode.R then
		Reload()
	end

	-- Switch fire mode
	if input.KeyCode == Enum.KeyCode.V then
		SwitchFireMode()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isFiring = false
	end
end)

print("M4A1 client script loaded")
