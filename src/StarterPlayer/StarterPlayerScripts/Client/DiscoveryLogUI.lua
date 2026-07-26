-- The Bestiary panel: [✓] Name for discovered Critters, [?] ??? for
-- everything else. Small and polished on purpose -- 6 real entries, not a
-- giant catalog (see GAME_DESIGN.md Phase 5: "make the first 5-10 entries
-- feel polished").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local DiscoveryLogUI = {}

local INFLUENCE_COLORS = {
	Fire = Color3.fromRGB(255, 140, 60),
	Water = Color3.fromRGB(90, 170, 230),
	Nature = Color3.fromRGB(110, 190, 90),
	Shadow = Color3.fromRGB(150, 90, 210),
	Secret = Color3.fromRGB(120, 240, 230),
}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function DiscoveryLogUI.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DiscoveryLogGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -570, 0, 20)
	button.Size = UDim2.fromOffset(130, 46)
	button.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
	button.Text = "📖 Bestiary"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = screenGui
	corner(button, 10)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -20, 0, 76)
	panel.Size = UDim2.fromOffset(300, 320)
	panel.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	panel.Visible = false
	panel.Parent = screenGui
	corner(panel, 14)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.fromOffset(10, 8)
	title.BackgroundTransparency = 1
	title.Text = "Bestiary"
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

	local function render(log)
		for _, child in ipairs(list:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end

		for order, entry in ipairs(log or {}) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 44)
			row.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
			row.LayoutOrder = order
			row.Parent = list
			corner(row, 8)

			local markLabel = Instance.new("TextLabel")
			markLabel.Size = UDim2.fromOffset(36, 44)
			markLabel.BackgroundTransparency = 1
			markLabel.Text = entry.Discovered and "✓" or "?"
			markLabel.TextColor3 = entry.Discovered and Color3.fromRGB(120, 230, 140) or Color3.fromRGB(140, 140, 145)
			markLabel.Font = Enum.Font.GothamBlack
			markLabel.TextScaled = true
			markLabel.Parent = row

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -46, 1, 0)
			nameLabel.Position = UDim2.fromOffset(40, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = entry.Discovered and (entry.IsSecret and ("✨ " .. entry.Name) or entry.Name)
				or "??? Undiscovered"
			nameLabel.TextColor3 = entry.Discovered
					and (INFLUENCE_COLORS[entry.DominantInfluence] or Color3.new(1, 1, 1))
				or Color3.fromRGB(140, 140, 145)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextScaled = true
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = row
		end
	end

	button.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)

	Remotes.get("StateUpdate").OnClientEvent:Connect(function(state)
		render(state.DiscoveryLog)
	end)
end

return DiscoveryLogUI
