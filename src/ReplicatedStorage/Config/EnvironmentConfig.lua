-- The four Environment Zones in every habitat. Playing with Pip at a zone
-- is the second of the two v1 Influence actions (feeding is the first).

local EnvironmentConfig = {}

EnvironmentConfig.Zones = {
	fire_corner = {
		Id = "fire_corner",
		Name = "Fire Corner",
		Description = "A small crackling campfire.",
		InfluenceEffects = { Fire = 5 },
		HappinessGain = 15,
		GrowthPoints = 6,
		Color = Color3.fromRGB(230, 120, 50),
	},
	water_pool = {
		Id = "water_pool",
		Name = "Water Pool",
		Description = "A shallow, cool pool.",
		InfluenceEffects = { Water = 5 },
		HappinessGain = 15,
		GrowthPoints = 6,
		Color = Color3.fromRGB(80, 160, 220),
	},
	nature_patch = {
		Id = "nature_patch",
		Name = "Nature Patch",
		Description = "Overgrown, a little wild.",
		InfluenceEffects = { Nature = 5 },
		HappinessGain = 15,
		GrowthPoints = 6,
		Color = Color3.fromRGB(90, 170, 80),
	},
	shadow_nook = {
		Id = "shadow_nook",
		Name = "Shadow Nook",
		Description = "Quiet. Colder than it should be.",
		InfluenceEffects = { Shadow = 5 },
		HappinessGain = 15,
		GrowthPoints = 6,
		Color = Color3.fromRGB(60, 50, 80),
	},
}

function EnvironmentConfig.Get(id)
	return EnvironmentConfig.Zones[id]
end

return EnvironmentConfig
