-- Assigns/releases habitats to players and teleports them home. Depends on
-- HabitatBuilder having already run so `plots` is populated.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HabitatConfig = require(ReplicatedStorage.Config.HabitatConfig)

local HabitatManager = {}

local plots = {}
local ownerToIndex = {}
local freeIndices = {}

local VIP_COLOR = Color3.fromRGB(255, 215, 60)

function HabitatManager.Init(builtPlots)
	plots = builtPlots
	for index in ipairs(plots) do
		table.insert(freeIndices, index)
	end
end

function HabitatManager.GetHabitat(index)
	return plots[index]
end

function HabitatManager.GetAllHabitats()
	return plots
end

function HabitatManager.GetHabitatIndexForOwner(userId)
	return ownerToIndex[userId]
end

function HabitatManager.GetHabitatForOwner(userId)
	local index = ownerToIndex[userId]
	return index and plots[index] or nil
end

local function updateSign(plot, text)
	local label = plot.Sign.OwnerBillboard:FindFirstChild("OwnerName")
	if label then
		label.Text = text
	end
end

-- Purely cosmetic status signal for the VIP Habitat gamepass (see
-- MonetizationConfig.Gamepasses.VIPHabitat) -- four glowing corner posts
-- plus a badge on the owner sign. Idempotent (safe to call every join) and
-- always cleared on release so the *next* owner of this habitat slot
-- doesn't inherit someone else's VIP glow.
function HabitatManager.ApplyVIPVisual(plot)
	if not plot or plot.Model:GetAttribute("VIPApplied") then
		return
	end
	plot.Model:SetAttribute("VIPApplied", true)

	local halfX = HabitatConfig.PlotSize.X / 2
	local halfZ = HabitatConfig.PlotSize.Y / 2
	local corners = {
		Vector3.new(halfX, 0, halfZ),
		Vector3.new(-halfX, 0, halfZ),
		Vector3.new(halfX, 0, -halfZ),
		Vector3.new(-halfX, 0, -halfZ),
	}

	for i, offset in ipairs(corners) do
		local post = Instance.new("Part")
		post.Name = "VIPPost" .. i
		post.Anchored = true
		post.CanCollide = false
		post.Material = Enum.Material.Neon
		post.Color = VIP_COLOR
		post.Size = Vector3.new(0.6, 6, 0.6)
		post.CFrame = plot.CFrame * CFrame.new(offset.X, 3, offset.Z)
		post.Parent = plot.Model

		local light = Instance.new("PointLight")
		light.Color = VIP_COLOR
		light.Brightness = 2
		light.Range = 12
		light.Parent = post
	end

	local badge = Instance.new("BillboardGui")
	badge.Name = "VIPBadge"
	badge.Size = UDim2.fromOffset(180, 34)
	badge.StudsOffset = Vector3.new(0, 1.4, 0)
	badge.AlwaysOnTop = true
	badge.Parent = plot.Sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "⭐ VIP HABITAT ⭐"
	label.TextColor3 = VIP_COLOR
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = badge
end

function HabitatManager.ClearVIPVisual(plot)
	if not plot or not plot.Model:GetAttribute("VIPApplied") then
		return
	end
	plot.Model:SetAttribute("VIPApplied", false)

	for _, child in ipairs(plot.Model:GetChildren()) do
		if child.Name:match("^VIPPost") then
			child:Destroy()
		end
	end

	local badge = plot.Sign:FindFirstChild("VIPBadge")
	if badge then
		badge:Destroy()
	end
end

local function teleportToHabitat(player, plot)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	root.CFrame = plot.CFrame * CFrame.new(0, 5, 12)
end

-- Reassigns a previously-saved habitat if one is still free at that index,
-- otherwise hands out any free habitat. Keeping the same index across
-- sessions is a nice-to-have (same spot every time), not a guarantee.
function HabitatManager.AssignHabitat(player, preferredIndex)
	local index = nil
	if preferredIndex then
		for i, freeIndex in ipairs(freeIndices) do
			if freeIndex == preferredIndex then
				table.remove(freeIndices, i)
				index = preferredIndex
				break
			end
		end
	end
	if not index then
		index = table.remove(freeIndices)
	end
	if not index then
		warn("HabitatManager: no free habitats available for", player.Name)
		return nil
	end

	local plot = plots[index]
	plot.OwnerUserId = player.UserId
	ownerToIndex[player.UserId] = index
	updateSign(plot, player.Name .. "'s Habitat")

	if player.Character then
		teleportToHabitat(player, plot)
	end
	local conn
	conn = player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart")
		task.wait(0.1)
		if ownerToIndex[player.UserId] == index then
			root.CFrame = plot.CFrame * CFrame.new(0, 5, 12)
		end
	end)
	plot.CharacterAddedConn = conn

	return plot
end

function HabitatManager.ReleaseHabitat(player, onClear)
	local index = ownerToIndex[player.UserId]
	if not index then
		return
	end

	local plot = plots[index]
	if plot.CharacterAddedConn then
		plot.CharacterAddedConn:Disconnect()
		plot.CharacterAddedConn = nil
	end

	if onClear then
		onClear(plot)
	end

	HabitatManager.ClearVIPVisual(plot)
	updateSign(plot, "Empty Habitat")
	plot.OwnerUserId = nil
	ownerToIndex[player.UserId] = nil
	table.insert(freeIndices, index)
end

return HabitatManager
