-- Builds the terrain SURROUNDING each existing Environment Zone and each
-- existing hub<->zone path -- see docs/FOUNDATION_ROADMAP.md section 7
-- (Phase 2/3, the world expansion) and BiomeConfig for the data this
-- reads. This module owns exactly one thing: turning a small, typed
-- feature description ("Hill" at this offset, this radius, this height)
-- into Parts. It never touches the zone landmarks/prompts WorldBuilder
-- already builds and owns -- it only fills in the ground around them.
--
-- Every builder here is deliberately generic and cheap (a handful of
-- Parts per feature, no per-biome bespoke code) so a future biome is a
-- BiomeConfig data entry, not a new function -- see FEATURE_BUILDERS at
-- the bottom for the full list of reusable feature types.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig = require(ReplicatedStorage.Config.WorldConfig)
local BiomeConfig = require(ReplicatedStorage.Config.BiomeConfig)
local PartUtil = require(ReplicatedStorage.Modules.PartUtil)

local TerrainBuilder = {}

local newPart = PartUtil.new

local function shade(color, factor)
	return Color3.new(
		math.clamp(color.R * factor, 0, 1),
		math.clamp(color.G * factor, 0, 1),
		math.clamp(color.B * factor, 0, 1)
	)
end

-- A deterministic per-feature Random, seeded from its own position so the
-- scatter inside a Hill/ForestPatch/RockField is stable across server
-- restarts (reproducible for testing) without needing an explicit seed
-- value in BiomeConfig's data.
local function randomFor(center)
	return Random.new(math.floor(center.X * 97 + center.Z * 131))
end

-- ==========================================================================
-- GENERIC FEATURE BUILDERS -- reused across every biome
-- ==========================================================================

-- A rounded mound: 3 stacked, tapering Ball parts. Cheap (3 parts) and
-- reads as a hill at a glance; `buildHill`/`buildMountain` are just this
-- with different proportions/materials, so biome data never duplicates
-- geometry logic, only parameters.
local function buildMound(parent, center, radius, height, baseColor, peakColor, material)
	local tiers = {
		{ y = height * 0.16, size = radius * 2, h = height * 0.42 },
		{ y = height * 0.48, size = radius * 1.5, h = height * 0.4 },
		{ y = height * 0.76, size = radius * 0.9, h = height * 0.34, color = peakColor },
	}
	for i, tier in ipairs(tiers) do
		newPart({
			Name = "Mound" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(tier.size, tier.h, tier.size),
			CFrame = CFrame.new(center + Vector3.new(0, tier.y, 0)),
			Color = tier.color or baseColor,
			Material = material,
			CanCollide = true,
			Parent = parent,
		})
	end
end

local function buildHill(parent, feature, center)
	buildMound(
		parent,
		center,
		feature.Radius,
		feature.Height,
		Color3.fromRGB(96, 168, 84),
		Color3.fromRGB(120, 190, 100),
		Enum.Material.Grass
	)
end

local function buildMountain(parent, feature, center)
	buildMound(
		parent,
		center,
		feature.Radius,
		feature.Height,
		Color3.fromRGB(108, 100, 96),
		Color3.fromRGB(150, 145, 145),
		Enum.Material.Rock
	)
end

-- A small stylized tree -- trunk + one or two canopy balls, ~3 parts.
-- Cheaper than the Meadow's own Critter Tree on purpose: this is filler
-- terrain, not a landmark. `twisted` leans the trunk for Gloom Grove's
-- "wrong-looking" silhouette language (see WorldBuilder.buildWhisperingHollow).
local function buildSimpleTree(parent, position, rng, twisted)
	local height = 6 + rng:NextNumber() * 3
	local lean = twisted and (rng:NextNumber() * 24 - 12) or (rng:NextNumber() * 6 - 3)
	local trunkColor = twisted and Color3.fromRGB(52, 44, 58) or Color3.fromRGB(96, 66, 46)
	local canopyColor = twisted
			and Color3.fromRGB(58, 48, 72)
		or Color3.fromRGB(84 + rng:NextInteger(0, 30), 150 + rng:NextInteger(0, 30), 76)

	local trunk = newPart({
		Name = "TrunkFill",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.1, 1.1),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90 + lean)),
		Color = trunkColor,
		Material = Enum.Material.Wood,
		Parent = parent,
	})

	local canopyPos = trunk.CFrame * CFrame.new(height / 2, 0, 0)
	newPart({
		Name = "CanopyFill",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(5.5, 4.5, 5.5),
		CFrame = canopyPos,
		Color = canopyColor,
		Material = twisted and Enum.Material.Slate or Enum.Material.Grass,
		CanCollide = false,
		Parent = parent,
	})
end

