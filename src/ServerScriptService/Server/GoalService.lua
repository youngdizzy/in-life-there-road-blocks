-- A small, fixed list of early goals so a new player always knows "what
-- can I do next" (see GAME_DESIGN.md Phase 9). Deliberately not a quest
-- system -- every goal here is derived from state that already exists
-- (no new tracked fields, no rewards, no chains); it's a checklist, not a
-- progression system in its own right.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GrowthConfig = require(ReplicatedStorage.Config.GrowthConfig)

local GoalService = {}

local JUVENILE_THRESHOLD = GrowthConfig.GetStageThreshold("Juvenile")

function GoalService.GetGoals(profile)
	local anyFed, anyPlayed, anyReachedJuvenile, anyEvolved = false, false, false, false
	for _, record in pairs(profile.Critters) do
		if record.LastFeedAt > 0 then
			anyFed = true
		end
		if record.LastPlayAt > 0 then
			anyPlayed = true
		end
		if record.GrowthPoints >= JUVENILE_THRESHOLD then
			anyReachedJuvenile = true
		end
		if record.EvolvedInto ~= nil then
			anyEvolved = true
		end
	end

	return {
		{ Id = "feed", Text = "Feed your Critter for the first time", Done = anyFed },
		{ Id = "play", Text = "Play at an Environment Zone", Done = anyPlayed },
		{ Id = "juvenile", Text = "Reach the Juvenile growth stage", Done = anyReachedJuvenile },
		{ Id = "second_critter", Text = "Unlock your second Critter", Done = profile.SecondCritterGranted },
		{ Id = "evolution", Text = "Discover your first evolution", Done = anyEvolved },
		-- profile.Discoveries is the Rare Discovery counter; every Rare
		-- Discovery in v1 also grants a Mutation Item (see
		-- MonetizationConfig.Discovery.GrantsMutationItem), so it doubles as
		-- an accurate "found a mutation item at least once" signal without
		-- needing a separate counter that would drift if an item is later
		-- fully consumed.
		{ Id = "mutation_item", Text = "Find your first Mutation Item", Done = profile.Discoveries > 0 },
	}
end

return GoalService
