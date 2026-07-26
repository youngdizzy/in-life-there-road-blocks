-- The Feed button and its small food-choice menu. Playing with Pip doesn't
-- need a menu -- it happens by walking up to an Environment Zone in the
-- habitat and pressing the prompt there (server-validated, see
-- InfluenceService.HandlePlayAtZone).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FoodConfig = require(ReplicatedStorage.Config.FoodConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local InteractionUI = {}

local FOOD_ORDER = { "plain_kibble", "spicy_pepper", "kelp_snack", "berry_mix", "mystery_mushroom" }

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function InteractionUI.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InteractionGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local feedButton = Instance.new("TextButton")
	feedButton.AnchorPoint = Vector2.new(1, 1)
	feedButton.Position = UDim2.new(1, -20, 1, -20)
	feedButton.Size = UDim2.fromOffset(160, 54)
	feedButton.BackgroundColor3 = Color3.fromRGB(230, 170, 60)
	feedButton.Text = "Feed Pip"
	feedButton.TextColor3 = Color3.new(1, 1, 1)
	feedButton.Font = Enum.Font.GothamBold
	feedButton.TextScaled = true
	feedButton.Parent = screenGui
	corner(feedButton, 12)

	local hintLabel = Instance.new("TextLabel")
	hintLabel.AnchorPoint = Vector2.new(1, 1)
	hintLabel.Position = UDim2.new(1, -20, 1, -80)
	hintLabel.Size = UDim2.fromOffset(260, 24)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "Walk to a zone and press E to play!"
	hintLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
	hintLabel.TextStrokeTransparency = 0
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.TextScaled = true
	hintLabel.TextXAlignment = Enum.TextXAlignment.Right
	hintLabel.Parent = screenGui

	local menu = Instance.new("Frame")
	menu.AnchorPoint = Vector2.new(0.5, 0.5)
	menu.Position = UDim2.fromScale(0.5, 0.5)
	menu.Size = UDim2.fromOffset(360, 380)
	menu.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	menu.Visible = false
	menu.Parent = screenGui
	corner(menu, 16)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 36)
	title.Position = UDim2.fromOffset(10, 8)
	title.BackgroundTransparency = 1
	title.Text = "What should Pip eat?"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = menu

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(32, 32)
	closeButton.Position = UDim2.new(1, -42, 0, 8)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextScaled = true
	closeButton.Parent = menu
	corner(closeButton, 8)

	local list = Instance.new("Frame")
	list.Position = UDim2.fromOffset(10, 52)
	list.Size = UDim2.new(1, -20, 1, -62)
	list.BackgroundTransparency = 1
	list.Parent = menu

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	for order, foodId in ipairs(FOOD_ORDER) do
		local food = FoodConfig.Get(foodId)

		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, 0, 0, 58)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		row.AutoButtonColor = true
		row.Text = ""
		row.LayoutOrder = order
		row.Parent = list
		corner(row, 8)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -20, 0.55, 0)
		nameLabel.Position = UDim2.fromOffset(14, 4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = food.Name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextScaled = true
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -20, 0.4, 0)
		descLabel.Position = UDim2.new(0, 14, 0.55, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = food.Description
		descLabel.TextColor3 = Color3.fromRGB(190, 190, 195)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextScaled = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = row

		row.MouseButton1Click:Connect(function()
			Remotes.get("FeedCritter"):FireServer(foodId)
			menu.Visible = false
		end)
	end

	feedButton.MouseButton1Click:Connect(function()
		menu.Visible = not menu.Visible
	end)
	closeButton.MouseButton1Click:Connect(function()
		menu.Visible = false
	end)
end

return InteractionUI
