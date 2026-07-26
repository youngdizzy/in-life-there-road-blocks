-- Centralized timed-boost tracking (temporary Growth Boost, temporary Luck
-- Potion, and any future one-off timed effect). One active timer per boost
-- type per player -- buying another one while active extends the timer
-- rather than stacking a second simultaneous instance, so "avoid stacking
-- incorrectly" (see the monetization spec) is structurally impossible, not
-- just a rule someone has to remember to enforce.

local BoostService = {}

-- Returns true (and self-heals expired entries) without ever needing a
-- background sweep loop -- every read prunes itself.
function BoostService.IsActive(profile, boostType)
	local entry = profile.ActiveBoosts[boostType]
	if not entry then
		return false
	end
	if os.time() >= entry.ExpiresAt then
		profile.ActiveBoosts[boostType] = nil
		return false
	end
	return true
end

function BoostService.GetRemainingSeconds(profile, boostType)
	if not BoostService.IsActive(profile, boostType) then
		return 0
	end
	return profile.ActiveBoosts[boostType].ExpiresAt - os.time()
end

function BoostService.Grant(profile, boostType, durationSeconds)
	local now = os.time()
	local existing = profile.ActiveBoosts[boostType]
	local extendFrom = (existing and existing.ExpiresAt > now) and existing.ExpiresAt or now
	profile.ActiveBoosts[boostType] = { ExpiresAt = extendFrom + durationSeconds }
end

return BoostService
