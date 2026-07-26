-- Builds the shared overworld: the Meadow hub, the paths radiating out of
-- it, the four public Environment Zones (each now a real destination with
-- its own landmark instead of a private pad per habitat), the Critter
-- Archive, the Critter Plaza, and the Evolution Sanctum. HabitatBuilder
-- still owns the player-neighborhood grid; this is everything else players
-- share. See WorldConfig for the coordinates every function here reads.
--
-- Same ground rule as HabitatBuilder: every prop is a plain Roblox Part
-- built at runtime, no imported meshes, no external asset/texture Ids --
-- see GAME_DESIGN.md "Placeholder Art Policy".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig = require(ReplicatedStorage.Config.WorldConfig)
local EnvironmentConfig = require(ReplicatedStorage.Config.EnvironmentConfig)
local PartUtil = require(ReplicatedStorage.Modules.PartUtil)

local WorldBuilder = {}

local newPart = PartUtil.new

-- Global lighting/atmosphere grade -- property values and two procedural
-- instances only, zero external asset Ids (see the visual-pass note in
-- HabitatBuilder's git history for why this lives in code, not a synced
-- Lighting service in Studio).
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

-- A flat circular ground patch -- a Cylinder part rotated so its round face
-- lies flat, top surface at Y=0. Cheaper and cleaner-silhouetted than a
-- rectangular pad for a "themed biome" area, and one part instead of a
-- terrain region.
local function buildGroundDisc(name, center, diameter, color, material, parent)
	return newPart({
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, diameter, diameter),
		CFrame = CFrame.new(center.X, -2, center.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
		Parent = parent,
	})
end

-- A straight walking path between two ground points -- orientation doesn't
-- care which end is "front" since the part is symmetric along its length.
local function buildPath(fromPoint, toPoint, width, parent)
	local length = (toPoint - fromPoint).Magnitude
	local mid = fromPoint + (toPoint - fromPoint) / 2
	return newPart({
		Name = "Path",
		Size = Vector3.new(width, 0.6, length),
		CFrame = CFrame.new(mid, Vector3.new(toPoint.X, mid.Y, toPoint.Z)),
		Color = Color3.fromRGB(214, 196, 160),
		Material = Enum.Material.Sand,
		CanCollide = false,
		Parent = parent,
	})
end

local function buildSpawn(parent)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Color = Color3.fromRGB(235, 225, 200)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.CFrame = CFrame.new(WorldConfig.SpawnPosition)
	spawn.Parent = parent
	return spawn
end

-- ==========================================================================
-- THE MEADOW: Critter Tree, meeting ring, compass sign
-- ==========================================================================

