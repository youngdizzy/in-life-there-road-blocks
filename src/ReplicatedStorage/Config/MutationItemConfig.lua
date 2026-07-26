-- Mystery Mutation Items. Each nudges a Critter's hidden Influence values
-- directly -- a meaningful, deliberate choice, not an instant rare-Critter
-- grant (see GAME_DESIGN.md "Monetization Philosophy"). Acquired via
-- DiscoveryService's Rare Discovery roll (see MonetizationConfig.Discovery),
-- consumed via MutationItemService.UseItem, stored via InventoryService.
--
-- InfluenceType is one of the four real Influence types, or "All" for a
-- small nudge to all four at once (Void Candy's "unstable" flavor). There
-- is no separate Void/Light/Cosmic Influence type -- adding one would mean
-- new evolution outcomes and touching evolution/UI code throughout the
-- project for two items' flavor text, which is exactly the kind of
-- overbuilding this project avoids. The flavor text owns the theme; the
-- mechanics stay inside the existing four Influences.

local MutationItemConfig = {}

MutationItemConfig.Items = {
	strange_seed = {
		Id = "strange_seed",
		Name = "Strange Seed",
		Description = "Sprouted overnight in a place nothing should grow.",
		InfluenceType = "Nature",
		InfluenceAmount = 6,
		EligibleCritters = {}, -- empty = any Critter that hasn't evolved yet
		Rarity = "Common",
		Implemented = true,
	},
	ember_core = {
		Id = "ember_core",
		Name = "Ember Core",
		Description = "Warm no matter how long it sits in your pocket.",
		InfluenceType = "Fire",
		InfluenceAmount = 6,
		EligibleCritters = {},
		Rarity = "Common",
		Implemented = true,
	},
	moon_shard = {
		Id = "moon_shard",
		Name = "Moon Shard",
		Description = "Cold, faintly glowing, and a little unsettling.",
		InfluenceType = "Shadow",
		InfluenceAmount = 6,
		EligibleCritters = {},
		Rarity = "Uncommon",
		Implemented = true,
	},
	starfruit = {
		Id = "starfruit",
		Name = "Starfruit",
		Description = "Tastes like somewhere much, much colder.",
		InfluenceType = "Water",
		InfluenceAmount = 6,
		EligibleCritters = {},
		Rarity = "Common",
		Implemented = true,
	},
	void_candy = {
		Id = "void_candy",
		Name = "Void Candy",
		Description = "Nobody's sure what this does. Maybe that's the point.",
		InfluenceType = "All",
		InfluenceAmount = 3,
		EligibleCritters = {},
		Rarity = "Rare",
		Implemented = true,
	},
}

function MutationItemConfig.Get(id)
	return MutationItemConfig.Items[id]
end

-- Every implemented item's Id, cached at require-time -- this is the pool
-- DiscoveryService rolls a random grant from.
MutationItemConfig.ImplementedIds = {}
for id, item in pairs(MutationItemConfig.Items) do
	if item.Implemented then
		table.insert(MutationItemConfig.ImplementedIds, id)
	end
end

return MutationItemConfig
