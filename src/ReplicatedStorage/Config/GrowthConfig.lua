-- Growth pacing: how fast the meter fills, what counts as each visible
-- stage, and the interaction cooldowns that stop spam-feeding/playing
-- from being the "real" strategy instead of variety.

local GrowthConfig = {}

GrowthConfig.Stages = {
	{ Name = "Baby", MinPoints = 0 },
	{ Name = "Juvenile", MinPoints = 40 },
	{ Name = "Ready to Evolve", MinPoints = 90 },
}

-- At or above this many Growth Points, the next Feed/Play action that
-- crosses it triggers EvolutionService to resolve the outcome.
GrowthConfig.EvolveThreshold = 100

GrowthConfig.FeedCooldownSeconds = 20
GrowthConfig.PlayCooldownSeconds = 20

GrowthConfig.MaxHunger = 100
GrowthConfig.MaxHappiness = 100

-- How far ahead the top Influence needs to be over the runner-up before the
-- UI is allowed to hint at it. Keeps early game a genuine mystery instead
-- of a spoiler the moment the player feeds one spicy pepper.
GrowthConfig.DominanceHintMargin = 8

-- The Secret evolution path: feed the mysterious food this many times
-- before Pip matures and it evolves into the Secret Critter instead of
-- whichever elemental Influence happens to be highest.
GrowthConfig.SecretUnlock = {
	RequiredFoodId = "mystery_mushroom",
	MinFeeds = 3,
}

function GrowthConfig.GetStage(growthPoints)
	local current = GrowthConfig.Stages[1]
	for _, stage in ipairs(GrowthConfig.Stages) do
		if growthPoints >= stage.MinPoints then
			current = stage
		end
	end
	return current.Name
end

function GrowthConfig.GetStageThreshold(stageName)
	for _, stage in ipairs(GrowthConfig.Stages) do
		if stage.Name == stageName then
			return stage.MinPoints
		end
	end
	return nil
end

-- The first meaningful Pip growth milestone (see MilestoneService): reads
-- the "Ready to Evolve" stage's own threshold rather than duplicating the
-- number, so the two can never quietly drift apart.
GrowthConfig.SecondCritterMilestoneStage = "Ready to Evolve"

return GrowthConfig