-- The central landmark. Not just decoration -- see the ProximityPrompt at
-- the base: it's a real, labeled hook for "the Tree matters" that future
-- work (Discoveries/Evolution/Events/world lore) can attach real behavior
-- to, without this build having to invent what that behavior is yet.
local function buildCritterTree(parent)
	local base = WorldConfig.CritterTreePosition
	local model = Instance.new("Model")
	model.Name = "CritterTree"
	model.Parent = parent

	-- Root flare + trunk, tapering upward across a few stacked segments.
	for i, ring in ipairs({
		{ y = 1, radius = 5.5 },
		{ y = 7, radius = 4.4 },
		{ y = 14, radius = 3.4 },
		{ y = 20, radius = 2.6 },
	}) do
		newPart({
			Name = "TrunkSegment" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(8, ring.radius * 2, ring.radius * 2),
			CFrame = CFrame.new(base + Vector3.new(0, ring.y, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(96, 66, 46),
			Material = Enum.Material.Wood,
			Parent = model,
		})
	end

	-- Canopy: several big overlapping leaf-balls, two greens for depth.
	local canopyPuffs = {
		{ offset = Vector3.new(0, 30, 0), size = 22, color = Color3.fromRGB(96, 176, 84) },
		{ offset = Vector3.new(11, 26, 6), size = 16, color = Color3.fromRGB(112, 190, 92) },
		{ offset = Vector3.new(-11, 26, -4), size = 16, color = Color3.fromRGB(112, 190, 92) },
		{ offset = Vector3.new(6, 24, -12), size = 15, color = Color3.fromRGB(84, 160, 76) },
		{ offset = Vector3.new(-8, 23, 11), size = 15, color = Color3.fromRGB(84, 160, 76) },
		{ offset = Vector3.new(0, 20, 15), size = 13, color = Color3.fromRGB(126, 200, 100) },
	}
	for i, puff in ipairs(canopyPuffs) do
		newPart({
			Name = "Canopy" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(puff.size, puff.size * 0.85, puff.size),
			CFrame = CFrame.new(base + puff.offset),
			Color = puff.color,
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = model,
		})
	end

	-- Five small glowing orbs (the four Influences + a warm starter gold) --
	-- a visual promise of what the Tree will one day be wired to, not a
	-- working system yet.
	local orbColors = {
		Color3.fromRGB(255, 210, 90),
		Color3.fromRGB(255, 140, 60),
		Color3.fromRGB(90, 170, 230),
		Color3.fromRGB(110, 190, 90),
		Color3.fromRGB(150, 90, 210),
	}
	for i, color in ipairs(orbColors) do
		local angle = math.rad((i - 1) * 72)
		local orbPos = base + Vector3.new(math.cos(angle) * 14, 25, math.sin(angle) * 14)
		local vine = newPart({
			Name = "Vine" .. i,
			Size = Vector3.new(0.3, 5, 0.3),
			CFrame = CFrame.new(orbPos + Vector3.new(0, 2.5, 0)),
			Color = Color3.fromRGB(70, 110, 60),
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = model,
		})
		local orb = newPart({
			Name = "Orb" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.6, 1.6, 1.6),
			CFrame = CFrame.new(orbPos),
			Color = color,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 10
		light.Brightness = 1.5
		light.Parent = orb
	end

	local promptPart = newPart({
		Name = "TreePrompt",
		Size = Vector3.new(2, 2, 2),
		Transparency = 1,
		CanCollide = false,
		CFrame = CFrame.new(base + Vector3.new(0, 3, -6)),
		Parent = model,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TreePrompt"
	prompt.ActionText = "Listen"
	prompt.ObjectText = "The Critter Tree"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 40)
	billboard.StudsOffset = Vector3.new(0, 38, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = model.TrunkSegment1
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "🌳 The Critter Tree"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	return model, promptPart
end

-- A ring of low benches around the Tree -- "a place where players
-- naturally meet," not a functional system.
local function buildMeetingRing(center, radius, count, parent)
	for i = 1, count do
		local angle = math.rad((i - 1) * (360 / count))
		local pos = center + Vector3.new(math.cos(angle) * radius, 0.9, math.sin(angle) * radius)
		newPart({
			Name = "Bench" .. i,
			Size = Vector3.new(4.5, 1.4, 1.6),
			CFrame = CFrame.new(pos) * CFrame.Angles(0, -angle, 0),
			Color = Color3.fromRGB(150, 110, 75),
			Material = Enum.Material.WoodPlanks,
			Parent = parent,
		})
	end
end

-- A single signpost near spawn listing every destination -- the map's own
-- answer to "a player should not feel lost."
local function buildCompassSign(parent)
	local pos = WorldConfig.SpawnPosition + Vector3.new(9, 0, -6)
	local post = newPart({
		Name = "CompassPost",
		Size = Vector3.new(0.6, 7, 0.6),
		CFrame = CFrame.new(pos.X, 3.5, pos.Z),
		Color = Color3.fromRGB(120, 90, 60),
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
	local board = newPart({
		Name = "CompassBoard",
		Size = Vector3.new(5, 3.4, 0.3),
		CFrame = CFrame.new(pos.X, 6, pos.Z) * CFrame.Angles(0, math.rad(20), 0),
		Color = Color3.fromRGB(200, 175, 135),
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(210, 150)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = table.concat({
		"WHERE TO EXPLORE",
		"🌿 Verdant Wilds -- southwest",
		"🔥 Ember Zone -- west",
		"💧 Tidepool -- east",
		"🌑 Gloom Grove -- north",
		"✨ Evolution Sanctum -- southeast",
		"🏠 Habitats -- south",
	}, "\n")
	label.Parent = billboard
	return post
end

-- ==========================================================================
-- THE CRITTER ARCHIVE + THE CRITTER PLAZA
-- ==========================================================================

local function buildArchive(parent)
	local base = WorldConfig.ArchivePosition
	local model = Instance.new("Model")
	model.Name = "CritterArchive"
	model.Parent = parent

	newPart({
		Name = "Wall",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(11, 22, 22),
		CFrame = CFrame.new(base + Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(228, 222, 205),
		Material = Enum.Material.Marble,
		Parent = model,
	})
	newPart({
		Name = "Roof",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(23, 13, 23),
		CFrame = CFrame.new(base + Vector3.new(0, 11, 0)),
		Color = Color3.fromRGB(70, 120, 130),
		Material = Enum.Material.Slate,
		CanCollide = false,
		Parent = model,
	})
	newPart({
		Name = "RoofCap",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.6, 3.4, 2.6),
		CFrame = CFrame.new(base + Vector3.new(0, 17.5, 0)),
		Color = Color3.fromRGB(255, 210, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})

	-- Two "undiscovered silhouette" pedestals out front -- a physical
	-- pointer at the Bestiary concept (see DiscoveryLogService), not a
	-- second copy of that data.
	for i = 1, 2 do
		local side = i == 1 and -1 or 1
		local pedPos = base + Vector3.new(side * 7, 0, 13)
		newPart({
			Name = "SilhouettePedestal" .. i,
			Size = Vector3.new(3, 2, 3),
			CFrame = CFrame.new(pedPos),
			Color = Color3.fromRGB(200, 195, 180),
			Material = Enum.Material.Marble,
			Parent = model,
		})
		newPart({
			Name = "Silhouette" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.6, 2.6, 3),
			CFrame = CFrame.new(pedPos + Vector3.new(0, 2.6, 0)),
			Color = Color3.fromRGB(18, 18, 22),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.15,
			CanCollide = false,
			Parent = model,
		})
	end

	local promptPart = newPart({
		Name = "ArchivePrompt",
		Size = Vector3.new(2, 2, 2),
		Transparency = 1,
		CanCollide = false,
		CFrame = CFrame.new(base + Vector3.new(0, 3, 15)),
		Parent = model,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ArchivePrompt"
	prompt.ActionText = "Browse"
	prompt.ObjectText = "The Critter Archive"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 40)
	billboard.StudsOffset = Vector3.new(0, 20, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = model.Wall
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "🏛️ The Critter Archive"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	return model, promptPart
end

local function buildPlaza(parent)
	local base = WorldConfig.PlazaPosition
	local model = Instance.new("Model")
	model.Name = "CritterPlaza"
	model.Parent = parent

	buildGroundDisc("PlazaFloor", base, 34, Color3.fromRGB(210, 196, 170), Enum.Material.Sandstone, model)

	-- A small centerpiece fountain -- tiered, with a rising sparkle instead
	-- of real fluid simulation.
	for i, ring in ipairs({
		{ y = 0.6, size = 9 },
		{ y = 1.6, size = 6 },
		{ y = 2.4, size = 3.4 },
	}) do
		newPart({
			Name = "FountainTier" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, ring.size, ring.size),
			CFrame = CFrame.new(base + Vector3.new(0, ring.y, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(120, 170, 200),
			Material = Enum.Material.Marble,
			Parent = model,
		})
	end
	local sparkle = Instance.new("Attachment")
	sparkle.Position = Vector3.new(0, 3, 0)
	sparkle.Parent = model.FountainTier3
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(210, 235, 250))
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.8, 1.3)
	emitter.Speed = NumberRange.new(3, 5)
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.Rate = 8
	emitter.Parent = sparkle

	-- Benches + a few empty "show off your Critter" display plinths (real
	-- future functionality is trading/show-off per GAME_DESIGN.md -- these
	-- are the physical space for it, not the system itself).
	buildMeetingRing(base, 13, 6, model)
	for i = 1, 4 do
		local angle = math.rad(i * 90 + 45)
		newPart({
			Name = "DisplayPlinth" .. i,
			Size = Vector3.new(3, 1.4, 3),
			CFrame = CFrame.new(base + Vector3.new(math.cos(angle) * 17, 0.7, math.sin(angle) * 17)),
			Color = Color3.fromRGB(190, 180, 160),
			Material = Enum.Material.Marble,
			Parent = model,
		})
	end

	local billboard = Instance.new("BillboardGui")
	local signPart = newPart({
		Name = "PlazaSign",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CFrame = CFrame.new(base + Vector3.new(0, 8, -16)),
		Parent = model,
	})
	billboard.Size = UDim2.fromOffset(200, 40)
	billboard.AlwaysOnTop = true
	billboard.Parent = signPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "🎪 The Critter Plaza"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	return model
end

-- ==========================================================================
-- THE EVOLUTION SANCTUM
-- ==========================================================================

local function buildEvolutionSanctum(parent)
	local config = WorldConfig.EvolutionSanctum
	local base = config.Center
	local model = Instance.new("Model")
	model.Name = "EvolutionSanctum"
	model.Parent = parent

	buildGroundDisc("SanctumFloor", base, config.Radius * 2, Color3.fromRGB(60, 55, 75), Enum.Material.Slate, model)

	newPart({
		Name = "Dais",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 34, 34),
		CFrame = CFrame.new(base + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(90, 80, 110),
		Material = Enum.Material.Marble,
		Parent = model,
	})

	-- Four glowing braziers, one per Influence, ringing the dais -- the
	-- "visual connection to the different influence types" the brief asks
	-- for, without inventing new mechanics for the MVP.
	local braziers = {
		{ color = Color3.fromRGB(255, 140, 60) },
		{ color = Color3.fromRGB(90, 170, 230) },
		{ color = Color3.fromRGB(110, 190, 90) },
		{ color = Color3.fromRGB(150, 90, 210) },
	}
	for i, brazier in ipairs(braziers) do
		local angle = math.rad((i - 1) * 90 + 45)
		local pos = base + Vector3.new(math.cos(angle) * 15, 0, math.sin(angle) * 15)
		newPart({
			Name = "BrazierPost" .. i,
			Size = Vector3.new(1.4, 4, 1.4),
			CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)),
			Color = Color3.fromRGB(70, 65, 80),
			Material = Enum.Material.Slate,
			Parent = model,
		})
		local flame = newPart({
			Name = "BrazierFlame" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.8, 1.8, 1.8),
			CFrame = CFrame.new(pos + Vector3.new(0, 5.4, 0)),
			Color = brazier.color,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = brazier.color
		light.Range = 16
		light.Brightness = 2
		light.Parent = flame

		-- A thin glowing spoke on the dais floor pointing toward this
		-- Influence's brazier -- cheap "ancient sigil" flavor without any
		-- texture/decal Ids.
		newPart({
			Name = "Spoke" .. i,
			Size = Vector3.new(1, 0.15, 13),
			CFrame = CFrame.new(base + Vector3.new(0, 2.1, 0))
				* CFrame.Angles(0, -angle + math.rad(90), 0)
				* CFrame.new(0, 0, -6.5),
			Color = brazier.color,
			Material = Enum.Material.Neon,
			Transparency = 0.35,
			CanCollide = false,
			Parent = model,
		})
	end

	-- A tall central spire -- "something important happens here."
	local spire = newPart({
		Name = "Spire",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 14, 3),
		CFrame = CFrame.new(base + Vector3.new(0, 9, 0)),
		Color = Color3.fromRGB(250, 235, 200),
		Material = Enum.Material.Neon,
		Transparency = 0.1,
		CanCollide = false,
		Parent = model,
	})
	local spireLight = Instance.new("PointLight")
	spireLight.Color = Color3.fromRGB(255, 245, 215)
	spireLight.Range = 30
	spireLight.Brightness = 2.5
	spireLight.Parent = spire

	local billboard = Instance.new("BillboardGui")
	local signPart = newPart({
		Name = "SanctumSign",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CFrame = CFrame.new(base + Vector3.new(0, 22, 0)),
		Parent = model,
	})
	billboard.Size = UDim2.fromOffset(220, 40)
	billboard.AlwaysOnTop = true
	billboard.Parent = signPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "✨ The Evolution Sanctum"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	return model
end

-- ==========================================================================
-- THE FOUR ENVIRONMENT ZONES (shared, public, gameplay-real)
-- ==========================================================================

local function buildGiantBloom(center, parent)
	local model = Instance.new("Model")
	model.Name = "GiantBloom"
	model.Parent = parent

	newPart({
		Name = "Stalk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(16, 4, 4),
		CFrame = CFrame.new(center + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(70, 130, 60),
		Material = Enum.Material.Grass,
		Parent = model,
	})
	newPart({
		Name = "SeedPod",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(9, 8, 9),
		CFrame = CFrame.new(center + Vector3.new(0, 17, 0)),
		Color = Color3.fromRGB(120, 90, 60),
		Material = Enum.Material.Ground,
		CanCollide = false,
		Parent = model,
	})

	local petalColors = {
		Color3.fromRGB(240, 130, 190),
		Color3.fromRGB(255, 200, 90),
		Color3.fromRGB(200, 130, 230),
		Color3.fromRGB(250, 150, 150),
	}
	for i = 1, 8 do
		local angle = math.rad(i * 45)
		local color = petalColors[(i % #petalColors) + 1]
		newPart({
			Name = "Petal" .. i,
			Shape = Enum.PartType.Wedge,
			Size = Vector3.new(6, 2.4, 11),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * 9, 16, math.sin(angle) * 9))
				* CFrame.Angles(0, angle, 0)
				* CFrame.Angles(math.rad(-35), 0, 0),
			Color = color,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = model,
		})
	end

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 220, 150)
	glow.Range = 26
	glow.Brightness = 1.4
	glow.Parent = model.SeedPod

	-- Supporting greenery scattered across the zone, plus a small stream.
	for i = 1, 10 do
		local angle = math.rad(i * 37)
		local dist = 22 + (i % 3) * 10
		newPart({
			Name = "Bush" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.6, 2.2, 2.6),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * dist, 0.9, math.sin(angle) * dist)),
			Color = Color3.fromRGB(70, 140, 60),
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = model,
		})
	end
	for i = 1, 5 do
		local angle = math.rad(i * 66 + 20)
		local dist = 30 + (i % 2) * 12
		local stem = newPart({
			Name = "FlowerStem" .. i,
			Size = Vector3.new(0.2, 1.6, 0.2),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * dist, 0.8, math.sin(angle) * dist)),
			Color = Color3.fromRGB(80, 140, 70),
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = model,
		})
		newPart({
			Name = "FlowerBloom" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.9, 0.9, 0.9),
			CFrame = stem.CFrame * CFrame.new(0, 1, 0),
			Color = i % 2 == 0 and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(240, 140, 190),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = model,
		})
	end
	newPart({
		Name = "Stream",
		Size = Vector3.new(6, 0.3, 40),
		CFrame = CFrame.new(center + Vector3.new(24, 0.1, 0)) * CFrame.Angles(0, math.rad(15), 0),
		Color = Color3.fromRGB(120, 200, 220),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		Parent = model,
	})

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 235, 210))
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(1.6, 2.4)
	emitter.Speed = NumberRange.new(0.3, 0.7)
	emitter.Acceleration = Vector3.new(0, -0.4, 0)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 4
	emitter.Parent = model.SeedPod

	return model
