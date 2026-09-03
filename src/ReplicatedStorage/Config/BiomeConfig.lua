-- Data for the terrain SURROUNDING each existing Environment Zone and
-- each existing hub<->zone path -- the Phase 2/3 world expansion (see
-- docs/FOUNDATION_ROADMAP.md section 7). This never touches the zone
-- landmarks/prompts themselves (those stay exactly as WorldBuilder
-- already builds them); it only adds terrain around and between them so
-- the world reads as one connected landscape instead of pods in a void.
--
-- Every position here is a Vector3 *offset from that zone's own center*
-- (WorldConfig.Zones[id].Center) for Regions, or an absolute Vector3 for
-- Corridors (a corridor doesn't have one natural center the way a zone
-- does). TerrainBuilder resolves offsets to world positions and dispatches
-- each entry's Type to a generic builder function -- adding a new biome
-- later means adding one new Regions entry with a Features list built
-- from these same Types (Hill/Mountain/ForestPatch/Cliff/CaveEntrance/
-- RockField/ShoreCluster/Stream), not writing new bespoke code, unless a
-- genuinely new feature *shape* is needed.
--
-- Every offset below was checked against the hub disc, all four zone
-- discs, the Evolution Sanctum disc, and the habitat neighborhood
-- rectangle before being written down here -- nature_patch in particular
-- sits close enough to the habitat neighborhood (see WorldConfig) that
-- its features are deliberately biased west/northwest only.

local BiomeConfig = {}

BiomeConfig.Regions = {
	nature_patch = {
		Features = {
			{ Type = "ForestPatch", Offset = Vector3.new(-90, 0, -20), Radius = 30, TreeCount = 7 },
			{ Type = "ForestPatch", Offset = Vector3.new(-70, 0, -80), Radius = 30, TreeCount = 6 },
			{ Type = "Hill", Offset = Vector3.new(-40, 0, -110), Radius = 25, Height = 16 },
			{ Type = "Hill", Offset = Vector3.new(-100, 0, 40), Radius = 25, Height = 14 },
		},
	},

	fire_corner = {
		Features = {
			{ Type = "Mountain", Offset = Vector3.new(-140, 0, 0), Radius = 35, Height = 40 },
			{ Type = "Hill", Offset = Vector3.new(-80, 0, -70), Radius = 25, Height = 18 },
			{ Type = "Hill", Offset = Vector3.new(-80, 0, 70), Radius = 25, Height = 16 },
			{
				Type = "Cliff",
				Offset = Vector3.new(-40, 0, -110),
				Width = 40,
				Height = 26,
				HasFall = true,
				FallColor = Color3.fromRGB(255, 130, 50), -- a lava-fall, not water, to stay on-theme
			},
			{ Type = "CaveEntrance", Offset = Vector3.new(-100, 0, 20) },
			{ Type = "RockField", Offset = Vector3.new(0, 0, -90), Radius = 30, Count = 7 },
		},
	},

	water_pool = {
		Features = {
			{ Type = "Hill", Offset = Vector3.new(140, 0, 0), Radius = 32, Height = 20 },
			{ Type = "ShoreCluster", Offset = Vector3.new(80, 0, -70), Radius = 25, Count = 7 },
			{ Type = "ShoreCluster", Offset = Vector3.new(80, 0, 70), Radius = 25, Count = 7 },
			{ Type = "Stream", FromOffset = Vector3.new(20, 0, 60), ToOffset = Vector3.new(60, 0, 90), Width = 6 },
			{ Type = "Cliff", Offset = Vector3.new(40, 0, -110), Width = 40, Height = 24 },
		},
	},

	shadow_nook = {
		Features = {
			{ Type = "Mountain", Offset = Vector3.new(0, 0, -160), Radius = 35, Height = 42 },
			{ Type = "ForestPatch", Offset = Vector3.new(-90, 0, -60), Radius = 28, TreeCount = 7, Twisted = true },
			{ Type = "ForestPatch", Offset = Vector3.new(90, 0, -60), Radius = 28, TreeCount = 6, Twisted = true },
			{ Type = "CaveEntrance", Offset = Vector3.new(0, 0, -100) },
			{
				Type = "Cliff",
				Offset = Vector3.new(-130, 0, -30),
				Width = 40,
				Height = 26,
				HasFall = true,
				FallColor = Color3.fromRGB(150, 140, 190), -- a misty, cool-toned fall -- mysterious, not menacing
			},
			{ Type = "Hill", Offset = Vector3.new(130, 0, -30), Radius = 25, Height = 18 },
		},
	},
}

-- Light scatter along each existing hub<->destination path, so the walk
-- between the Meadow and a zone isn't just grass either side of a trail.
-- Absolute positions (see file header) -- each already checked clear of
-- the hub disc, every zone disc, the Sanctum disc, and the habitat
-- rectangle, and kept close to its own path's centerline so nothing
-- blocks the actual walkable trail.
BiomeConfig.Corridors = {
	nature_patch = {
		{ Type = "Hill", Position = Vector3.new(-87, 0, 84), Radius = 16, Height = 10 },
		{ Type = "Hill", Position = Vector3.new(-52, 0, 110), Radius = 16, Height = 9 },
	},
	fire_corner = {
		{ Type = "Hill", Position = Vector3.new(-114, 0, -22), Radius = 16, Height = 10 },
		{ Type = "ForestPatch", Position = Vector3.new(-114, 0, 22), Radius = 16, TreeCount = 3 },
	},
	water_pool = {
		{ Type = "Hill", Position = Vector3.new(114, 0, 22), Radius = 16, Height = 10 },
		{ Type = "ShoreCluster", Position = Vector3.new(114, 0, -22), Radius = 16, Count = 4 },
	},
	shadow_nook = {
		{ Type = "Hill", Position = Vector3.new(22, 0, -116), Radius = 16, Height = 10 },
		{ Type = "ForestPatch", Position = Vector3.new(-22, 0, -116), Radius = 16, TreeCount = 3, Twisted = true },
	},
	sanctum = {
		{ Type = "Hill", Position = Vector3.new(66, 0, 118), Radius = 16, Height = 9 },
		{ Type = "Hill", Position = Vector3.new(100, 0, 91), Radius = 16, Height = 9 },
	},
	habitat = {
		{ Type = "Hill", Position = Vector3.new(-22, 0, 105), Radius = 16, Height = 8 },
		{ Type = "Hill", Position = Vector3.new(22, 0, 105), Radius = 16, Height = 8 },
	},
}

return BiomeConfig
