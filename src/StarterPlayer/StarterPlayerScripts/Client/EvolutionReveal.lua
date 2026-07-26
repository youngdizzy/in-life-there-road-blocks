-- The big "wait... YOURS turned into THAT?" moment. Fired once, by the
-- server, when EvolutionService actually commits an outcome -- this is
-- pure presentation of an already-decided result.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local EvolutionReveal = {}

local INFLUENCE_COLORS = {
	Fire = Color3.fromRGB(255, 140, 60),
	Water = Color3.fromRGB(90, 170, 230),
	Nature = Color3.fromRGB(110, 190, 90),
	Shadow = Color3.fromRGB(150, 90, 210),
	Secret = Color3.fromRGB(120, 240, 230),
}

function EvolutionReveal.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EvolutionRevealGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui

	Remotes.get("EvolutionReveal").OnClientEvent:Connect(function(payload)
		local color = INFLUENCE_COLORS[payload.DominantInfluence] or Color3.new(1, 1, 1)

		local dim = Instance.new("Frame")
		dim.Size = UDim2.fromScale(1, 1)
		dim.BackgroundColor3 = Color3.new(0, 0, 0)
		dim.BackgroundTransparency = 1
		dim.Parent = screenGui
		TweenService:Create(dim, TweenInfo.new(0.4), { BackgroundTransparency = 0.5 }):Play()

		local card = Instance.new("Frame")
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Position = UDim2.fromScale(0.5, 0.42)
		card.Size = UDim2.fromOffset(0, 0)
		card.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
		card.Parent = screenGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 20)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 5
		stroke.Parent = card

		local headline = Instance.new("TextLabel")
		headline.Size = UDim2.new(1, 0, 0.2, 0)
		headline.Position = UDim2.fromScale(0, 0.08)
		headline.BackgroundTransparency = 1
		headline.Text = payload.IsSecret and "?!?! SECRET EVOLUTION !?!?" or "YOUR PIP EVOLVED!"
		headline.TextColor3 = color
		headline.Font = Enum.Font.GothamBlack
		headline.TextScaled = true
		headline.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0.28, 0)
		nameLabel.Position = UDim2.fromScale(0, 0.32)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = payload.Name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.GothamBlack
		nameLabel.TextScaled = true
		nameLabel.Parent = card

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.85, 0, 0.24, 0)
		descLabel.Position = UDim2.fromScale(0.075, 0.62)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = payload.Description
		descLabel.TextColor3 = Color3.fromRGB(210, 210, 215)
		descLabel.TextWrapped = true
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextScaled = true
		descLabel.Parent = card

		local tapLabel = Instance.new("TextLabel")
		tapLabel.Size = UDim2.new(1, 0, 0.12, 0)
		tapLabel.Position = UDim2.fromScale(0, 0.86)
		tapLabel.BackgroundTransparency = 1
		tapLabel.Text = "tap to continue"
		tapLabel.TextColor3 = Color3.fromRGB(150, 150, 155)
		tapLabel.Font = Enum.Font.GothamItalic
		tapLabel.TextScaled = true
		tapLabel.Parent = card

		local openTween = TweenService:Create(
			card,
			TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(420, 300) }
		)
		openTween:Play()

		local dismissed = false
		local function dismiss()
			if dismissed then
				return
			end
			dismissed = true

			local closeTween = TweenService:Create(
				card,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 }
			)
			local dimTween = TweenService:Create(dim, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
			closeTween:Play()
			dimTween:Play()
			closeTween.Completed:Wait()
			card:Destroy()
			dim:Destroy()
		end

		local clickDetector = Instance.new("TextButton")
		clickDetector.Size = UDim2.fromScale(1, 1)
		clickDetector.BackgroundTransparency = 1
		clickDetector.Text = ""
		clickDetector.ZIndex = 5
		clickDetector.Parent = card
		clickDetector.MouseButton1Click:Connect(dismiss)

		task.delay(6, dismiss)
	end)
end

return EvolutionReveal
