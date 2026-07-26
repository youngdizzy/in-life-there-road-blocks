-- The one centralized place luck is computed. Any future system that wants
-- to be luck-sensitive (rare mutations, rare items, event rewards, ...)
-- calls LuckService.GetMultiplier(profile) explicitly -- luck never
-- silently applies to every random roll in the game (see GAME_DESIGN.md
-- "Monetization Philosophy").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local BoostService = require(script.Parent.BoostService)

local LuckService = {}

-- Additive stacking over a base of 1.0 (see MonetizationConfig.Luck) so a
-- gamepass plus a potion is a strong-but-sane 3x, never a runaway
-- multiplicative number.
function LuckService.GetMultiplier(profile)
	local multiplier = 1.0

	if profile.OwnedGamepasses["Luck2x"] then
		multiplier += MonetizationConfig.Luck.GamepassBonus
	end

	if BoostService.IsActive(profile, "LuckPotion") then
		multiplier += MonetizationConfig.Luck.PotionBonus
	end

	return multiplier
end

-- Applies luck to a base 0-1 chance, capped so luck makes rare things more
-- likely without ever approaching "guaranteed" (see MonetizationConfig.Discovery.MaxChance
-- for the concrete example this is built for).
function LuckService.ApplyToChance(baseChance, profile, maxChance)
	local result = baseChance * LuckService.GetMultiplier(profile)
	if maxChance then
		result = math.min(result, maxChance)
	end
	return result
end

return LuckService
