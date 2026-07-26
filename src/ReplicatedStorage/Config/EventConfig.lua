-- Limited-time event framework (see monetization spec Phase 6). Data-only
-- schema + the four example events from the brief, all Active = false --
-- there is no EventService running any of this yet. This exists so the
-- shape (start/end time, event Critters/items/cosmetics/currency/discovery
-- rules) is settled before anyone builds the runtime piece.

local EventConfig = {}

EventConfig.Events = {
	eclipse = {
		Id = "eclipse",
		Name = "Eclipse Event",
		Description = "Moon-themed Critters and shadow evolution possibilities.",
		Active = false,
		StartTime = nil,
		EndTime = nil,
		Critters = {},
		Items = {},
		Cosmetics = {},
		Currency = nil,
		DiscoveryRules = {},
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