local function buildForestPatch(parent, feature, center)
	local rng = randomFor(center)
	for _ = 1, feature.TreeCount or 6 do
		local angle = rng:NextNumber() * math.pi * 2
		local dist = rng:NextNumber() * feature.Radius
		local pos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		buildSimpleTree(parent, pos, rng, feature.Twisted)
	end
end

-- A jagged rock face -- 3 angled Blocks plus a flatter plateau cap.
-- `HasFall` adds a thin glowing strip down the face (a lava-fall for
-- Ember Zone, a misty fall for Gloom Grove) reusing the same visual
-- trick as the Tidepool's own waterfalls.
local function buildCliff(parent, feature, center)
	local width = feature.Width or 36
	local height = feature.Height or 24
	local baseColor = Color3.fromRGB(95, 88, 84)

	for i = 1, 3 do
		local offset = (i - 2) * (width / 3.2)
		local segHeight = height * (0.75 + 0.25 * math.sin(i * 1.7))
		newPart({
			Name = "CliffFace" .. i,
			Size = Vector3.new(width / 2.6, segHeight, 8),
			CFrame = CFrame.new(center + Vector3.new(offset, segHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad((i - 2) * 4)),
			Color = shade(baseColor, 1 + (i - 2) * 0.06),
			Material = Enum.Material.Rock,
			Parent = parent,
		})
	end

	newPart({
		Name = "CliffPlateau",
		Size = Vector3.new(width, 2, 12),
		CFrame = CFrame.new(center + Vector3.new(0, height + 1, -2)),
		Color = shade(baseColor, 1.1),
		Material = Enum.Material.Rock,
		Parent = parent,
	})

	if feature.HasFall then
		local fallColor = feature.FallColor or Color3.fromRGB(150, 210, 240)
		local fall = newPart({
			Name = "Cascade",
			Size = Vector3.new(4, height * 0.9, 0.6),
			CFrame = CFrame.new(center + Vector3.new(0, height * 0.45, 4.2)),
			Color = fallColor,
			Material = Enum.Material.Neon,
			Transparency = 0.25,
			CanCollide = false,
			Parent = parent,
		})
		local light = Instance.new("PointLight")
		light.Color = fallColor
		light.Range = 16
		light.Brightness = 1.6
		light.Parent = fall

		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(fallColor)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(1, 2)
		emitter.SpreadAngle = Vector2.new(30, 10)
		emitter.Rate = 8
		emitter.Parent = fall
	end
end

-- A rock archway around a dark entrance plane -- a visual-only marker for
-- future dungeon/underground content (see docs/CRITTERBOUND_DESIGN_BIBLE.md
-- section 8's "caves, hidden areas"). No interior exists yet; this is
-- deliberately not wired to a ProximityPrompt so it never promises
-- gameplay it doesn't have.
local function buildCaveEntrance(parent, feature, center)
	for _, side in ipairs({ -1, 1 }) do
		newPart({
			Name = "CavePillar",
			Size = Vector3.new(4, 12, 5),
			CFrame = CFrame.new(center + Vector3.new(side * 5, 6, 0)) * CFrame.Angles(0, 0, math.rad(-side * 8)),
			Color = Color3.fromRGB(70, 64, 62),
			Material = Enum.Material.Rock,
			Parent = parent,
		})
	end
	newPart({
		Name = "CaveLintel",
		Size = Vector3.new(14, 4, 5),
		CFrame = CFrame.new(center + Vector3.new(0, 11, 0)) * CFrame.Angles(0, 0, math.rad(2)),
		Color = Color3.fromRGB(64, 58, 56),
		Material = Enum.Material.Rock,
		Parent = parent,
	})
	newPart({
		Name = "CaveDark",
		Size = Vector3.new(7, 8, 1),
		CFrame = CFrame.new(center + Vector3.new(0, 4.5, -1.8)),
		Color = Color3.fromRGB(8, 8, 10),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = parent,
	})
end

local function buildRockField(parent, feature, center)
	local rng = randomFor(center)
	for _ = 1, feature.Count or 6 do
		local angle = rng:NextNumber() * math.pi * 2
		local dist = rng:NextNumber() * feature.Radius
		local size = 2 + rng:NextNumber() * 2.5
		newPart({
			Name = "Boulder",
			Shape = Enum.PartType.Block,
			Size = Vector3.new(size, size * 0.8, size * 0.9),
			CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * dist, size * 0.3, math.sin(angle) * dist))
				* CFrame.Angles(rng:NextNumber() * 0.4, rng:NextNumber() * math.pi, rng:NextNumber() * 0.3),
			Color = Color3.fromRGB(60 + rng:NextInteger(-8, 8), 48, 44),
			Material = Enum.Material.Basalt,
			Parent = parent,
		})
	end
end