end

local function buildEmberCore(center, parent)
	local model = Instance.new("Model")
	model.Name = "EmberCore"
	model.Parent = parent

	for i = 1, 9 do
		local angle = math.rad(i * 40)
		local dist = 6 + (i % 3) * 3
		newPart({
			Name = "Rock" .. i,
			Shape = Enum.PartType.Block,
			Size = Vector3.new(3 + (i % 3), 3 + (i % 4), 3 + (i % 2)),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * dist, 1.5 + (i % 3), math.sin(angle) * dist))
				* CFrame.Angles(math.rad(i * 7), math.rad(i * 21), math.rad(i * 5)),
			Color = Color3.fromRGB(58, 45, 42),
			Material = Enum.Material.Basalt,
			Parent = model,
		})
	end

	local crystal = newPart({
		Name = "Crystal",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6, 20, 6),
		CFrame = CFrame.new(center + Vector3.new(0, 12, 0)) * CFrame.Angles(math.rad(6), 0, math.rad(-4)),
		Color = Color3.fromRGB(255, 110, 40),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})
	local crystalLight = Instance.new("PointLight")
	crystalLight.Color = Color3.fromRGB(255, 140, 60)
	crystalLight.Range = 30
	crystalLight.Brightness = 3
	crystalLight.Parent = crystal

	for i = 1, 3 do
		local angle = math.rad(i * 110)
		newPart({
			Name = "CrackGlow" .. i,
			Size = Vector3.new(0.4, 3, 0.4),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * 5, 2, math.sin(angle) * 5))
				* CFrame.Angles(0, angle, math.rad(25)),
			Color = Color3.fromRGB(255, 160, 70),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = model,
		})
	end

	for i = 1, 6 do
		local angle = math.rad(i * 60 + 20)
		local dist = 24 + (i % 3) * 9
		newPart({
			Name = "EmberRock" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2, 1.6, 2),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * dist, 0.8, math.sin(angle) * dist)),
			Color = Color3.fromRGB(70, 55, 50),
			Material = Enum.Material.Basalt,
			CanCollide = false,
			Parent = model,
		})
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 170, 70))
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(1, 1.8)
	emitter.Speed = NumberRange.new(3, 6)
	emitter.Acceleration = Vector3.new(0, 8, 0)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Rate = 10
	emitter.Parent = crystal

	return model
