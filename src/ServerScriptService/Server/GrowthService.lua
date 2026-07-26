-- Tracks the visible Growth meter/stage and turns accumulated hidden
-- Influence into a soft, non-spoiling hint for the UI. Evolution itself
-- (crossing the threshold and choosing an outcome) lives in
-- EvolutionService -- this module only manages the meter and the hint.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GrowthConfig = require(ReplicatedStorage.Config.GrowthConfig)

local GrowthService = {}

local HINTS = {
	Fire = "Pip seems to really like warm, spicy things...",
	Water = "Pip keeps wandering back to the water...",
	Nature = "Pip's been spending a lot of time in the leaves...",
	Shadow = "Pip's gotten a little quieter, a little stranger...",
}

function GrowthService.AddGrowthPoints(record, points)
	record.GrowthPoints += points
	record.Stage = GrowthConfig.GetStage(record.GrowthPoints)
end

function GrowthService.IsReadyToEvolve(record)
	return record.GrowthPoints >= GrowthConfig.EvolveThreshold
end

-- Only reveals a hint once one Influence is clearly ahead of the others
-- (see GrowthConfig.DominanceHintMargin). Early game stays a real mystery
-- instead of spoiling itself after one feeding.
function GrowthService.GetDominantHint(record)
	local sorted = {}
	for influenceType, value in pairs(record.Influences) do
		table.insert(sorted, { Type = influenceType, Value = value })
	end
	table.sort(sorted, function(a, b)
		return a.Value > b.Value
	end)

	if #sorted < 1 or sorted[1].Value <= 0 then
		return nil
	end

	local runnerUpValue = sorted[2] and sorted[2].Value or 0
	if sorted[1].Value - runnerUpValue < GrowthConfig.DominanceHintMargin then
		return nil
	end

	return HINTS[sorted[1].Type]
end

return GrowthService
