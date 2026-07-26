-- Mystery Mutation Items (see monetization spec Phase 5). Data-only stub:
-- there is no inventory/item-use system yet for these to plug into (see
-- GAME_DESIGN.md/README "Monetization Phase Status"). Building the grant +
-- consume + effect flow now, with no inventory backing it, would be the
-- "huge unfinished version" the brief explicitly says not to build.
-- This table exists so the shape of the catalog is decided in advance.

local MutationItemConfig = {}

MutationItemConfig.Items = {
	strange_seed = { Id = "strange_seed", Name = "Strange Seed", Implemented = false },
	ember_core = { Id = "ember_core", Name = "Ember Core", Implemented = false },
	moon_shard = { Id = "moon_shard", Name = "Moon Shard", Implemented = false },
	void_candy = { Id = "void_candy", Name = "Void Candy", Implemented = false },
	starfruit = { Id = "starfruit", Name = "Starfruit", Implemented = false },
}

return MutationItemConfig