end

local function buildGreatPool(center, parent)
	local model = Instance.new("Model")
	model.Name = "GreatPool"
	model.Parent = parent

	buildGroundDisc("PoolWater", center, 24, Color3.fromRGB(70, 175, 220), Enum.Material.Neon, model)
	model.PoolWater.Transparency = 0.15
	model.PoolWater.CanCollide = false
	model.PoolWater.CFrame = model.PoolWater.CFrame * CFrame.new(0, 0.3, 0)

	for i = 1, 8 do
		local angle = math.rad(i * 45)
		newPart({
			Name = "ShoreRock" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(3, 2.2, 3),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * 13, 0.8, math.sin(angle) * 13)),
			Color = Color3.fromRGB(150, 150, 145),
			Material = Enum.Material.Slate,
			CanCollide = false,
			Parent = model,
		})
	end

	-- Two small waterfalls off raised ledges into the pool.
	for i = 1, 2 do
		local side = i == 1 and -1 or 1
		local ledgePos = center + Vector3.new(side * 16, 4, -18)
		newPart({
			Name = "Ledge" .. i,
			Size = Vector3.new(8, 8, 6),
			CFrame = CFrame.new(ledgePos),
			Color = Color3.fromRGB(140, 138, 130),
			Material = Enum.Material.Slate,
			Parent = model,
		})
		local fall = newPart({
			Name = "Waterfall" .. i,
			Size = Vector3.new(4, 8, 0.6),
			CFrame = CFrame.new(ledgePos + Vector3.new(0, -4, 3.2)),
			Color = Color3.fromRGB(150, 220, 240),
			Material = Enum.Material.Neon,
			Transparency = 0.25,
			CanCollide = false,
			Parent = model,
		})
		local splashEmitter = Instance.new("ParticleEmitter")
		splashEmitter.Color = ColorSequence.new(Color3.fromRGB(230, 245, 250))
		splashEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
		splashEmitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		splashEmitter.Lifetime = NumberRange.new(0.4, 0.7)
		splashEmitter.Speed = NumberRange.new(2, 4)
		splashEmitter.SpreadAngle = Vector2.new(60, 20)
		splashEmitter.Rate = 10
		splashEmitter.Parent = fall
	end

	-- Playful stylized coral, not realistic.
	local coralColors = { Color3.fromRGB(255, 140, 170), Color3.fromRGB(255, 200, 100), Color3.fromRGB(170, 130, 230) }
	for i = 1, 6 do
		local angle = math.rad(i * 60 + 15)
		local dist = 16 + (i % 2) * 5
		newPart({
			Name = "Coral" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.6, 1.2, 1.2),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * dist, 0.6, math.sin(angle) * dist))
				* CFrame.Angles(0, 0, math.rad(90))
				* CFrame.Angles(math.rad(20 * i), 0, 0),
			Color = coralColors[(i % #coralColors) + 1],
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = model,
		})
	end

	local bubbleEmitter = Instance.new("ParticleEmitter")
	bubbleEmitter.Color = ColorSequence.new(Color3.fromRGB(220, 240, 250))
	bubbleEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.05) })
	bubbleEmitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	bubbleEmitter.Lifetime = NumberRange.new(1, 1.8)
	bubbleEmitter.Speed = NumberRange.new(0.5, 1)
	bubbleEmitter.Acceleration = Vector3.new(0, 2, 0)
	bubbleEmitter.SpreadAngle = Vector2.new(180, 180)
	bubbleEmitter.Rate = 6
	bubbleEmitter.Parent = model.PoolWater

	return model
