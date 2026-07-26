-- Assigns/releases habitats to players and teleports them home. Depends on
-- HabitatBuilder having already run so `plots` is populated.

local HabitatManager = {}

local plots = {}
local ownerToIndex = {}
local freeIndices = {}

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

	updateSign(plot, "Empty Habitat")
	plot.OwnerUserId = nil
	ownerToIndex[player.UserId] = nil
	table.insert(freeIndices, index)
end

return HabitatManager
