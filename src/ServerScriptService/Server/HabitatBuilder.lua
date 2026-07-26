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

-- Global lighting/atmosphere tuning -- entirely property values and two
-- procedural instances (Atmosphere, ColorCorrection), zero external asset
-- Ids, so nothing here can ever render as a broken/missing texture. This
-- is the single highest-impact, lowest-risk visual change available in
-- this environment: Roblox's own default Lighting is intentionally flat,
-- and a "polished Roblox game" reads as such mostly through grading, not
-- geometry. Future = nicer soft lighting than the default ShadowMap
-- technology, at some GPU cost; revisit if this ever needs to run well on
-- low-end/mobile devices.
local function configureLighting()
	local Lighting = game:GetService("Lighting")

	Lighting.Technology = Enum.Technology.Future
	Lighting.Brightness = 2.5
	Lighting.ClockTime = 14.5
	Lighting.GeographicLatitude = 30
	Lighting.Ambient = Color3.fromRGB(95, 100, 115)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 125, 130)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 244, 224)
	Lighting.ColorShift_Bottom = Color3.fromRGB(205, 215, 235)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(199, 199, 199)
	atmosphere.Decay = Color3.fromRGB(110, 120, 140)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1.1
	atmosphere.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "WorldGrade"
	colorCorrection.Brightness = 0.02
	colorCorrection.Contrast = 0.08
	colorCorrection.Saturation = 0.14
	colorCorrection.TintColor = Color3.fromRGB(255, 250, 244)
	colorCorrection.Parent = Lighting
end

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

-- A single, small "welcome mat" under the pedestal -- one deliberate touch
-- of coziness, not a decorating system. Sits flush with the platform so it
-- reads as a rug, not another step.
local function buildPedestal(plotModel, platformCFrame)
	newPart({
		Name = "Rug",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.1, 7, 7),
		Color = Color3.fromRGB(200, 110, 90),
		Material = Enum.Material.Fabric,
		CanCollide = false,
		CFrame = platformCFrame * CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = plotModel,
	})

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

