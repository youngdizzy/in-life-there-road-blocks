-- Lists a player's owned Critters and lets them choose which one is
-- active (displayed on the habitat pedestal, and the target of
-- Feed/Play/Mutation Items). The minimum needed to make owning more than
-- one Critter mean anything -- not a full collection/showcase system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Remotes)

local DataManager = require(script.Parent.DataManager)
local CritterService = require(script.Parent.CritterService)
local HabitatManager = require(script.Parent.HabitatManager)

local CollectionService = {}

-- Required lazily (inside functions, not at module load time) because
-- StateService.Push includes CollectionService.GetSummary in its payload --
-- a top-level require in both directions would be a circular require, and
-- one of the two modules would load half-built. Deferring this one until
-- it's actually called sidesteps that; by then both modules have already
-- finished loading.
local function getStateService()
	return require(script.Parent.StateService)
end

function CollectionService.GetSummary(profile)
	local list = {}
	for uid, record in pairs(profile.Critters) do
		table.insert(list, {
			Uid = uid,
			Name = record.Name,
			DefinitionId = record.DefinitionId,
			Stage = record.Stage,
			Active = uid == profile.ActiveCritterUid,
		})
	end
	table.sort(list, function(a, b)
		return a.Uid < b.Uid
	end)
	return list
end

function CollectionService.SetActiveCritter(player, uid)
	local profile = DataManager.GetProfile(player)
	if not profile then
		return
	end

	if not profile.Critters[uid] then
		return
	end
	if profile.ActiveCritterUid == uid then
		return
	end

	profile.ActiveCritterUid = uid

	local plot = HabitatManager.GetHabitatForOwner(player.UserId)
	if plot then
		CritterService.RefreshVisual(plot, profile)
	end
	getStateService().Push(player, profile)
end

function CollectionService.Init()
	Remotes.get("SetActiveCritter").OnServerEvent:Connect(function(player, uid)
		CollectionService.SetActiveCritter(player, uid)
	end)
end

return CollectionService
