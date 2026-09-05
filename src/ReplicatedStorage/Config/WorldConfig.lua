-- Shared overworld coordinates. WorldBuilder (the hub, the four Environment
-- Zones, the Archive/Plaza/Sanctum) and HabitatBuilder (the player
-- neighborhood) both read this so the two halves of the map are built from
-- one source of truth instead of two files quietly agreeing on magic
-- numbers. Every ground level in this file is Y=0 (top face of a ground
-- part) so nothing needs per-area vertical fudging.

local WorldConfig = {}

WorldConfig.HubCenter = Vector3.new(0, 0, 0)
WorldConfig.HubRadius = 60
WorldConfig.PathWidth = 14

-- Where a new player spawns and looks -- just inside the Meadow's south
-- edge, facing the Critter Tree at the hub center.
WorldConfig.SpawnPosition = Vector3.new(0, 1, 46)
WorldConfig.CritterTreePosition = Vector3.new(0, 0, -10)
WorldConfig.ArchivePosition = Vector3.new(-46, 0, -32)
WorldConfig.PlazaPosition = Vector3.new(46, 0, -32)

-- The four real Environment Zones, now shared world destinations instead of
-- a private copy per habitat. Ids match EnvironmentConfig exactly on
-- purpose -- InfluenceService.HandlePlayAtZone already only cares about the
-- zoneId, never where the prompt physically lives, so moving these here
-- required zero changes to the influence/growth/evolution chain.
WorldConfig.Zones = {
	nature_patch = { Center = Vector3.new(-140, 0, 195), Radius = 62, LandmarkName = "The Giant Bloom" },
	fire_corner = { Center = Vector3.new(-230, 0, 0), Radius = 62, LandmarkName = "The Ember Core" },
	water_pool = { Center = Vector3.new(230, 0, 0), Radius = 62, LandmarkName = "The Great Pool" },
	shadow_nook = { Center = Vector3.new(0, 0, -235), Radius = 62, LandmarkName = "The Whispering Hollow" },
}
WorldConfig.ZoneOrder = { "nature_patch", "fire_corner", "water_pool", "shadow_nook" }

WorldConfig.EvolutionSanctum = { Center = Vector3.new(155, 0, 195), Radius = 42 }

-- Not a circular zone like the others (it's a rectangular grid built by
-- HabitatBuilder) -- just the point WorldBuilder's south path aims at, and
-- the center HabitatBuilder centers its own grid + ground patch on.
WorldConfig.HabitatEntrance = Vector3.new(0, 0, 150)
WorldConfig.HabitatNeighborhoodCenter = Vector3.new(0, 0, 270)

return WorldConfig
