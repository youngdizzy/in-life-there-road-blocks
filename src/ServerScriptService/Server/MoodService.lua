-- Turns Hunger/Happiness/Growth into one of a small, fixed set of moods a
-- player can read at a glance (see GAME_DESIGN.md Phase 1: "the player
-- should be able to understand Pip's current state at a glance"). Not a
-- needs simulator -- just a few clear buckets computed from state that
-- already exists, no new hidden numbers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GrowthConfig = require(ReplicatedStorage.Config.GrowthConfig)

local MoodService = {}

local MOODS = {
	Hungry = { Label = "Hungry", Emoji = "🍽️" },
	Tired = { Label = "Tired", Emoji = "😴" },
	Growing = { Label = "Growing", Emoji = "✨" },
	Excited = { Label = "Excited", Emoji = "🤩" },
	Happy = { Label = "Happy", Emoji = "😊" },
	Curious = { Label = "Curious", Emoji = "🤔" },
}

-- Ordered checks -- the first one that matches wins, so e.g. a starving
-- Critter always reads as Hungry even if it's also close to evolving.
function MoodService.GetMood(record)
	if record.Hunger < 30 then
		return MOODS.Hungry
	end

	if record.Happiness < 30 then
		return MOODS.Tired
	end

	if not record.EvolvedInto and record.GrowthPoints / GrowthConfig.EvolveThreshold >= 0.8 then
		return MOODS.Growing
	end

	if record.Hunger > 80 and record.Happiness > 80 then
		return MOODS.Excited
	end

	if record.Happiness > 60 then
		return MOODS.Happy
	end

	return MOODS.Curious
end

return MoodService
