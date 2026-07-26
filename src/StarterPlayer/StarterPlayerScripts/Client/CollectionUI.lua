-- Lists owned Critters and lets the player pick which one is active. The
-- minimum needed to make a second Critter (or Extra Critter Slots) mean
-- anything -- not a full showcase/trading screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local CollectionUI = {}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function CollectionUI.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CollectionGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -290, 0, 20)
	button.Size = UDim2.fromOffset(130, 46)
	button.BackgroundColor3 = Color3.fromRGB(90, 160, 230)
	button.Text = "🐾 Collection"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = screenGui
	corner(button, 10)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -20, 0, 76)
	panel.Size = UDim2.fromOffset(300, 260)
	panel.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	panel.Visible = false
	panel.Parent = screenGui
	corner(panel, 14)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.fromOffset(10, 8)
	title.BackgroundTransparency = 1
	title.Text = "Your Collection"
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

	local function render(collection)
		for _, child in ipairs(list:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end

		for order, entry in ipairs(collection or {}) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 50)
			row.BackgroundColor3 = entry.Active and Color3.fromRGB(60, 90, 130) or Color3.fromRGB(45, 45, 52)
			row.LayoutOrder = order
			row.Parent = list
			corner(row, 8)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, -10, 1, 0)
			nameLabel.Position = UDim2.fromOffset(12, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = ("%s (%s)"):format(entry.Name, entry.Stage)
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextScaled = true
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = row

			if entry.Active then
				local activeLabel = Instance.new("TextLabel")
				activeLabel.Size = UDim2.new(0.35, 0, 1, 0)
				activeLabel.Position = UDim2.new(0.65, 0, 0, 0)
				activeLabel.BackgroundTransparency = 1
				activeLabel.Text = "Active"
				activeLabel.TextColor3 = Color3.fromRGB(140, 220, 255)
				activeLabel.Font = Enum.Font.GothamBold
				activeLabel.TextScaled = true
				activeLabel.Parent = row
			else
				local selectButton = Instance.new("TextButton")
				selectButton.Size = UDim2.new(0.35, -10, 0.7, 0)
				selectButton.Position = UDim2.new(0.65, 0, 0.15, 0)
				selectButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
				selectButton.Text = "Select"
				selectButton.TextColor3 = Color3.new(1, 1, 1)
				selectButton.Font = Enum.Font.GothamBold
				selectButton.TextScaled = true
				selectButton.Parent = row
				corner(selectButton, 6)
				selectButton.MouseButton1Click:Connect(function()
					Remotes.get("SetActiveCritter"):FireServer(entry.Uid)
				end)
			end
		end
	end

	button.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)

	Remotes.get("StateUpdate").OnClientEvent:Connect(function(state)
		render(state.Collection)
	end)
end

return CollectionUI
