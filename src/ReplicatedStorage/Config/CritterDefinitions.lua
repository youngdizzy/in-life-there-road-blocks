-- Data-driven Critter catalog. Adding a new Critter should mean adding a
-- table entry here (plus, if it needs a genuinely new silhouette piece,
-- a new HeadNubShape/TailShape case in CritterService's model builder) --
-- never touching InfluenceService, GrowthService, EvolutionService, or
-- DataManager.
--
-- Every evolution of Pip keeps the same silhouette *language* -- egg-round
-- two-tone body, a pair of head-nubs, stubby feet, a small tail, big eyes
-- (see GAME_DESIGN.md "Placeholder Art Policy" / "Making Pip Feel Alive")
-- -- and is distinguished by color, head-nub shape, eye color, and one
-- optional ambient particle. See CritterService for what each field drives.

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
		AccentColor = Color3.fromRGB(255, 241, 214), -- lighter belly/underside
		EyeColor = nil, -- nil = default white sclera
		HeadNubShape = "Round",
		HeadNubColor = Color3.fromRGB(235, 195, 110),
		AmbientParticle = nil,
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
		AccentColor = Color3.fromRGB(255, 205, 120),
		EyeColor = nil,
		HeadNubShape = "Flame",
		HeadNubColor = Color3.fromRGB(255, 210, 70),
		AmbientParticle = "Embers",
		BaseScale = 1.25,
		DominantInfluence = "Fire",
	},

	mossy = {
		Id = "mossy",
		Name = "Mossy",
		Implemented = true,
		Description = "Smells like rain. Occasionally sprouts a leaf.",
		BodyColor = Color3.fromRGB(110, 190, 90),
		AccentColor = Color3.fromRGB(212, 230, 180),
		EyeColor = nil,
		HeadNubShape = "Leaf",
		HeadNubColor = Color3.fromRGB(70, 140, 60),
		AmbientParticle = "Petals",
		BaseScale = 1.25,
		DominantInfluence = "Nature",
	},

	nox = {
		Id = "nox",
		Name = "Nox",
		Implemented = true,
		Description = "Shows up in photos a half-second late.",
		BodyColor = Color3.fromRGB(70, 60, 90),
		AccentColor = Color3.fromRGB(102, 88, 122),
		EyeColor = Color3.fromRGB(190, 120, 255), -- glowing, replaces the default white sclera
		HeadNubShape = "Horn",
		HeadNubColor = Color3.fromRGB(150, 90, 210),
		AmbientParticle = "Smoke",
		BaseScale = 1.25,
		DominantInfluence = "Shadow",
	},

	ripple = {
		Id = "ripple",
		Name = "Ripple",
		Implemented = true,
		Description = "Leaves a small puddle wherever it stands.",
		BodyColor = Color3.fromRGB(90, 170, 230),
		AccentColor = Color3.fromRGB(205, 235, 250),
		EyeColor = nil,
		HeadNubShape = "Fin",
		HeadNubColor = Color3.fromRGB(150, 210, 245),
		AmbientParticle = "Bubbles",
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
		AccentColor = Color3.fromRGB(62, 55, 82),
		EyeColor = Color3.fromRGB(140, 255, 240),
		HeadNubShape = "Spark",
		HeadNubColor = Color3.fromRGB(120, 240, 230),
		AmbientParticle = "Motes",
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
