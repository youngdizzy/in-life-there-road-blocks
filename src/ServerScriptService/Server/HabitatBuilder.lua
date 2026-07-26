-- Procedurally builds the world: baseplate, a spawn pad, and a grid of
-- personal habitats (platform + Pip's pedestal + the four Environment
-- Zone props). Building it in code means there's no binary .rbxl to keep
-- in sync with git -- the whole world lives here as real source.
--
-- v1 habitats are deliberately small and simple (Development Principle #7,
-- GAME_DESIGN.md "Explicitly Not Built Yet" — no big open world). They
-- exist to give Pip a home and a reason to have four Environment Zones,
-- nothing more yet.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HabitatConfig = require(ReplicatedStorage.Config.HabitatConfig)
local EnvironmentConfig = require(ReplicatedStorage.Config.EnvironmentConfig)

local HabitatBuilder = {}

local ZONE_ORDER = { "fire_corner", "water_pool", "nature_patch", "shadow_nook" }
local ZONE_ANGLES = { 45, 135, 225, 315 } -- degrees, spread evenly around the pedestal

local function newPart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		part[key] = value
	end
	return part
end

local function buildPedestal(plotModel, platformCFrame)
	local pedestal = newPart({
		Name = "Pedestal",
		Size = Vector3.new(5, 1, 5),
		Color = Color3.fromRGB(230, 220, 190),
		Material = Enum.Material.Sand,
		CFrame = platformCFrame * CFrame.new(0, 0.5, 0),
		Parent = plotModel,
	})
	return pedestal
end

local function buildZone(plotModel, platformCFrame, zoneId, angleDegrees)
	local zoneConfig = EnvironmentConfig.Get(zoneId)
	local angle = math.rad(angleDegrees)
	local offset = Vector3.new(
		math.cos(angle) * HabitatConfig.ZoneRadius,
		0.5,
		math.sin(angle) * HabitatConfig.ZoneRadius
	)

	local zonePart = newPart({
		Name = zoneId,
		Size = Vector3.new(4, 1, 4),
		Color = zoneConfig.Color,
		Material = Enum.Material.Neon,
		CFrame = platformCFrame * CFrame.new(offset),
		Parent = plotModel,
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ZoneLabel"
	billboard.Size = UDim2.fromOffset(140, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = zonePart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = zoneConfig.Name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlayPrompt"
	prompt.ActionText = "Play"
	prompt.ObjectText = zoneConfig.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = zonePart

	return zonePart
end

local function buildOwnerSign(plotModel, platformCFrame)
	local signPart = newPart({
		Name = "SignPart",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CFrame = platformCFrame * CFrame.new(0, 6, -(HabitatConfig.PlotSize.Y / 2) - 1),
		Parent = plotModel,
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OwnerBillboard"
	billboard.Size = UDim2.fromOffset(220, 50)
	billboard.AlwaysOnTop = true
	billboard.Parent = signPart

	local label = Instance.new("TextLabel")
	label.Name = "OwnerName"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Empty Habitat"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	return signPart
end

function HabitatBuilder.Build()
	local workspace = game:GetService("Workspace")

	local totalWidth = HabitatConfig.GridColumns * (HabitatConfig.PlotSize.X + HabitatConfig.PlotSpacing)
	local totalDepth = HabitatConfig.GridRows * (HabitatConfig.PlotSize.Y + HabitatConfig.PlotSpacing)

	local baseplate = newPart({
		Name = "Baseplate",
		Size = Vector3.new(totalWidth + 60, 4, totalDepth + 100),
		Color = Color3.fromRGB(60, 130, 70),
		Material = Enum.Material.Grass,
		CFrame = CFrame.new(0, -2, 0),
		Parent = workspace,
	})
	baseplate:SetAttribute("IsBaseplate", true)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Color = Color3.fromRGB(160, 160, 160)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.CFrame = CFrame.new(0, 0.5, totalDepth / 2 + 35)
	spawn.Parent = workspace

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Habitats"
	plotsFolder.Parent = workspace

	local plots = {}
	local startX = -(HabitatConfig.GridColumns - 1) * (HabitatConfig.PlotSize.X + HabitatConfig.PlotSpacing) / 2
	local startZ = -(HabitatConfig.GridRows - 1) * (HabitatConfig.PlotSize.Y + HabitatConfig.PlotSpacing) / 2

	local index = 0
	for row = 0, HabitatConfig.GridRows - 1 do
		for col = 0, HabitatConfig.GridColumns - 1 do
			index += 1

			local x = startX + col * (HabitatConfig.PlotSize.X + HabitatConfig.PlotSpacing)
			local z = startZ + row * (HabitatConfig.PlotSize.Y + HabitatConfig.PlotSpacing)
			local platformCFrame = CFrame.new(x, 0, z)

			local plotModel = Instance.new("Folder")
			plotModel.Name = "Habitat" .. index
			plotModel.Parent = plotsFolder

			local platform = newPart({
				Name = "Platform",
				Size = Vector3.new(HabitatConfig.PlotSize.X, 2, HabitatConfig.PlotSize.Y),
				Color = Color3.fromRGB(150, 190, 150),
				Material = Enum.Material.Ground,
				CFrame = platformCFrame,
				Parent = plotModel,
			})

			local pedestal = buildPedestal(plotModel, platformCFrame)

			local zones = {}
			for i, zoneId in ipairs(ZONE_ORDER) do
				zones[zoneId] = buildZone(plotModel, platformCFrame, zoneId, ZONE_ANGLES[i])
			end

			local sign = buildOwnerSign(plotModel, platformCFrame)

			plots[index] = {
				Index = index,
				Model = plotModel,
				Platform = platform,
				Pedestal = pedestal,
				Zones = zones,
				Sign = sign,
				CFrame = platformCFrame,
				OwnerUserId = nil,
			}
		end
	end

	return plots
end

return HabitatBuilder
