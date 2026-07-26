-- The real second-Critter acquisition path (see GAME_DESIGN.md
-- "Monetization Phase Status" -- Extra Critter Slots is meaningless
-- without one). Deterministic and free-to-play: the first time Pip
-- reaches the "Ready to Evolve" stage, the player is granted a second
-- Critter. No RNG, no purchase required, one-time per profile.
--
-- Deliberately not a gacha/egg system -- just enough to make Critter
-- slots real. A richer acquisition system (discoverable eggs, event
-- drops, ...) can replace or extend this later without touching
-- CritterSlotService, which stays the one validated gate either way.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GrowthConfig = require(ReplicatedStorage.Config.GrowthConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)
local CritterSlotService = require(script.Parent.CritterSlotService)
local DiscoveryLogService = require(script.Parent.DiscoveryLogService)

local MilestoneService = {}

-- The specific second Critter granted. A friendly, fully-implemented
-- species (see CritterDefinitions) rather than a stub, so it's playable
-- the moment it's granted.
local SECOND_CRITTER_DEFINITION_ID = "mossy"
local SECOND_CRITTER_NAME = "Mossy"

local MILESTONE_POINTS = GrowthConfig.GetStageThreshold(GrowthConfig.SecondCritterMilestoneStage)

local function notify(player, message, kind)
	Remotes.get("Notify"):FireClient(player, { Text = message, Kind = kind or "info" })
end

-- Call after any action that adds Growth Points to the *starter* Pip
-- specifically (see the DefinitionId check) -- a second Critter's own
-- growth should never re-trigger this.
function MilestoneService.CheckFirstMilestone(player, profile, record)
	if profile.SecondCritterGranted then
		return
	end
	if record.DefinitionId ~= "pip" then
		return
	end
	if record.GrowthPoints < MILESTONE_POINTS then
		return
	end

	local uid, reason = CritterSlotService.AddCritter(profile, SECOND_CRITTER_DEFINITION_ID, SECOND_CRITTER_NAME)
	if not uid then
		-- No free slot (shouldn't happen at the default base of 2, but
		-- fails safely instead of granting past the cap if it somehow does).
		warn(("MilestoneService: could not grant second Critter to %s: %s"):format(player.Name, tostring(reason)))
		return
	end

	profile.SecondCritterGranted = true
	DiscoveryLogService.MarkDiscovered(profile, SECOND_CRITTER_DEFINITION_ID)
	notify(
		player,
		("🎉 %s discovered a new friend! %s joined your collection (see Collection)."):format(
			record.Name,
			SECOND_CRITTER_NAME
		),
		"success"
	)
end

return MilestoneService
