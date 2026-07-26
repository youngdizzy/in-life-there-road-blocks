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
function CritterSlotService.AddCritter(profile, definitionId, name)
	if not CritterSlotService.HasFreeSlot(profile) then
		return nil, "No free Critter slots"
	end

	local uid = DataManager.NewCritterUid(profile)
	profile.Critters[uid] = DataManager.DefaultCritterRecord(definitionId, name)
	return uid
end

return CritterSlotService