-- Turns each Environment Zone from a flat colored pad into a small themed
-- landmark -- logs and embers, pool rocks, a cluster of bushes and
-- flowers, a shadowy rock nook -- so it reads as "a place," not a tile.
-- Kept sparing (a handful of parts + one ambient particle per zone) on
-- purpose, per "do not fill the map with random decorations that have no
-- purpose": every prop here belongs to the one zone it's decorating.
local function buildZoneDecoration(plotModel, zonePart, zoneId)
	if zoneId == "fire_corner" then
		for i = 1, 3 do
			local angle = math.rad(i * 70)
			local log = newPart({
				Name = "Log" .. i,
				Size = Vector3.new(0.5, 0.5, 2.6),
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(92, 62, 42),
				CanCollide = false,
				CFrame = zonePart.CFrame * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, angle, math.rad(18)),
				Parent = plotModel,
			})
		end

		local emberLight = Instance.new("PointLight")
		emberLight.Color = Color3.fromRGB(255, 150, 60)
		emberLight.Range = 14
		emberLight.Brightness = 2.5
		emberLight.Parent = zonePart

		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 170, 70))
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(0.8, 1.4)
		emitter.Speed = NumberRange.new(2, 4)
		emitter.Acceleration = Vector3.new(0, 6, 0)
		emitter.SpreadAngle = Vector2.new(20, 20)
		emitter.Rate = 6
		emitter.Parent = zonePart
	elseif zoneId == "water_pool" then
		for i = 1, 6 do
			local angle = math.rad(i * 60)
			newPart({
				Name = "PoolRock" .. i,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.9, 0.7, 0.9),
				Material = Enum.Material.Slate,
				Color = Color3.fromRGB(120, 120, 125),
				CanCollide = false,
				CFrame = zonePart.CFrame * CFrame.new(math.cos(angle) * 2.6, 0, math.sin(angle) * 2.6),
				Parent = plotModel,
			})
		end

		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(Color3.fromRGB(210, 235, 250))
		emitter.Size =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.05) })
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(1, 1.8)
		emitter.Speed = NumberRange.new(0.5, 1)
		emitter.Acceleration = Vector3.new(0, 2, 0)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Rate = 4
		emitter.Parent = zonePart
	elseif zoneId == "nature_patch" then
		for i = 1, 3 do
			local angle = math.rad(i * 110)
			newPart({
				Name = "Bush" .. i,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.4, 1.2, 1.4),
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(70, 130, 60),
				CanCollide = false,
				CFrame = zonePart.CFrame * CFrame.new(math.cos(angle) * 2.4, 0.4, math.sin(angle) * 2.4),
				Parent = plotModel,
			})
		end

		for i = 1, 2 do
			local angle = math.rad(i * 160 + 40)
			local stem = newPart({
				Name = "FlowerStem" .. i,
				Size = Vector3.new(0.15, 1, 0.15),
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(80, 140, 70),
				CanCollide = false,
				CFrame = zonePart.CFrame * CFrame.new(math.cos(angle) * 2, 0.5, math.sin(angle) * 2),
				Parent = plotModel,
			})

			newPart({
				Name = "FlowerBloom" .. i,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.5, 0.5, 0.5),
				Material = Enum.Material.Neon,
				Color = i == 1 and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(240, 140, 190),
				CanCollide = false,
				CFrame = stem.CFrame * CFrame.new(0, 0.6, 0),
				Parent = plotModel,
			})
		end

		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(Color3.fromRGB(180, 230, 150))
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(1.4, 2.2)
		emitter.Speed = NumberRange.new(0.3, 0.7)
		emitter.Acceleration = Vector3.new(0, -0.5, 0)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Rate = 3
		emitter.Parent = zonePart
	elseif zoneId == "shadow_nook" then
		for i = 1, 2 do
			local side = i == 1 and -1 or 1
			newPart({
				Name = "NookRock" .. i,
				Shape = Enum.PartType.Block,
				Size = Vector3.new(1, 2.4, 1.6),
				Material = Enum.Material.Slate,
				Color = Color3.fromRGB(45, 42, 55),
				CanCollide = false,
				CFrame = zonePart.CFrame * CFrame.new(side * 2, 1, -0.5) * CFrame.Angles(0, math.rad(side * 20), 0),
				Parent = plotModel,
			})
		end

		local glowLight = Instance.new("PointLight")
		glowLight.Color = Color3.fromRGB(160, 100, 220)
		glowLight.Range = 12
		glowLight.Brightness = 1.5
		glowLight.Parent = zonePart

		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(Color3.fromRGB(140, 100, 200))
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(1.2, 2)
		emitter.Speed = NumberRange.new(0.5, 1)
		emitter.Acceleration = Vector3.new(0, 1.5, 0)
		emitter.SpreadAngle = Vector2.new(30, 30)
		emitter.Rate = 3
		emitter.Parent = zonePart
	end
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
	label.Text = zoneConfig.Icon and (zoneConfig.Icon .. " " .. zoneConfig.Name) or zoneConfig.Name
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

	buildZoneDecoration(plotModel, zonePart, zoneId)

	return zonePart
end

-- A low perimeter fence around the platform edge -- just enough that a
-- habitat reads as "this is MY space" (see GAME_DESIGN.md Phase 6), not a
-- decorating system. Non-collide so it never blocks the player or the
-- Environment Zones (which sit well inside it).
local FENCE_HEIGHT = 1.5
local FENCE_THICKNESS = 0.4

local function buildPerimeterFence(plotModel, platformCFrame)
	local halfX = HabitatConfig.PlotSize.X / 2
	local halfZ = HabitatConfig.PlotSize.Y / 2
	local railY = 1 + FENCE_HEIGHT / 2 -- platform top (Size.Y/2 = 1) plus half the fence's own height

	local rails = {
		{ Size = Vector3.new(HabitatConfig.PlotSize.X, FENCE_HEIGHT, FENCE_THICKNESS), Offset = CFrame.new(0, railY, halfZ) },
		{
			Size = Vector3.new(HabitatConfig.PlotSize.X, FENCE_HEIGHT, FENCE_THICKNESS),
			Offset = CFrame.new(0, railY, -halfZ),
		},
		{ Size = Vector3.new(FENCE_THICKNESS, FENCE_HEIGHT, HabitatConfig.PlotSize.Y), Offset = CFrame.new(halfX, railY, 0) },
		{
			Size = Vector3.new(FENCE_THICKNESS, FENCE_HEIGHT, HabitatConfig.PlotSize.Y),
			Offset = CFrame.new(-halfX, railY, 0),
		},
	}

	for i, rail in ipairs(rails) do
		newPart({
			Name = "FenceRail" .. i,
			Size = rail.Size,
			Color = Color3.fromRGB(120, 90, 60),
			Material = Enum.Material.WoodPlanks,
			CanCollide = false,
			CFrame = platformCFrame * rail.Offset,
			Parent = plotModel,
		})
	end
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

	configureLighting()

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

			buildPerimeterFence(plotModel, platformCFrame)
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
