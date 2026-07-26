-- Habitat themes. "default" and "vip" are the two real, selectable themes
-- in v1 -- see HabitatThemeService for ownership checking and
-- HabitatManager.ApplyVIPVisual/ClearVIPVisual for the actual render (the
-- same corner-post/badge visual from the VIP Habitat gamepass, now
-- something the player chooses to display rather than something forced on
-- automatically). The rest are future premium themes: real names, no
-- render path yet -- re-skinning the whole platform per theme needs its
-- own work in HabitatBuilder that hasn't been done.

local HabitatThemeConfig = {}

HabitatThemeConfig.Themes = {
	default = {
		Id = "default",
		Name = "Default",
		Implemented = true,
		RequiresGamepass = nil,
	},
	vip = {
		Id = "vip",
		Name = "VIP Golden",
		Implemented = true,
		RequiresGamepass = "VIPHabitat",
	},

	neon_city = { Id = "neon_city", Name = "Neon City", Implemented = false },
	moon_base = { Id = "moon_base", Name = "Moon Base", Implemented = false },
	volcano = { Id = "volcano", Name = "Volcano", Implemented = false },
	enchanted_forest = { Id = "enchanted_forest", Name = "Enchanted Forest", Implemented = false },
	cloud_kingdom = { Id = "cloud_kingdom", Name = "Cloud Kingdom", Implemented = false },
	deep_ocean = { Id = "deep_ocean", Name = "Deep Ocean", Implemented = false },
}

function HabitatThemeConfig.Get(id)
	return HabitatThemeConfig.Themes[id]
end

return HabitatThemeConfig