end

local function buildWhisperingHollow(center, parent)
	local model = Instance.new("Model")
	model.Name = "WhisperingHollow"
	model.Parent = parent

	-- Twisted trees: a few angled cylinder segments instead of a straight
	-- trunk, so the silhouette itself reads as "wrong" -- mysterious, not
	-- scary (kept to indigo/plum, never pure black).
	for t = 1, 3 do
		local angle = math.rad(t * 110)
		local dist = 16 + (t % 2) * 6
		local treeBase = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		local cursor = treeBase
		local lean = 0
		for seg = 1, 3 do
			lean += (seg % 2 == 0 and 12 or -16)
			local segCFrame = CFrame.new(cursor) * CFrame.Angles(0, angle, math.rad(lean)) * CFrame.new(0, 4, 0)
			newPart({
				Name = ("Tree%d_Segment%d"):format(t, seg),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(8, 1.6 - seg * 0.3, 1.6 - seg * 0.3),
				CFrame = segCFrame * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(48, 40, 55),
				Material = Enum.Material.Wood,
				Parent = model,
			})
			cursor = (segCFrame * CFrame.new(4, 0, 0)).Position
		end
		newPart({
			Name = "TreeCanopy" .. t,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(9, 6, 9),
			CFrame = CFrame.new(cursor + Vector3.new(0, 2, 0)),
			Color = Color3.fromRGB(58, 48, 72),
			Material = Enum.Material.Slate,
			CanCollide = false,
			Parent = model,
		})
	end

	-- A central cluster of glowing mushrooms/plants -- the zone's warm
	-- focal point, kept inviting rather than dark.
	local glowColors = { Color3.fromRGB(150, 100, 220), Color3.fromRGB(90, 200, 190) }
	for i = 1, 7 do
		local angle = math.rad(i * 51)
		local dist = 3 + (i % 3) * 2.4
		local stemHeight = 1 + (i % 3) * 0.6
		local stem = newPart({
			Name = "MushroomStem" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(stemHeight, 0.7, 0.7),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * dist, stemHeight / 2, math.sin(angle) * dist))
				* CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(210, 205, 200),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = model,
		})
		local cap = newPart({
			Name = "MushroomCap" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.6, 0.9, 1.6),
			CFrame = stem.CFrame * CFrame.new(0, stemHeight / 2 + 0.2, 0),
			Color = glowColors[(i % #glowColors) + 1],
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = cap.Color
		light.Range = 8
		light.Brightness = 1.2
		light.Parent = cap
	end

	-- A soft haze layer -- a large, very transparent part plus slow drifting
	-- smoke particles, no real fog service needed.
	local haze = newPart({
		Name = "Haze",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(70, 14, 70),
		CFrame = CFrame.new(center + Vector3.new(0, 6, 0)),
		Color = Color3.fromRGB(90, 85, 110),
		Material = Enum.Material.ForceField,
		Transparency = 0.88,
		CanCollide = false,
		Parent = model,
	})

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(140, 120, 180))
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(2, 3.2)
	emitter.Speed = NumberRange.new(0.4, 0.8)
	emitter.Acceleration = Vector3.new(0, 1, 0)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 3
	emitter.Parent = haze

	return model
end

local ZONE_GROUND = {
	nature_patch = { Color = Color3.fromRGB(72, 138, 62), Material = Enum.Material.Grass },
	fire_corner = { Color = Color3.fromRGB(64, 46, 40), Material = Enum.Material.Basalt },
	water_pool = { Color = Color3.fromRGB(214, 198, 150), Material = Enum.Material.Sand },
	shadow_nook = { Color = Color3.fromRGB(54, 48, 66), Material = Enum.Material.Slate },
}

local ZONE_LANDMARK_BUILDERS = {
	nature_patch = buildGiantBloom,
	fire_corner = buildEmberCore,
	water_pool = buildGreatPool,
	shadow_nook = buildWhisperingHollow,
}

-- Builds one public Environment Zone: its ground tint, its landmark, and
-- the same "Play" ProximityPrompt shape HabitatBuilder used to build per
-- habitat -- wired by Init.server.lua straight to
-- InfluenceService.HandlePlayAtZone(player, zoneId), now with no owner
-- check at all, since a shared world zone doesn't belong to anyone.
local function buildZone(zoneId, parent)
	local zoneConfig = EnvironmentConfig.Get(zoneId)
	local worldZone = WorldConfig.Zones[zoneId]
	local ground = ZONE_GROUND[zoneId]

	local model = Instance.new("Model")
	model.Name = worldZone.LandmarkName
	model.Parent = parent

	buildGroundDisc(zoneId .. "Ground", worldZone.Center, worldZone.Radius * 2, ground.Color, ground.Material, model)

	local landmarkBuilder = ZONE_LANDMARK_BUILDERS[zoneId]
	if landmarkBuilder then
		landmarkBuilder(worldZone.Center, model)
	end

	local promptPart = newPart({
		Name = zoneId,
		Size = Vector3.new(4, 1, 4),
		Color = zoneConfig.Color,
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(worldZone.Center + Vector3.new(0, 0.5, 26)),
		Parent = model,
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ZoneLabel"
	billboard.Size = UDim2.fromOffset(160, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = promptPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = zoneConfig.Icon and (zoneConfig.Icon .. " " .. zoneConfig.Name) or zoneConfig.Name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	local landmarkBillboard = Instance.new("BillboardGui")
	landmarkBillboard.Size = UDim2.fromOffset(220, 40)
	landmarkBillboard.StudsOffset = Vector3.new(0, 24, 0)
	landmarkBillboard.AlwaysOnTop = true
	landmarkBillboard.Parent = promptPart
	local landmarkLabel = Instance.new("TextLabel")
	landmarkLabel.Size = UDim2.fromScale(1, 1)
	landmarkLabel.BackgroundTransparency = 1
	landmarkLabel.Text = worldZone.LandmarkName
	landmarkLabel.TextColor3 = Color3.new(1, 1, 1)
	landmarkLabel.TextStrokeTransparency = 0
	landmarkLabel.Font = Enum.Font.GothamBold
	landmarkLabel.TextScaled = true
	landmarkLabel.Parent = landmarkBillboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlayPrompt"
	prompt.ActionText = "Play"
	prompt.ObjectText = zoneConfig.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart

	return promptPart
end

-- ==========================================================================
-- BUILD
-- ==========================================================================

function WorldBuilder.Build()
	local workspace = game:GetService("Workspace")

	configureLighting()

	local worldFolder = Instance.new("Folder")
	worldFolder.Name = "World"
	worldFolder.Parent = workspace

	-- Hub ground + the Meadow's own landmarks.
	buildGroundDisc("MeadowGround", WorldConfig.HubCenter, WorldConfig.HubRadius * 2, Color3.fromRGB(94, 172, 84), Enum.Material.Grass, worldFolder)
	buildSpawn(worldFolder)
	buildCritterTree(worldFolder)
	buildMeetingRing(WorldConfig.CritterTreePosition, 18, 8, worldFolder)
	buildCompassSign(worldFolder)
	buildArchive(worldFolder)
	buildPlaza(worldFolder)

	-- Spokes: hub edge -> each destination's own edge, using plain vector
	-- math so the layout doesn't need hand-tuned per-path numbers. `dest`
	-- is assumed to already be roughly on the ground plane (Y ignored).
	local function spokePoints(dest, destRadius)
		local flat = Vector3.new(dest.X, 0, dest.Z)
		local dir = flat.Unit
		local hubEdge = dir * WorldConfig.HubRadius
		local destEdge = flat - dir * destRadius
		return hubEdge, destEdge
	end

	for _, zoneId in ipairs(WorldConfig.ZoneOrder) do
		local worldZone = WorldConfig.Zones[zoneId]
		local hubEdge, zoneEdge = spokePoints(worldZone.Center, worldZone.Radius)
		buildPath(hubEdge, zoneEdge, WorldConfig.PathWidth, worldFolder)
		buildZone(zoneId, worldFolder)
	end

	do
		local sanctum = WorldConfig.EvolutionSanctum
		local hubEdge, sanctumEdge = spokePoints(sanctum.Center, sanctum.Radius)
		buildPath(hubEdge, sanctumEdge, WorldConfig.PathWidth, worldFolder)
		buildEvolutionSanctum(worldFolder)
	end

	do
		local entrance = WorldConfig.HabitatEntrance
		local hubEdge = spokePoints(entrance, 0)
		buildPath(hubEdge, entrance, WorldConfig.PathWidth, worldFolder)

		local signPart = newPart({
			Name = "HabitatSign",
			Size = Vector3.new(1, 1, 1),
			Transparency = 1,
			CanCollide = false,
			CFrame = CFrame.new(entrance + Vector3.new(0, 6, 0)),
			Parent = worldFolder,
		})
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(200, 36)
		billboard.AlwaysOnTop = true
		billboard.Parent = signPart
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "🏠 Player Habitats ↓"
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Parent = billboard
	end

	return worldFolder
end

return WorldBuilder
