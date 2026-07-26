-- The monetization shop: Gamepasses / Boosts / Cosmetics / Currency tabs,
-- plus two honest "coming soon" placeholders for Habitat and Event so the
-- category structure the design calls for is visible without faking
-- purchasable content that doesn't exist yet. Every purchase button fires
-- a request to the server -- nothing here grants anything itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local CosmeticConfig = require(ReplicatedStorage.Config.CosmeticConfig)
local HabitatThemeConfig = require(ReplicatedStorage.Config.HabitatThemeConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local ShopUI = {}

local latestState = nil

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

local function buildRow(parent, layoutOrder, title, description, buttonText, buttonColor, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 66)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	row.LayoutOrder = layoutOrder
	row.Parent = parent
	corner(row, 8)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.62, -10, 0.5, 0)
	titleLabel.Position = UDim2.fromOffset(14, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = row

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.62, -10, 0.5, -6)
	descLabel.Position = UDim2.new(0, 14, 0.5, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Color3.fromRGB(190, 190, 195)
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextScaled = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = row

	if buttonText then
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0.32, 0, 0.7, 0)
		button.Position = UDim2.new(0.66, 0, 0.15, 0)
		button.BackgroundColor3 = buttonColor or Color3.fromRGB(80, 180, 100)
		button.Text = buttonText
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.GothamBold
		button.TextScaled = true
		button.Parent = row
		corner(button, 8)
		if onClick then
			button.MouseButton1Click:Connect(onClick)
		end
	end

	return row
end

local function clearChildren(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function renderGamepasses(list)
	clearChildren(list)
	local order = 0
	for key, cfg in pairs(MonetizationConfig.Gamepasses) do
		order += 1
		local owned = latestState and latestState.OwnedGamepasses and latestState.OwnedGamepasses[key]
		buildRow(
			list,
			order,
			cfg.Name,
			cfg.Description,
			owned and "Owned" or "Buy",
			owned and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(230, 170, 60),
			(not owned) and function()
				Remotes.get("PromptGamepass"):FireServer(key)
			end or nil
		)
	end
end

local function renderBoosts(list)
	clearChildren(list)
	local order = 0
	local keys = { "GrowthBoost15Min", "GrowthBoost1Hour", "LuckPotion30Min" }
	for _, key in ipairs(keys) do
		local cfg = MonetizationConfig.DevProducts[key]
		order += 1
		buildRow(list, order, cfg.Name, "Temporary boost, stacks by extending the timer.", "Buy", nil, function()
			Remotes.get("PromptDevProduct"):FireServer(key)
		end)
	end
end

local function renderCosmetics(list)
	clearChildren(list)
	local order = 0

	local devProductByCosmetic = {}
	for key, cfg in pairs(MonetizationConfig.DevProducts) do
		if cfg.CosmeticId then
			devProductByCosmetic[cfg.CosmeticId] = key
		end
	end

	for id, cfg in pairs(CosmeticConfig.Cosmetics) do
		if cfg.Implemented then
			order += 1
			local unlocked = latestState and latestState.UnlockedCosmetics and latestState.UnlockedCosmetics[id]
			local equipped = latestState and latestState.EquippedCosmetic == id

			if unlocked then
				buildRow(
					list,
					order,
					cfg.Name,
					cfg.Description,
					equipped and "Unequip" or "Equip",
					equipped and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(90, 160, 230),
					function()
						Remotes.get("EquipCosmetic"):FireServer(equipped and nil or id)
					end
				)
			else
				local productKey = devProductByCosmetic[id]
				buildRow(
					list,
					order,
					cfg.Name,
					cfg.Description,
					productKey and "Buy" or nil,
					Color3.fromRGB(230, 170, 60),
					productKey and function()
						Remotes.get("PromptDevProduct"):FireServer(productKey)
					end or nil
				)
			end
		end
	end
end

local function renderCurrency(list)
	clearChildren(list)
	local order = 0
	local keys = { "GemsSmall", "GemsMedium", "GemsLarge" }
	for _, key in ipairs(keys) do
		local cfg = MonetizationConfig.DevProducts[key]
		order += 1
		buildRow(list, order, cfg.Name, ("%d Gems"):format(cfg.Gems), "Buy", nil, function()
			Remotes.get("PromptDevProduct"):FireServer(key)
		end)
	end
end

local function renderEmptyNote(list, text)
	clearChildren(list)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 60)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(160, 160, 165)
	label.Font = Enum.Font.GothamItalic
	label.TextScaled = true
	label.Parent = list
end

