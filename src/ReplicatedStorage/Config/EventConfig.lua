-- Limited-time event framework (see monetization spec Phase 6). "eclipse"
-- ("First Eclipse") is the one fully wired test event -- see EventService
-- for the runtime that reads Active/StartTime/EndTime and applies
-- EclipseShadowBonusPerAction / grants the reward. The other three are
-- intentionally still schema-only (Active = false, nothing reads their
-- Critters/Items/Cosmetics/Currency/DiscoveryRules fields yet) -- proving
-- the architecture with one real event beats half-wiring four of them.
--
-- Active = true here is a manual "the event is running" switch, since v1
-- has no scheduler triggering events automatically -- a developer flips it
-- (or sets real StartTime/EndTime timestamps, which EventService also
-- checks) to test in Studio. See README "Testing Phase 6".

local EventConfig = {}

EventConfig.Events = {
	eclipse = {
		Id = "eclipse",
		Name = "First Eclipse",
		Description = "Moon-themed. A faint extra Shadow pull on everything you do.",
		Active = true,
		StartTime = nil, -- nil = no lower time bound; set a unix timestamp to test one
		EndTime = nil, -- nil = no upper time bound; set a unix timestamp to test one
		Critters = {},
		Items = { "moon_shard" },
		Cosmetics = {},
		Currency = nil,
		DiscoveryRules = {},

		-- Real runtime effect, applied by EventService/InfluenceService
		-- while the event is active.
		EclipseShadowBonusPerAction = 1,
		RewardGems = 50,
		RewardItemId = "moon_shard",
	},
	meteor = {
		Id = "meteor",
		Name = "Meteor Event",
		Description = "A meteor lands in the world with temporary mutation influences.",
		Active = false,
		StartTime = nil,
		EndTime = nil,
		Critters = {},
		Items = {},
		Cosmetics = {},
		Currency = nil,
		DiscoveryRules = {},
	},
	garden_festival = {
		Id = "garden_festival",
		Name = "Garden Festival",
		Description = "Nature Critters, plant-based evolution paths, seasonal cosmetics.",
		Active = false,
		StartTime = nil,
		EndTime = nil,
		Critters = {},
		Items = {},
		Cosmetics = {},
		Currency = nil,
		DiscoveryRules = {},
	},
	chaos_weekend = {
		Id = "chaos_weekend",
		Name = "Chaos Weekend",
		Description = "Unusual mutation combinations and strange discovery opportunities.",
		Active = false,
		StartTime = nil,
		EndTime = nil,
		Critters = {},
		Items = {},
		Cosmetics = {},
		Currency = nil,
		DiscoveryRules = {},
	},
}

return EventConfig