local function buildShoreCluster(parent, feature, center)
	local rng = randomFor(center)
	for i = 1, feature.Count or 6 do
		local angle = rng:NextNumber() * math.pi * 2
		local dist = rng:NextNumber() * feature.Radius
		local pos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		if i % 3 == 0 then
			newPart({
				Name = "ShoreRockFill",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2.4, 1.8, 2.4),
				CFrame = CFrame.new(pos + Vector3.new(0, 0.7, 0)),
				Color = Color3.fromRGB(145, 145, 140),
				Material = Enum.Material.Slate,
				Parent = parent,
			})
		else
			newPart({
				Name = "Reed",
				Size = Vector3.new(0.3, 2.4 + rng:NextNumber(), 0.3),
				CFrame = CFrame.new(pos + Vector3.new(0, 1.2, 0)) * CFrame.Angles(rng:NextNumber() * 0.2, 0, rng:NextNumber() * 0.2),
				Color = Color3.fromRGB(90, 150, 100),
				Material = Enum.Material.Grass,
				CanCollide = false,
				Parent = parent,
			})
		end
	end
end

-- A short water strip between two points -- the same "rectangle between
-- two points" trick WorldBuilder's own buildPath uses, kept as an
-- independent copy here (see file header: additive only, never editing
-- WorldBuilder's existing code) so a Stream is just a themed variant of a
-- Path, not a new geometry idea.
local function buildStream(parent, fromPoint, toPoint, width)
	local length = (toPoint - fromPoint).Magnitude
	local mid = fromPoint + (toPoint - fromPoint) / 2
	newPart({
		Name = "Stream",
		Size = Vector3.new(width, 0.4, length),
		CFrame = CFrame.new(mid, Vector3.new(toPoint.X, mid.Y, toPoint.Z)) * CFrame.new(0, 0.15, 0),
		Color = Color3.fromRGB(120, 195, 220),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		CanCollide = false,
		Parent = parent,
	})
end

-- ==========================================================================
-- DISPATCH
-- ==========================================================================

-- One entry per feature Type used in BiomeConfig. Adding a new *kind* of
-- feature is one new function above plus one new line here; adding more
-- of an *existing* kind anywhere else in the world is purely a
-- BiomeConfig data change.
local FEATURE_BUILDERS = {
	Hill = buildHill,
	Mountain = buildMountain,
	ForestPatch = buildForestPatch,
	Cliff = buildCliff,
	CaveEntrance = buildCaveEntrance,
	RockField = buildRockField,
	ShoreCluster = buildShoreCluster,
}

local function buildFeatureAt(parent, feature, center)
	if feature.Type == "Stream" then
		return -- Stream resolves two offsets, handled by its caller below
	end
	local builder = FEATURE_BUILDERS[feature.Type]
	if builder then
		builder(parent, feature, center)
	else
		warn("TerrainBuilder: unknown feature Type", tostring(feature.Type))
	end
end

-- Builds every terrain feature configured for one existing Environment
-- Zone. Positions resolve relative to that zone's own center
-- (WorldConfig.Zones[zoneId].Center) so this stays correct even if that
-- position config ever moves.
function TerrainBuilder.BuildBiome(zoneId, parent)
	local region = BiomeConfig.Regions[zoneId]
	local worldZone = WorldConfig.Zones[zoneId]
	if not region or not worldZone then
		return
	end

	for _, feature in ipairs(region.Features) do
		if feature.Type == "Stream" then
			buildStream(
				parent,
				worldZone.Center + feature.FromOffset,
				worldZone.Center + feature.ToOffset,
				feature.Width or 5
			)
		else
			buildFeatureAt(parent, feature, worldZone.Center + feature.Offset)
		end
	end
end

-- Light scatter along one existing hub<->destination path. `corridorId`
-- matches BiomeConfig.Corridors' keys (the four zone ids, "sanctum", or
-- "habitat") -- positions there are already absolute (see BiomeConfig's
-- file header for why).
function TerrainBuilder.BuildCorridorScatter(corridorId, parent)
	local features = BiomeConfig.Corridors[corridorId]
	if not features then
		return
	end
	for _, feature in ipairs(features) do
		buildFeatureAt(parent, feature, feature.Position)
	end
end

-- The single entry point WorldBuilder calls -- builds every configured
-- biome shell and every configured corridor scatter. Purely additive to
-- whatever WorldBuilder already built into `parent` (the shared World
-- folder); never touches or depends on build order relative to it.
function TerrainBuilder.BuildAll(parent)
	for zoneId in pairs(BiomeConfig.Regions) do
		TerrainBuilder.BuildBiome(zoneId, parent)
	end
	for corridorId in pairs(BiomeConfig.Corridors) do
		TerrainBuilder.BuildCorridorScatter(corridorId, parent)
	end
end

return TerrainBuilder
