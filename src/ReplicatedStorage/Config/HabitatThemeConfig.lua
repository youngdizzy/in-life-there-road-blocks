-- Premium habitat themes (see monetization spec Phase 7). Data-only stub --
-- the only real habitat monetization shipped so far is the VIP Habitat
-- gamepass's corner-post/badge visual (see HabitatManager.ApplyVIPVisual).
-- Full re-skinning of the platform/props per theme needs its own render
-- path in HabitatBuilder and isn't built yet.

local HabitatThemeConfig = {}

HabitatThemeConfig.Themes = {
	neon_city = { Id = "neon_city", Name = "Neon City", Implemented = false },
	moon_base = { Id = "moon_base", Name = "Moon Base", Implemented = false },
	volcano = { Id = "volcano", Name = "Volcano", Implemented = false },
	enchanted_forest = { Id = "enchanted_forest", Name = "Enchanted Forest", Implemented = false },
	cloud_kingdom = { Id = "cloud_kingdom", Name = "Cloud Kingdom", Implemented = false },
	deep_ocean = { Id = "deep_ocean", Name = "Deep Ocean", Implemented = false },
}

return HabitatThemeConfig
