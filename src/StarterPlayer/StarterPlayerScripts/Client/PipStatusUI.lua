-- Top-left status panel: name, stage, Hunger/Happiness, and the soft
-- discovery hint. Everything here is a direct readout of the StateUpdate
-- payload -- the client never computes stage or hints itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local PipStatusUI = {}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

local function buildBar(parent, position, fillColor)
	local back = Instance.new("Frame")
	back.Position = position
	back.Size = UDim2.new(1, -20, 0, 14)
	back.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
	back.Parent = parent
	corner(back, 7)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.Parent = back
	corner(fill, 7)

	return fill
end

function PipStatusUI.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PipStatusGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Position = UDim2.fromOffset(16, 16)
	panel.Size = UDim2.fromOffset(300, 240)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	panel.BackgroundTransparency = 0.1
	panel.Parent = screenGui
	corner(panel, 12)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, -20, 0, 28)
	nameLabel.Position = UDim2.fromOffset(10, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Pip"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = panel

	local gemsLabel = Instance.new("TextLabel")
	gemsLabel.Size = UDim2.new(0.4, -20, 0, 28)
	gemsLabel.Position = UDim2.new(0.6, 0, 0, 8)
	gemsLabel.BackgroundTransparency = 1
	gemsLabel.Text = "0 💎"
	gemsLabel.TextColor3 = Color3.fromRGB(180, 150, 255)
	gemsLabel.Font = Enum.Font.GothamBold
	gemsLabel.TextScaled = true
	gemsLabel.TextXAlignment = Enum.TextXAlignment.Right
	gemsLabel.Parent = panel

	local stageLabel = Instance.new("TextLabel")
	stageLabel.Size = UDim2.new(1, -20, 0, 20)
	stageLabel.Position = UDim2.fromOffset(10, 36)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text = "Baby"
	stageLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
	stageLabel.Font = Enum.Font.GothamBold
	stageLabel.TextScaled = true
	stageLabel.TextXAlignment = Enum.TextXAlignment.Left
	stageLabel.Parent = panel

	local growthLabel = Instance.new("TextLabel")
	growthLabel.Size = UDim2.new(1, -20, 0, 16)
	growthLabel.Position = UDim2.fromOffset(10, 60)
	growthLabel.BackgroundTransparency = 1
	growthLabel.Text = "Growth: 0 / 100"
	growthLabel.TextColor3 = Color3.fromRGB(200, 200, 205)
	growthLabel.Font = Enum.Font.Gotham
	growthLabel.TextScaled = true
	growthLabel.TextXAlignment = Enum.TextXAlignment.Left
	growthLabel.Parent = panel

	local hungerLabel = Instance.new("TextLabel")
	hungerLabel.Size = UDim2.new(1, -20, 0, 14)
	hungerLabel.Position = UDim2.fromOffset(10, 82)
	hungerLabel.BackgroundTransparency = 1
	hungerLabel.Text = "Hunger"
	hungerLabel.TextColor3 = Color3.fromRGB(200, 200, 205)
	hungerLabel.Font = Enum.Font.Gotham
	hungerLabel.TextScaled = true
	hungerLabel.TextXAlignment = Enum.TextXAlignment.Left
	hungerLabel.Parent = panel
	local hungerFill = buildBar(panel, UDim2.fromOffset(10, 98), Color3.fromRGB(230, 170, 60))

	local happinessLabel = Instance.new("TextLabel")
	happinessLabel.Size = UDim2.new(1, -20, 0, 14)
	happinessLabel.Position = UDim2.fromOffset(10, 118)
	happinessLabel.BackgroundTransparency = 1
	happinessLabel.Text = "Happiness"
	happinessLabel.TextColor3 = Color3.fromRGB(200, 200, 205)
	happinessLabel.Font = Enum.Font.Gotham
	happinessLabel.TextScaled = true
	happinessLabel.TextXAlignment = Enum.TextXAlignment.Left
	happinessLabel.Parent = panel
	local happinessFill = buildBar(panel, UDim2.fromOffset(10, 134), Color3.fromRGB(230, 100, 150))

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(1, -20, 0, 36)
	hintLabel.Position = UDim2.fromOffset(10, 152)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "Pip's feelings are still a mystery..."
	hintLabel.TextColor3 = Color3.fromRGB(180, 170, 220)
	hintLabel.TextWrapped = true
	hintLabel.Font = Enum.Font.GothamItalic
	hintLabel.TextScaled = true
	hintLabel.TextXAlignment = Enum.TextXAlignment.Left
	hintLabel.Parent = panel

	local boostsLabel = Instance.new("TextLabel")
	boostsLabel.Size = UDim2.new(1, -20, 0, 16)
	boostsLabel.Position = UDim2.fromOffset(10, 190)
	boostsLabel.BackgroundTransparency = 1
	boostsLabel.Text = ""
	boostsLabel.TextColor3 = Color3.fromRGB(140, 220, 255)
	boostsLabel.Font = Enum.Font.GothamBold
	boostsLabel.TextScaled = true
	boostsLabel.TextXAlignment = Enum.TextXAlignment.Left
	boostsLabel.Parent = panel

	local BOOST_LABELS = { GrowthBoost = "⚡ Growth Boost", LuckPotion = "🍀 Luck Potion" }

	local function formatRemaining(seconds)
		local minutes = math.floor(seconds / 60)
		local secs = seconds % 60
		return ("%d:%02d"):format(minutes, secs)
	end

	Remotes.get("StateUpdate").OnClientEvent:Connect(function(state)
		nameLabel.Text = state.Name
		gemsLabel.Text = ("%d 💎"):format(state.Gems or 0)
		stageLabel.Text = state.Evolved and "Evolved!" or state.Stage
		growthLabel.Text = state.Evolved and "Fully grown"
			or ("Growth: %d / %d"):format(state.GrowthPoints, state.GrowthThreshold)
		hungerFill.Size = UDim2.fromScale(math.clamp(state.Hunger / 100, 0, 1), 1)
		happinessFill.Size = UDim2.fromScale(math.clamp(state.Happiness / 100, 0, 1), 1)
		hintLabel.Text = state.Evolved and state.Description or (state.DominantHint or "Pip's feelings are still a mystery...")

		local parts = {}
		for boostType, remaining in pairs(state.ActiveBoosts or {}) do
			table.insert(parts, ("%s %s"):format(BOOST_LABELS[boostType] or boostType, formatRemaining(remaining)))
		end
		boostsLabel.Text = table.concat(parts, "   ")
	end)
end

return PipStatusUI
