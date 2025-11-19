--[[
	Shop Controller (Client)
	Populates and manages the ShopSection in the main menu
	Weapon skin shop system with KFCoins
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local PurchaseSkinEvent = RemoteEvents:FindFirstChild("PurchaseSkin") or Instance.new("RemoteEvent", RemoteEvents)
PurchaseSkinEvent.Name = "PurchaseSkin"
local GetCreditsEvent = RemoteEvents:FindFirstChild("GetCredits") or Instance.new("RemoteEvent", RemoteEvents)
GetCreditsEvent.Name = "GetCredits"

local ShopController = {}

local currentFilter = "All"
local playerCredits = 0
local ownedSkins = {}

-- Skin catalog (temporary, should come from server)
local SKIN_CATALOG = {
	{id = "camo_woodland", name = "Woodland Camo", description = "Classic forest camouflage", price = 250, rarity = "Common", applicableTo = {"Primary", "Secondary"}},
	{id = "camo_desert", name = "Desert Camo", description = "Sandy desert camouflage", price = 250, rarity = "Common", applicableTo = {"Primary", "Secondary"}},
	{id = "black_ops", name = "Black Ops", description = "Tactical matte black finish", price = 300, rarity = "Common", applicableTo = {"Primary", "Secondary", "Melee"}},
	{id = "urban_digital", name = "Urban Digital", description = "Modern digital urban camo", price = 750, rarity = "Uncommon", applicableTo = {"Primary"}},
	{id = "red_tiger", name = "Red Tiger", description = "Aggressive tiger stripe pattern", price = 850, rarity = "Uncommon", applicableTo = {"Primary", "Secondary"}},
	{id = "gold_plated", name = "Gold Plated", description = "Luxurious gold finish", price = 1500, rarity = "Rare", applicableTo = {"Primary", "Secondary", "Melee"}},
	{id = "diamond_crust", name = "Diamond Crust", description = "Sparkling diamond texture", price = 1800, rarity = "Rare", applicableTo = {"Primary", "Secondary"}},
}

function ShopController:Initialize()
	-- Wait for menu to exist
	local mainMenu = playerGui:WaitForChild("FPSMainMenu", 10)
	if not mainMenu then
		warn("FPSMainMenu not found - ShopController cannot initialize")
		return
	end

	-- Find ShopSection
	local contentArea = mainMenu.MainContainer:FindFirstChild("ContentArea")
	if not contentArea then
		warn("ContentArea not found in menu")
		return
	end

	local shopSection = contentArea:WaitForChild("ShopSection", 5)
	if not shopSection then
		warn("ShopSection not found in menu - please create it in Studio")
		return
	end

	-- Request player credits
	GetCreditsEvent:FireServer()
	GetCreditsEvent.OnClientEvent:Connect(function(credits, owned)
		playerCredits = credits or 0
		ownedSkins = owned or {}
		self:UpdateCreditsDisplay(shopSection)
		self:PopulateSkins(shopSection)
	end)

	-- Connect filter buttons
	self:ConnectFilterButtons(shopSection)

	-- Populate skins
	self:PopulateSkins(shopSection)

	-- Update credits display
	self:UpdateCreditsDisplay(shopSection)

	print("✓ ShopController initialized (using menu section)")
end

function ShopController:ConnectFilterButtons(shopSection)
	local filterFrame = shopSection:FindFirstChild("CategoryFilter")
	if not filterFrame then return end

	local filters = {"All", "Primary", "Secondary", "Melee", "Featured"}
	for _, filter in ipairs(filters) do
		local filterBtn = filterFrame:FindFirstChild(filter .. "Filter")
		if filterBtn and filterBtn:IsA("TextButton") then
			filterBtn.MouseButton1Click:Connect(function()
				self:ApplyFilter(shopSection, filter)
			end)
		end
	end
end

function ShopController:ApplyFilter(shopSection, filter)
	currentFilter = filter

	-- Update filter button visuals
	local filterFrame = shopSection:FindFirstChild("CategoryFilter")
	if filterFrame then
		for _, btn in ipairs(filterFrame:GetChildren()) do
			if btn:IsA("TextButton") then
				if btn.Name == filter .. "Filter" then
					btn.BackgroundColor3 = Color3.fromRGB(50, 200, 255)
				else
					btn.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
				end
			end
		end
	end

	-- Repopulate with filter
	self:PopulateSkins(shopSection)

	print("Applied filter:", filter)
end

function ShopController:PopulateSkins(shopSection)
	local skinGrid = shopSection:FindFirstChild("SkinGrid")
	if not skinGrid then return end

	local template = skinGrid:FindFirstChild("SkinTemplate")
	if not template then return end

	-- Clear existing skins (except template)
	for _, child in ipairs(skinGrid:GetChildren()) do
		if not child:IsA("UIGridLayout") and not child:IsA("UIPadding") and child.Name ~= "SkinTemplate" then
			child:Destroy()
		end
	end

	-- Filter skins
	local filteredSkins = {}
	for _, skin in ipairs(SKIN_CATALOG) do
		if currentFilter == "All" or table.find(skin.applicableTo, currentFilter) then
			table.insert(filteredSkins, skin)
		end
	end

	-- Create skin cards
	for _, skin in ipairs(filteredSkins) do
		local skinCard = template:Clone()
		skinCard.Name = skin.id
		skinCard.Visible = true
		skinCard.Parent = skinGrid

		-- Set skin info
		local nameLabel = skinCard:FindFirstChild("SkinName")
		if nameLabel then
			nameLabel.Text = skin.name
		end

		local descLabel = skinCard:FindFirstChild("Description")
		if descLabel then
			descLabel.Text = skin.description
		end

		-- Set rarity badge
		local rarityBadge = skinCard:FindFirstChild("Preview"):FindFirstChild("Rarity")
		if rarityBadge then
			rarityBadge.Text = skin.rarity:upper()
			-- Color based on rarity
			if skin.rarity == "Common" then
				rarityBadge.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
			elseif skin.rarity == "Uncommon" then
				rarityBadge.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			elseif skin.rarity == "Rare" then
				rarityBadge.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
			elseif skin.rarity == "Epic" then
				rarityBadge.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
			elseif skin.rarity == "Legendary" then
				rarityBadge.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
			end
		end

		-- Check if owned
		local isOwned = table.find(ownedSkins, skin.id) ~= nil
		local buyBtn = skinCard:FindFirstChild("BuyButton")
		local ownedLabel = skinCard:FindFirstChild("OwnedLabel")

		if isOwned then
			if buyBtn then buyBtn.Visible = false end
			if ownedLabel then ownedLabel.Visible = true end
		else
			if buyBtn then
				buyBtn.Visible = true
				buyBtn.Text = "BUY - " .. skin.price

				-- Connect purchase
				buyBtn.MouseButton1Click:Connect(function()
					self:PurchaseSkin(shopSection, skin)
				end)
			end
			if ownedLabel then ownedLabel.Visible = false end
		end
	end

	print("✓ Populated", #filteredSkins, "skins with filter:", currentFilter)
end

function ShopController:PurchaseSkin(shopSection, skin)
	if playerCredits < skin.price then
		warn("Not enough credits! Need", skin.price, "but have", playerCredits)
		-- TODO: Show error notification
		return
	end

	-- Request purchase from server
	PurchaseSkinEvent:FireServer(skin.id)

	-- Server will respond via GetCreditsEvent with updated credits/owned skins
	print("Requested purchase of skin:", skin.name)
end

function ShopController:UpdateCreditsDisplay(shopSection)
	local header = shopSection:FindFirstChild("Header")
	if not header then return end

	local creditsDisplay = header:FindFirstChild("CreditsDisplay")
	if not creditsDisplay then return end

	local valueLabel = creditsDisplay:FindFirstChild("Value")
	if valueLabel then
		valueLabel.Text = tostring(playerCredits)
	end
end

-- Initialize
ShopController:Initialize()

return ShopController