local function renderHabitat(list)
	clearChildren(list)
	local order = 0
	local available = {}
	if latestState and latestState.AvailableHabitatThemes then
		for _, theme in ipairs(latestState.AvailableHabitatThemes) do
			available[theme.Id] = true
		end
	end

	for id, cfg in pairs(HabitatThemeConfig.Themes) do
		if cfg.Implemented then
			order += 1
			local owned = available[id]
			local selected = latestState and latestState.SelectedHabitatTheme == id

			if owned then
				buildRow(
					list,
					order,
					cfg.Name,
					selected and "Currently selected." or "Tap to display this theme on your habitat.",
					selected and "Selected" or "Select",
					selected and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(90, 160, 230),
					(not selected) and function()
						Remotes.get("SelectHabitatTheme"):FireServer(id)
					end or nil
				)
			else
				buildRow(
					list,
					order,
					cfg.Name,
					("Requires the %s gamepass."):format(
						cfg.RequiresGamepass and MonetizationConfig.Gamepasses[cfg.RequiresGamepass].Name or "?"
					),
					"Get it",
					Color3.fromRGB(230, 170, 60),
					cfg.RequiresGamepass and function()
						Remotes.get("PromptGamepass"):FireServer(cfg.RequiresGamepass)
					end or nil
				)
			end
		end
	end
end

local function renderEvent(list)
	local events = latestState and latestState.ActiveEvents or {}
	if #events == 0 then
		renderEmptyNote(list, "No event is running right now.")
		return
	end

	clearChildren(list)
	for order, event in ipairs(events) do
		buildRow(
			list,
			order,
			event.Name,
			event.Description,
			event.Claimed and "Claimed" or "Claim Reward",
			event.Claimed and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(80, 180, 100),
			(not event.Claimed) and function()
				Remotes.get("ClaimEventReward"):FireServer(event.Id)
			end or nil
		)
	end
end

function ShopUI.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local shopButton = Instance.new("TextButton")
	shopButton.AnchorPoint = Vector2.new(1, 0)
	shopButton.Position = UDim2.new(1, -20, 0, 20)
	shopButton.Size = UDim2.fromOffset(120, 46)
	shopButton.BackgroundColor3 = Color3.fromRGB(230, 170, 60)
	shopButton.Text = "Shop"
	shopButton.TextColor3 = Color3.new(1, 1, 1)
	shopButton.Font = Enum.Font.GothamBold
	shopButton.TextScaled = true
	shopButton.Parent = screenGui
	corner(shopButton, 10)

	local shopFrame = Instance.new("Frame")
	shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	shopFrame.Position = UDim2.fromScale(0.5, 0.5)
	shopFrame.Size = UDim2.fromOffset(460, 540)
	shopFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	shopFrame.Visible = false
	shopFrame.Parent = screenGui
	corner(shopFrame, 16)

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(36, 36)
	closeButton.Position = UDim2.new(1, -46, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextScaled = true
	closeButton.Parent = shopFrame
	corner(closeButton, 8)
	closeButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = false
	end)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 36)
	title.Position = UDim2.fromOffset(10, 8)
	title.BackgroundTransparency = 1
	title.Text = "Shop"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = shopFrame

	local tabBar = Instance.new("Frame")
	tabBar.Position = UDim2.fromOffset(10, 46)
	tabBar.Size = UDim2.new(1, -20, 0, 34)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = shopFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.Parent = tabBar

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(10, 88)
	list.Size = UDim2.new(1, -20, 1, -98)
	list.BackgroundTransparency = 1
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.Parent = shopFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	local tabs = {
		{ Name = "Gamepasses", Render = renderGamepasses },
		{ Name = "Boosts", Render = renderBoosts },
		{ Name = "Cosmetics", Render = renderCosmetics },
		{ Name = "Currency", Render = renderCurrency },
		{ Name = "Habitat", Render = renderHabitat },
		{ Name = "Event", Render = renderEvent },
	}

	local tabButtons = {}
	local activeTab = tabs[1]

	local function selectTab(tab)
		activeTab = tab
		for _, t in ipairs(tabs) do
			tabButtons[t.Name].BackgroundColor3 = (t == tab) and Color3.fromRGB(230, 170, 60)
				or Color3.fromRGB(50, 50, 58)
		end
		tab.Render(list)
	end

	for _, tab in ipairs(tabs) do
		local tabButton = Instance.new("TextButton")
		tabButton.Size = UDim2.fromOffset(72, 34)
		tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
		tabButton.Text = tab.Name
		tabButton.TextColor3 = Color3.new(1, 1, 1)
		tabButton.Font = Enum.Font.GothamBold
		tabButton.TextScaled = true
		tabButton.Parent = tabBar
		corner(tabButton, 6)
		tabButtons[tab.Name] = tabButton
		tabButton.MouseButton1Click:Connect(function()
			selectTab(tab)
		end)
	end

	shopButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = not shopFrame.Visible
		if shopFrame.Visible then
			selectTab(activeTab)
		end
	end)

	Remotes.get("StateUpdate").OnClientEvent:Connect(function(state)
		latestState = state
		if shopFrame.Visible then
			activeTab.Render(list)
		end
	end)
end

return ShopUI
