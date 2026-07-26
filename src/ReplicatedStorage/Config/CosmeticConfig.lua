-- Cosmetic effect catalog. Attaching one to a Critter never touches
-- Critter logic (growth/influence/evolution) -- see CosmeticService.Attach,
-- which is the only place that knows how to render any of these.
--
-- Only a couple are fully implemented; the rest are stubs (Implemented =
-- false) that prove the catalog scales without pretending to be finished
-- content. Follows the same pattern as CritterDefinitions' future roster.

local CosmeticConfig = {}

CosmeticConfig.Cosmetics = {
	sparkles = {
		Id = "sparkles",
		Name = "Sparkle Trail",
		Implemented = true,
		Description = "A gentle trail of drifting sparkles.",
	},
	golden_eyes = {
		Id = "golden_eyes",
		Name = "Golden Eyes",
		Implemented = true,
		Description = "Eyes that catch the light like gold.",
	},

	galaxy_aura = { Id = "galaxy_aura", Name = "Galaxy Aura", Implemented = false, Description = "(future)" },
	neon_outline = { Id = "neon_outline", Name = "Neon Outline", Implemented = false, Description = "(future)" },
	rainbow_particles = {
		Id = "rainbow_particles",
		Name = "Rainbow Particles",
		Implemented = false,
		Description = "(future)",
	},
	shadow_flames = { Id = "shadow_flames", Name = "Shadow Flames", Implemented = false, Description = "(future)" },
}

function CosmeticConfig.Get(id)
	return CosmeticConfig.Cosmetics[id]
end

return CosmeticConfig
