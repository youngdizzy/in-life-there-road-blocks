-- Builds the read-only client projection of a player's active Critter and
-- fires it down StateUpdate. The client never computes any of this itself
-- (Development Principle #5 / GAME_DESIGN.md "Server Authority") -- it only
-- displays whatever this module decided to send.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CritterDefinitions = require(ReplicatedStorage.Config.CritterDefinitions)
local GrowthConfig = require(ReplicatedStorage.Config.GrowthConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)
local CritterService = require(script.Parent.CritterService)
local GrowthService = require(script.Parent.GrowthService)
local CritterSlotService = require(script.Parent.CritterSlotService)
local BoostService = require(script.Parent.BoostService)
local CollectionService = require(script.Parent.CollectionService)
local EventService = require(script.Parent.EventService)
local HabitatThemeService = require(script.Parent.HabitatThemeService)
local MoodService = require(script.Parent.MoodService)
local DiscoveryLogService = require(script.Parent.DiscoveryLogService)
local GoalService = require(script.Parent.GoalService)
local HabitatManager = require(script.Parent.HabitatManager)

local StateService = {}

local BOOST_TYPES = { "GrowthBoost", "LuckPotion" }

function StateService.Push(player, profile)
	local record = CritterService.GetActiveCritter(profile)
	if not record then
		return
	end

	local definition = CritterDefinitions.Get(record.DefinitionId)

	local activeBoosts = {}
	for _, boostType in ipairs(BOOST_TYPES) do
		local remaining = BoostService.GetRemainingSeconds(profile, boostType)
		if remaining > 0 then
			activeBoosts[boostType] = remaining
		end
	end

	local activeEvents = {}
	for _, event in ipairs(EventService.GetActiveEvents()) do
		table.insert(activeEvents, {
			Id = event.Id,
			Name = event.Name,
			Description = event.Description,
			Claimed = EventService.HasClaimedReward(profile, event.Id),
		})
	end

	local mood = MoodService.GetMood(record)

	-- Keeps the in-world model's face (eyebrows/mouth) matching whatever
	-- the UI is about to show -- StateService.Push already fires on every
	-- action that could change Mood, so this is the one place that needs
	-- to know about it.
	local plot = HabitatManager.GetHabitatForOwner(player.UserId)
	if plot then
		CritterService.ApplyMood(plot, mood)
	end

	Remotes.get("StateUpdate"):FireClient(player, {
		Name = record.Name,
		Description = definition and definition.Description or "",
		Stage = record.Stage,
		GrowthPoints = record.GrowthPoints,
		GrowthThreshold = GrowthConfig.EvolveThreshold,
		Hunger = record.Hunger,
		Happiness = record.Happiness,
		Evolved = record.EvolvedInto ~= nil,
		DominantHint = record.EvolvedInto == nil and GrowthService.GetDominantHint(record) or nil,
		Mood = mood,

		Gems = profile.Gems,
		Discoveries = profile.Discoveries,
		OwnedGamepasses = profile.OwnedGamepasses,
		UnlockedCosmetics = profile.UnlockedCosmetics,
		EquippedCosmetic = record.EquippedCosmetic,
		CritterSlotsUsed = CritterSlotService.GetUsedSlots(profile),
		CritterSlotsMax = CritterSlotService.GetMaxSlots(profile),
		ActiveBoosts = activeBoosts,

		Collection = CollectionService.GetSummary(profile),
		Inventory = profile.Inventory,
		ActiveEvents = activeEvents,
		AvailableHabitatThemes = HabitatThemeService.GetAvailableThemes(profile),
		SelectedHabitatTheme = profile.SelectedHabitatTheme,
		DiscoveryLog = DiscoveryLogService.GetLog(profile),
		Goals = GoalService.GetGoals(profile),
	})
end

return StateService
