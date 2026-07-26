-- Single source of truth for every Gamepass ID, Developer Product ID, and
-- monetization balance number in the game. Nothing outside this file
-- should ever contain a hardcoded Gamepass/Product id or a monetization
-- multiplier -- see GAME_DESIGN.md "Monetization Philosophy".
--
-- All Ids are placeholders (0) until real ones are created in the Creator
-- Dashboard for this experience. See README.md "Monetization setup".

local MonetizationConfig = {}

-- ============================================================
-- Gamepasses (one-time, permanent)
-- ============================================================
MonetizationConfig.Gamepasses = {
	Luck2x = {
		Id = 0,
		Name = "2x Luck",
		Description = "Doubles your luck bonus toward rare discoveries.",
	},
	GrowthBoost = {
		Id = 0,
		Name = "Growth Boost",
		Description = "Grows faster from every Feed and Play action, forever.",
	},
	VIPHabitat = {
		Id = 0,
		Name = "VIP Habitat",
		Description = "A glowing VIP ring around your habitat, a VIP badge, and bragging rights.",
	},
	ExtraCritterSlots = {
		Id = 0,
		Name = "Extra Critter Slots",
		Description = "Room for more Critters in your collection.",
		BonusSlots = 3,
	},
	AutoCare = {
		Id = 0,
		Name = "Auto-Care",
		Description = "Automatically tops up Hunger and Happiness so your Critter is never neglected.",
	},
	MutationLab = {
		Id = 0,
		Name = "Mutation Lab",
		Description = "Analyze your Critter's Influences in detail -- informed guessing, not spoilers.",
	},
}

-- ============================================================
-- Developer Products (repeatable, consumable)
-- ============================================================
MonetizationConfig.DevProducts = {
	GemsSmall = { Id = 0, Name = "Small Gem Pack", Gems = 500 },
	GemsMedium = { Id = 0, Name = "Medium Gem Pack", Gems = 2500 },
	GemsLarge = { Id = 0, Name = "Large Gem Pack", Gems = 6000 },

	GrowthBoost15Min = {
		Id = 0,
		Name = "Growth Boost (15 min)",
		BoostType = "GrowthBoost",
		DurationSeconds = 15 * 60,
	},
	GrowthBoost1Hour = {
		Id = 0,
		Name = "Growth Boost (1 hour)",
		BoostType = "GrowthBoost",
		DurationSeconds = 60 * 60,
	},
	LuckPotion30Min = {
		Id = 0,
		Name = "Luck Potion (30 min)",
		BoostType = "LuckPotion",
		DurationSeconds = 30 * 60,
	},

	SparkleTrailCosmetic = {
		Id = 0,
		Name = "Sparkle Trail",
		CosmeticId = "sparkles",
	},
}

-- Reverse lookup by developer product Id, built at require-time. Ignores
-- placeholder (0) ids so a bunch of unfinished products don't collide with
-- each other before real ids are assigned.
MonetizationConfig.DevProductById = {}
for key, product in pairs(MonetizationConfig.DevProducts) do
	if type(product.Id) == "number" and product.Id > 0 then
		MonetizationConfig.DevProductById[product.Id] = key
	end
end

-- ============================================================
-- Balance numbers. Every multiplier in the game reads from here, never
-- a magic number inline (see LuckService/GrowthService).
-- ============================================================

-- Bonuses stack ADDITIVELY on top of a base of 1.0, not multiplicatively,
-- specifically so a gamepass + a temporary potion never compounds into an
-- absurd number (1.0 + 1.0 + 1.0 = 3x, never 1 * 2 * 2 = 4x and climbing).
MonetizationConfig.Luck = {
	GamepassBonus = 1.0, -- +100% (2x total) with 2x Luck gamepass
	PotionBonus = 1.0, -- +100% (additional) while a Luck Potion is active
}

MonetizationConfig.Growth = {
	GamepassBonus = 1.0, -- +100% (2x total) with Growth Boost gamepass
	BoostBonus = 1.0, -- +100% (additional) while a temporary Growth Boost is active
}

MonetizationConfig.CritterSlots = {
	Base = 1, -- v1 raises exactly one Critter at a time by design; this is
	-- the number that grows once a real multi-Critter collection loop exists.
}

MonetizationConfig.AutoCare = {
	IntervalSeconds = 30,
	HungerRestore = 10,
	HappinessRestore = 10,
}

-- Base chance (0-1) of a "Rare Discovery" on any single Feed/Play action,
-- before luck is applied. See DiscoveryService. Kept low and capped so
-- Luck feels valuable without being the whole game.
MonetizationConfig.Discovery = {
	BaseChance = 0.05,
	MaxChance = 0.35,
	BonusGrowthPoints = 8,
}

return MonetizationConfig
