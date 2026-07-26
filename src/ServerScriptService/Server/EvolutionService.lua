-- The evolution prototype: when a Critter's Growth meter crosses the
-- threshold, decides the outcome from accumulated Influence (or the Secret
-- condition), permanently transforms the Critter, and tells the client to
-- play the reveal. Entirely server-decided -- the client only animates
-- whatever result this module already committed to the profile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CritterDefinitions = require(ReplicatedStorage.Config.CritterDefinitions)
local GrowthConfig = require(ReplicatedStorage.Config.GrowthConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)
local CritterService = require(script.Parent.CritterService)
local GrowthService = require(script.Parent.GrowthService)
local HabitatManager = require(script.Parent.HabitatManager)
local DiscoveryLogService = require(script.Parent.DiscoveryLogService)

local EvolutionService = {}

-- Fixed priority used only to break an exact tie (e.g. a Critter raised
-- entirely on Plain Kibble, which carries no Influence at all). Keeps the
-- outcome deterministic without needing a "what if everything is 0" special
-- case anywhere else.
local OUTCOME_BY_INFLUENCE = {
	Fire = "blazebit",
	Water = "ripple",
	Nature = "mossy",
	Shadow = "nox",
}
local PRIORITY_ORDER = { "Fire", "Water", "Nature", "Shadow" }

local function pickElementalOutcome(influences)
	local best = PRIORITY_ORDER[1]
	for _, influenceType in ipairs(PRIORITY_ORDER) do
		if (influences[influenceType] or 0) > (influences[best] or 0) then
			best = influenceType
		end
	end
	return OUTCOME_BY_INFLUENCE[best]
end

-- Call after any action that adds Growth Points. No-ops unless the
-- Critter just crossed the threshold, hasn't already evolved, and its own
-- species definition actually lists possible evolutions -- e.g. a second
-- Critter granted directly as "mossy" (see MilestoneService) is already a
-- final form and should just mature, not re-roll into "blazebit" because
-- its Fire Influence happened to climb. Only definitions with an
-- EvolvesInto list (currently just "pip") are eligible at all.
function EvolutionService.CheckAndEvolve(player, profile, record)
	if record.EvolvedInto or not GrowthService.IsReadyToEvolve(record) then
		return
	end

	local currentDefinition = CritterDefinitions.Get(record.DefinitionId)
	if not currentDefinition or not currentDefinition.EvolvesInto then
		return
	end

	local outcomeId
	if record.MysteryMushroomFeeds >= GrowthConfig.SecretUnlock.MinFeeds then
		outcomeId = "wisp"
	else
		outcomeId = pickElementalOutcome(record.Influences)
	end

	local definition = CritterDefinitions.Get(outcomeId)
	assert(definition, "EvolutionService: unknown outcome " .. tostring(outcomeId))

	-- Snapshot what's about to be overwritten. Nothing consumes this yet --
	-- it's the foundation an evolution reroll/"second chance" system would
	-- need (see the monetization spec Phase 5), captured now so that data
	-- isn't lost by the time such a system exists. Building the actual
	-- reroll flow (an item, a remote, a UI) with no reroll mechanic to
	-- attach it to would just be unfinished surface area.
	table.insert(record.EvolutionHistory, {
		Timestamp = os.time(),
		FromDefinitionId = record.DefinitionId,
		ToDefinitionId = outcomeId,
		GrowthPoints = record.GrowthPoints,
		Influences = {
			Fire = record.Influences.Fire,
			Water = record.Influences.Water,
			Nature = record.Influences.Nature,
			Shadow = record.Influences.Shadow,
		},
	})

	-- The presentation sequence: the triggering Feed/Play/Item action
	-- already played its own reaction moments ago (see InfluenceService/
	-- MutationItemService) -- that's "Pip reacts." From here: a short
	-- buildup on the *outgoing* model, then the swap + burst together, then
	-- the reveal popup. "Do not make the sequence too long" -- the buildup
	-- is under 2 seconds and this whole function only runs once per
	-- evolution, ever, for a given Critter.
	local plot = HabitatManager.GetHabitatForOwner(player.UserId)
	if plot then
		local buildupSeconds = CritterService.PlayEvolutionBuildup(plot, definition.HeadNubColor)
		if buildupSeconds > 0 then
			task.wait(buildupSeconds)
		end
	end

	record.DefinitionId = outcomeId
	record.EvolvedInto = outcomeId
	record.Stage = "Evolved"
	record.Name = definition.Name
	DiscoveryLogService.MarkDiscovered(profile, outcomeId)

	if plot then
		CritterService.PlayEvolutionEffect(plot, definition.HeadNubColor)
		CritterService.RefreshVisual(plot, profile)
	end

	Remotes.get("EvolutionReveal"):FireClient(player, {
		Name = definition.Name,
		Description = definition.Description,
		IsSecret = definition.IsSecret or false,
		DominantInfluence = definition.DominantInfluence,
	})
end

return EvolutionService
