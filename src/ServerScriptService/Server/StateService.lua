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

local StateService = {}

function StateService.Push(player, profile)
	local record = CritterService.GetActiveCritter(profile)
	if not record then
		return
	end

	local definition = CritterDefinitions.Get(record.DefinitionId)

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
	})
end

return StateService
