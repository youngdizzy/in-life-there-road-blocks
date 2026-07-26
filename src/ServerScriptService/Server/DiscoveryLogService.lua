-- The Bestiary: records which Critter species a player has ever
-- discovered (owned or evolved into), independent of whether they still
-- own one right now. Undiscovered entries show as "???" client-side
-- instead of naming the Critter -- see GAME_DESIGN.md Phase 5: "this
-- creates curiosity."
--
-- Only the 6 fully-implemented species are listed (see
-- CritterDefinitions.lua); the 4 future stubs aren't obtainable yet, so
-- listing them as permanently-locked "???" entries would just be
-- frustrating rather than curiosity-inducing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CritterDefinitions = require(ReplicatedStorage.Config.CritterDefinitions)

local DiscoveryLogService = {}

local DISCOVERY_ORDER = { "pip", "blazebit", "mossy", "ripple", "nox", "wisp" }

function DiscoveryLogService.MarkDiscovered(profile, definitionId)
	profile.DiscoveredSpecies[definitionId] = true
end

function DiscoveryLogService.GetLog(profile)
	local log = {}
	for _, definitionId in ipairs(DISCOVERY_ORDER) do
		local definition = CritterDefinitions.Get(definitionId)
		local discovered = profile.DiscoveredSpecies[definitionId] == true

		table.insert(log, {
			DefinitionId = definitionId,
			Name = discovered and definition.Name or "???",
			Discovered = discovered,
			IsSecret = definition.IsSecret or false,
			DominantInfluence = discovered and definition.DominantInfluence or nil,
		})
	end
	return log
end

return DiscoveryLogService
