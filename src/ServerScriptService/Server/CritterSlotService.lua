-- The one validated gate for "does this player have room for another
-- Critter." v1 only ever grants the single starter Pip through it, but
-- every future acquisition path (event Critters, Mutation Lab discoveries,
-- future gacha-free rewards) must call CritterSlotService.AddCritter
-- instead of writing to profile.Critters directly, so the slot limit can
-- never be bypassed from the client or from a new feature that forgets to
-- check.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local DataManager = require(script.Parent.DataManager)

local CritterSlotService = {}

function CritterSlotService.GetMaxSlots(profile)
	local max = MonetizationConfig.CritterSlots.Base
	if profile.OwnedGamepasses["ExtraCritterSlots"] then
		max += MonetizationConfig.Gamepasses.ExtraCritterSlots.BonusSlots
	end
	return max
end

function CritterSlotService.GetUsedSlots(profile)
	local count = 0
	for _ in pairs(profile.Critters) do
		count += 1
	end
	return count
end

function CritterSlotService.HasFreeSlot(profile)
	return CritterSlotService.GetUsedSlots(profile) < CritterSlotService.GetMaxSlots(profile)
end

-- Returns the new critter's uid on success, or nil, "reason" on failure
-- (currently only "No free Critter slots"). This is the only sanctioned
-- way to add a Critter to a profile.
--
-- `origin` is a free-form provenance tag ("starter", "milestone", and
-- eventually "wild"/"trade"/"purchase"/"event") -- see
-- DataManager.DefaultCritterRecord's Origin/ObtainedAt fields. Passing
-- nil is fine (Origin just stays nil); every current caller should still
-- pass one so the field means something from day one instead of needing
-- a backfill later.
function CritterSlotService.AddCritter(profile, definitionId, name, origin)
	if not CritterSlotService.HasFreeSlot(profile) then
		return nil, "No free Critter slots"
	end

	local uid = DataManager.NewCritterUid(profile)
	local record = DataManager.DefaultCritterRecord(definitionId, name)
	record.Origin = origin
	record.ObtainedAt = os.time()
	profile.Critters[uid] = record
	return uid
end

return CritterSlotService
