-- Tracks the visible Growth meter/stage and turns accumulated hidden
-- Influence into a soft, non-spoiling hint for the UI. Evolution itself
-- (crossing the threshold and choosing an outcome) lives in
-- EvolutionService -- this module only manages the meter and the hint.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GrowthConfig = require(ReplicatedStorage.Config.GrowthConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local BoostService = require(script.Parent.BoostService)

local GrowthService = {}

local HINTS = {
	Fire = "Pip seems to really like warm, spicy things...",
	Water = "Pip keeps wandering back to the water...",
	Nature = "Pip's been spending a lot of time in the leaves...",
	Shadow = "Pip's gotten a little quieter, a little stranger...",
}

-- Additive stacking over a base of 1.0 (see MonetizationConfig.Growth), same
-- reasoning as LuckService: a permanent gamepass plus a temporary boost
-- should never compound into an ever-climbing multiplier.
function GrowthService.GetGrowthMultiplier(profile)
	local multiplier = 1.0

	if profile.OwnedGamepasses["GrowthBoost"] then
		multiplier += MonetizationConfig.Growth.GamepassBonus
	end

	if BoostService.IsActive(profile, "GrowthBoost") then
		multiplier += MonetizationConfig.Growth.BoostBonus
	end

	return multiplier
end

-- basePoints is the raw, un-boosted amount a food/zone is worth (see
-- FoodConfig/EnvironmentConfig) -- the multiplier is applied here, once,
-- so no caller ever has to remember to multiply it in themselves.
function GrowthService.AddGrowthPoints(profile, record, basePoints)
	record.GrowthPoints += basePoints * GrowthService.GetGrowthMultiplier(profile)
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
