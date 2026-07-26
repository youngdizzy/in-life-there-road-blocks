-- The starter food menu. Small and purposeful on purpose (see
-- GAME_DESIGN.md Development Principle #7/#11) -- every food exists to
-- push a specific Influence, not to pad out a catalog.
--
-- v1 has no currency/economy yet (Development Principle #12), so every
-- food is freely selectable; FeedCooldownSeconds (GrowthConfig) is what
-- stops spam-feeding, not a resource cost.

local FoodConfig = {}

FoodConfig.Foods = {
	plain_kibble = {
		Id = "plain_kibble",
		Name = "Plain Kibble",
		Description = "Reliable, boring, gets the job done.",
		InfluenceEffects = {},
		HungerRestore = 40,
		GrowthPoints = 5,
	},
	spicy_pepper = {
		Id = "spicy_pepper",
		Name = "Spicy Pepper",
		Description = "Pip's eyes water. Pip asks for another one.",
		InfluenceEffects = { Fire = 4 },
		HungerRestore = 25,
		GrowthPoints = 6,
	},
	kelp_snack = {
		Id = "kelp_snack",
		Name = "Kelp Snack",
		Description = "Cold, a little salty, disappears fast.",
		InfluenceEffects = { Water = 4 },
		HungerRestore = 25,
		GrowthPoints = 6,
	},
	berry_mix = {
		Id = "berry_mix",
		Name = "Berry Mix",
		Description = "Handful of forest berries. Some crunch is normal.",
		InfluenceEffects = { Nature = 4 },
		HungerRestore = 25,
		GrowthPoints = 6,
	},
	mystery_mushroom = {
		Id = "mystery_mushroom",
		Name = "Mystery Mushroom",
		Description = "You are not entirely sure where this came from.",
		InfluenceEffects = { Shadow = 3 },
		HungerRestore = 15,
		GrowthPoints = 6,
		IsMysterious = true,
	},
}

function FoodConfig.Get(id)
	return FoodConfig.Foods[id]
end

return FoodConfig
