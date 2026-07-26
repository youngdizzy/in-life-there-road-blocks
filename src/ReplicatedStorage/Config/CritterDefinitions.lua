-- Data-driven Critter catalog. Adding a new Critter should mean adding a
-- table entry here (plus a spawn shape in CritterService if it needs a
-- unique silhouette) -- never touching InfluenceService, GrowthService,
-- EvolutionService, or DataManager.
--
-- Every evolution of Pip keeps the same round-body/big-eyes shape language
-- (see GAME_DESIGN.md "Placeholder Art Policy") and is only distinguished
-- by color and a small elemental accessory, so the model builder in
-- CritterService only needs BodyColor/AccessoryColor/AccessoryShape/Scale.

local CritterDefinitions = {}

CritterDefinitions.InfluenceTypes = { "Fire", "Water", "Nature", "Shadow" }

CritterDefinitions.Critters = {
	pip = {
		Id = "pip",
		Name = "Pip",
		Implemented = true,
		IsStarter = true,
		Description = "Curious, hungry, and a little bit silly.",
		BodyColor = Color3.fromRGB(255, 221, 140),
		AccessoryColor = nil,
		AccessoryShape = nil,
		BaseScale = 1.0,
		DominantInfluence = nil,
		EvolvesInto = { "blazebit", "mossy", "nox", "ripple", "wisp" },
	},

	blazebit = {
		Id = "blazebit",
		Name = "Blazebit",
		Implemented = true,
		Description = "Warm to the touch and always a little too excited.",
		BodyColor = Color3.fromRGB(255, 140, 60),
		AccessoryColor = Color3.fromRGB(255, 200, 60),
		AccessoryShape = "Flame",
		BaseScale = 1.25,
		DominantInfluence = "Fire",
	},

	mossy = {
		Id = "mossy",
		Name = "Mossy",
		Implemented = true,
		Description = "Smells like rain. Occasionally sprouts a leaf.",
		BodyColor = Color3.fromRGB(110, 190, 90),
		AccessoryColor = Color3.fromRGB(70, 140, 60),
		AccessoryShape = "Leaf",
		BaseScale = 1.25,
		DominantInfluence = "Nature",
	},

	nox = {
		Id = "nox",
		Name = "Nox",
		Implemented = true,
		Description = "Shows up in photos a half-second late.",
		BodyColor = Color3.fromRGB(70, 60, 90),
		AccessoryColor = Color3.fromRGB(150, 90, 210),
		AccessoryShape = "Spike",
		BaseScale = 1.25,
		DominantInfluence = "Shadow",
	},

	ripple = {
		Id = "ripple",
		Name = "Ripple",
		Implemented = true,
		Description = "Leaves a small puddle wherever it stands.",
		BodyColor = Color3.fromRGB(90, 170, 230),
		AccessoryColor = Color3.fromRGB(180, 225, 245),
		AccessoryShape = "Droplet",
		BaseScale = 1.25,
		DominantInfluence = "Water",
	},

	-- The Secret outcome: proving that "rare combinations -> secret
	-- outcomes" is real. See GrowthConfig.SecretUnlock for the condition.
	wisp = {
		Id = "wisp",
		Name = "Wisp",
		Implemented = true,
		IsSecret = true,
		Description = "Nobody quite believes Wisp used to be a Pip.",
		BodyColor = Color3.fromRGB(40, 35, 55),
		AccessoryColor = Color3.fromRGB(120, 240, 230),
		AccessoryShape = "Spark",
		BaseScale = 1.3,
		DominantInfluence = "Secret",
	},

	-- Future roster. Stubs only: enough to prove the architecture scales,
	-- nothing implemented. See GAME_DESIGN.md "Future Critter Roster".
	pebble = { Id = "pebble", Name = "Pebble", Implemented = false, Description = "Earth Critter (future)." },
	zappy = { Id = "zappy", Name = "Zappy", Implemented = false, Description = "Electric Critter (future)." },
	glimmer = { Id = "glimmer", Name = "Glimmer", Implemented = false, Description = "Light Critter (future)." },
	munch = { Id = "munch", Name = "Munch", Implemented = false, Description = "Food-themed Critter (future)." },
}

function CritterDefinitions.Get(id)
	return CritterDefinitions.Critters[id]
end

return CritterDefinitions
