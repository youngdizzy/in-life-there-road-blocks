-- Bottom-right toast stack for server messages (steal outcomes, warnings,
-- purchase confirmations, etc).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Modules.Remotes)

local KIND_COLORS = {
	info = Color3.fromRGB(70, 130, 220),
	success = Color3.fromRGB(60, 180, 100),
	warning = Color3.fromRGB(230, 170, 40),
	danger = Color3.fromRGB(220, 70, 70),
}

local Notifications = {}

function Notifications.Init(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NotificationsGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = UDim2.new(1, -20, 1, -20)
	container.Size = UDim2.fromOffset(320, 400)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	Remotes.get("Notify").OnClientEvent:Connect(function(payload)
		local toast = Instance.new("Frame")
		toast.Size = UDim2.new(1, 0, 0, 50)
		toast.BackgroundColor3 = KIND_COLORS[payload.Kind] or KIND_COLORS.info
		toast.BackgroundTransparency = 0.05
		toast.Parent = container

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = toast

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 1, 0)
		label.Position = UDim2.fromOffset(10, 0)
		label.BackgroundTransparency = 1
		label.Text = payload.Text
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextWrapped = true
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Parent = toast

		task.delay(3, function()
			local tween = TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			local labelTween = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 })
			tween:Play()
			labelTween:Play()
			tween.Completed:Wait()
			toast:Destroy()
		end)
	end)
end

return Notifications
