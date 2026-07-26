-- A small always-visible checklist under the status panel, so "what can I
-- do next" never requires opening a menu (see GAME_DESIGN.md Phase 9).
-- Collapsible (click the header) for players who don't want it up, but
-- shown by default.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local GoalsUI = {}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function GoalsUI.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GoalsGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Position = UDim2.fromOffset(16, 264)
	panel.Size = UDim2.fromOffset(300, 30)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	panel.BackgroundTransparency = 0.1
	panel.ClipsDescendants = true
	panel.Parent = screenGui
	corner(panel, 12)

	local header = Instance.new("TextButton")
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.Text = "▾ Goals"
	header.TextColor3 = Color3.fromRGB(220, 220, 225)
	header.Font = Enum.Font.GothamBold
	header.TextScaled = true
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = panel

	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingLeft = UDim.new(0, 10)
	headerPadding.Parent = header

	local list = Instance.new("Frame")
	list.Position = UDim2.fromOffset(10, 32)
	list.Size = UDim2.new(1, -20, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.BackgroundTransparency = 1
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local expanded = true
	local function updateHeight()
		if not expanded then
			panel.Size = UDim2.fromOffset(300, 30)
			return
		end
		panel.Size = UDim2.fromOffset(300, 38 + list.AbsoluteSize.Y)
	end

	list:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateHeight)

	header.MouseButton1Click:Connect(function()
		expanded = not expanded
		header.Text = (expanded and "▾" or "▸") .. " Goals"
		updateHeight()
	end)

	local function render(goals)
		for _, child in ipairs(list:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end

		for order, goal in ipairs(goals or {}) do
			local row = Instance.new("TextLabel")
			row.Size = UDim2.new(1, 0, 0, 18)
			row.LayoutOrder = order
			row.BackgroundTransparency = 1
			row.Text = (goal.Done and "✅ " or "⬜ ") .. goal.Text
			row.TextColor3 = goal.Done and Color3.fromRGB(120, 220, 140) or Color3.fromRGB(210, 210, 215)
			row.Font = Enum.Font.Gotham
			row.TextScaled = true
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Parent = list
		end

		updateHeight()
	end

	Remotes.get("StateUpdate").OnClientEvent:Connect(function(state)
		render(state.Goals)
	end)
end

return GoalsUI
