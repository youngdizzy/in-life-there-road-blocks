-- Minimal Mutation Item inventory: see what you own, use one on your
-- active Critter. Selecting *which* Critter is a separate step (see
-- CollectionUI) -- this only ever acts on whichever one is currently active.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MutationItemConfig = require(ReplicatedStorage.Config.MutationItemConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local InventoryUI = {}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function InventoryUI.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -430, 0, 20)
	button.Size = UDim2.fromOffset(130, 46)
	button.BackgroundColor3 = Color3.fromRGB(150, 90, 220)
	button.Text = "🎒 Items"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = screenGui
	corner(button, 10)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -20, 0, 76)
	panel.Size = UDim2.fromOffset(320, 300)
	panel.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	panel.Visible = false
	panel.Parent = screenGui
	corner(panel, 14)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.fromOffset(10, 8)
	title.BackgroundTransparency = 1
	title.Text = "Mutation Items"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(10, 44)
	list.Size = UDim2.new(1, -20, 1, -54)
	list.BackgroundTransparency = 1
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local function render(inventory)
		for _, child in ipairs(list:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end

		inventory = inventory or {}
		local order = 0
		local hasAny = false

		for itemId, quantity in pairs(inventory) do
			local item = MutationItemConfig.Get(itemId)
			if item and quantity > 0 then
				hasAny = true
				order += 1

				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 64)
				row.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
				row.LayoutOrder = order
				row.Parent = list
				corner(row, 8)

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(0.62, -10, 0.5, 0)
				nameLabel.Position = UDim2.fromOffset(12, 4)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = ("%s x%d"):format(item.Name, quantity)
				nameLabel.TextColor3 = Color3.new(1, 1, 1)
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextScaled = true
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Parent = row

				local descLabel = Instance.new("TextLabel")
				descLabel.Size = UDim2.new(0.62, -10, 0.4, 0)
				descLabel.Position = UDim2.new(0, 12, 0.5, 0)
				descLabel.BackgroundTransparency = 1
				descLabel.Text = item.Description
				descLabel.TextColor3 = Color3.fromRGB(190, 190, 195)
				descLabel.TextWrapped = true
				descLabel.Font = Enum.Font.Gotham
				descLabel.TextScaled = true
				descLabel.TextXAlignment = Enum.TextXAlignment.Left
				descLabel.Parent = row

				local useButton = Instance.new("TextButton")
				useButton.Size = UDim2.new(0.3, 0, 0.6, 0)
				useButton.Position = UDim2.new(0.68, 0, 0.2, 0)
				useButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
				useButton.Text = "Use"
				useButton.TextColor3 = Color3.new(1, 1, 1)
				useButton.Font = Enum.Font.GothamBold
				useButton.TextScaled = true
				useButton.Parent = row
				corner(useButton, 6)
				useButton.MouseButton1Click:Connect(function()
					Remotes.get("UseMutationItem"):FireServer(itemId)
				end)
			end
		end

		if not hasAny then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 0, 60)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "No items yet -- Rare Discoveries sometimes find one."
			emptyLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
			emptyLabel.TextWrapped = true
			emptyLabel.Font = Enum.Font.GothamItalic
			emptyLabel.TextScaled = true
			emptyLabel.Parent = list
		end
	end

	button.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)

	Remotes.get("StateUpdate").OnClientEvent:Connect(function(state)
		render(state.Inventory)
	end)
end

return InventoryUI
