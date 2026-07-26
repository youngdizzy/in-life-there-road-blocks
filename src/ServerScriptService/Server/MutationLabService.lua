-- The Mutation Lab gamepass: a qualitative, gamepass-gated readout of a
-- Critter's Influences. Deliberately gives *more* information than the
-- free dominant-influence hint (GrowthService.GetDominantHint) without
-- ever stating exact numbers or naming the eventual evolution outcome --
-- "informed experimentation, not spoilers" (see the monetization spec).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CritterDefinitions = require(ReplicatedStorage.Config.CritterDefinitions)
local GrowthConfig = require(ReplicatedStorage.Config.GrowthConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)
local DataManager = require(script.Parent.DataManager)
local CritterService = require(script.Parent.CritterService)

local MutationLabService = {}

local function qualitativeLabel(value)
	if value <= 0 then
		return "none yet"
	elseif value < 8 then
		return "faint"
	elseif value < 20 then
		return "noticeable"
	elseif value < 40 then
		return "strong"
	else
		return "overwhelming"
	end
end

-- Returns nil, "reason" if the player doesn't own the gamepass or has no
-- active Critter to analyze. Never reveals which Critter an Influence
-- level will actually evolve into.
function MutationLabService.GetAnalysis(player)
	local profile = DataManager.GetProfile(player)
	if not profile then
		return nil, "No profile loaded"
	end

	if not profile.OwnedGamepasses["MutationLab"] then
		return nil, "requires_gamepass"
	end

	local record = CritterService.GetActiveCritter(profile)
	if not record then
		return nil, "No active Critter"
	end

	local breakdown = {}
	for _, influenceType in ipairs(CritterDefinitions.InfluenceTypes) do
		breakdown[influenceType] = qualitativeLabel(record.Influences[influenceType] or 0)
	end

	return {
		Breakdown = breakdown,
		DiscoveriesFound = profile.Discoveries,
		GrowthPercent = math.floor((record.GrowthPoints / GrowthConfig.EvolveThreshold) * 100),
		Evolved = record.EvolvedInto ~= nil,
	}
end

function MutationLabService.Init()
	Remotes.get("GetMutationAnalysis").OnServerInvoke = function(player)
		return MutationLabService.GetAnalysis(player)
	end
end

return MutationLabService
