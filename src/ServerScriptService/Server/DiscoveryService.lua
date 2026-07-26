-- The first real luck-gated system: a small, capped chance on every
-- Feed/Play action of a "Rare Discovery" -- a modest bonus, not a
-- shortcut, and never a guaranteed rare outcome (see GAME_DESIGN.md
-- "Monetization Philosophy" and MonetizationConfig.Discovery for the
-- actual numbers). Future rare-mutation/rare-item/event-reward systems
-- should follow this exact shape: call LuckService, roll, grant something
-- modest, record it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)
local LuckService = require(script.Parent.LuckService)
local GrowthService = require(script.Parent.GrowthService)

local DiscoveryService = {}

-- Call after a successful Feed/Play, before the growth/evolution check that
-- follows it, so a Rare Discovery's bonus points count toward the same
-- evolution roll as the action that triggered it.
function DiscoveryService.RollForDiscovery(player, profile, record)
	local chance = LuckService.ApplyToChance(
		MonetizationConfig.Discovery.BaseChance,
		profile,
		MonetizationConfig.Discovery.MaxChance
	)

	if math.random() > chance then
		return false
	end

	profile.Discoveries += 1
	if not record.EvolvedInto then
		GrowthService.AddGrowthPoints(profile, record, MonetizationConfig.Discovery.BonusGrowthPoints)
	end

	Remotes.get("Notify"):FireClient(player, {
		Text = ("✨ Rare discovery! %s found something special."):format(record.Name),
		Kind = "success",
	})

	return true
end

return DiscoveryService
