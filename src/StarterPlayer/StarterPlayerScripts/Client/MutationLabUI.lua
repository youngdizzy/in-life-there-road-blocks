-- The Mutation Lab panel: a gamepass-gated "Analyze" button that shows a
-- qualitative Influence breakdown. Clicking it without owning the gamepass
-- prompts the purchase instead -- a clear, honest upsell rather than a
-- greyed-out dead button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local MutationLabUI = {}

local INFLUENCE_ORDER = { "Fire", "Water", "Nature", "Shadow" }

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function MutationLabUI.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MutationLabGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -150, 0, 20)
	button.Size = UDim2.fromOffset(120, 46)
	button.BackgroundColor3 = Color3.fromRGB(120, 90, 200)
	button.Text = "🔬 Analyze"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = screenGui
	corner(button, 10)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -20, 0, 76)
	panel.Size = UDim2.fromOffset(280, 220)
	panel.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	panel.Visible = false
	panel.Parent = screenGui
	corner(panel, 14)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.fromOffset(10, 8)
	title.BackgroundTransparency = 1
	title.Text = "Mutation Lab"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local rows = {}
	for i, influenceType in ipairs(INFLUENCE_ORDER) do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, -20, 0, 24)
		row.Position = UDim2.fromOffset(10, 40 + (i - 1) * 26)
		row.BackgroundTransparency = 1
		row.Text = influenceType .. ": --"
		row.TextColor3 = Color3.fromRGB(210, 210, 215)
		row.Font = Enum.Font.Gotham
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = panel
		rows[influenceType] = row
	end

	local footer = Instance.new("TextLabel")
	footer.Size = UDim2.new(1, -20, 0, 40)
	footer.Position = UDim2.fromOffset(10, 150)
	footer.BackgroundTransparency = 1
	footer.Text = ""
	footer.TextColor3 = Color3.fromRGB(160, 160, 165)
	footer.TextWrapped = true
	footer.Font = Enum.Font.GothamItalic
	footer.TextScaled = true
	footer.TextXAlignment = Enum.TextXAlignment.Left
	footer.Parent = panel

	local function refresh()
		local analysis, reason = Remotes.get("GetMutationAnalysis"):InvokeServer()

		if not analysis then
			if reason == "requires_gamepass" then
				panel.Visible = false
				Remotes.get("PromptGamepass"):FireServer("MutationLab")
			end
			return
		end

		panel.Visible = true
		for influenceType, row in pairs(rows) do
			row.Text = ("%s: %s"):format(influenceType, analysis.Breakdown[influenceType])
		end
		footer.Text = analysis.Evolved and "Already evolved."
			or ("Growth: %d%% -- %d rare discoveries found so far."):format(
				analysis.GrowthPercent,
				analysis.DiscoveriesFound
			)
	end

	button.MouseButton1Click:Connect(function()
		if panel.Visible then
			panel.Visible = false
		else
			refresh()
		end
	end)
end

return MutationLabUI
