-- Connects MutationItemConfig to the real Influence/Growth/Evolution
-- systems: validates ownership and eligibility server-side, consumes
-- exactly one item, nudges Influence (never grants a Critter outright),
-- and lets that nudge count toward the same evolution check a Feed/Play
-- action would trigger.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationItemConfig = require(ReplicatedStorage.Config.MutationItemConfig)
local CritterDefinitions = require(ReplicatedStorage.Config.CritterDefinitions)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local DataManager = require(script.Parent.DataManager)
local CritterService = require(script.Parent.CritterService)
local InventoryService = require(script.Parent.InventoryService)
local GrowthService = require(script.Parent.GrowthService)
local EvolutionService = require(script.Parent.EvolutionService)
local StateService = require(script.Parent.StateService)
local HabitatManager = require(script.Parent.HabitatManager)

local MutationItemService = {}

-- A mutation item is itself a meaningful action, so it's worth a little
-- Growth too -- same order of magnitude as a food/zone action, not a
-- shortcut past them.
local GROWTH_POINTS_PER_USE = 4

local function notify(player, message, kind)
	Remotes.get("Notify"):FireClient(player, { Text = message, Kind = kind or "info" })
end

local function isEligible(item, record)
	if #item.EligibleCritters == 0 then
		return true
	end
	for _, definitionId in ipairs(item.EligibleCritters) do
		if definitionId == record.DefinitionId then
			return true
		end
	end
	return false
end

function MutationItemService.UseItem(player, itemId)
	local profile = DataManager.GetProfile(player)
	local record = profile and CritterService.GetActiveCritter(profile)
	if not record then
		return
	end

	local item = MutationItemConfig.Get(itemId)
	if not item or not item.Implemented then
		return
	end

	if not InventoryService.HasItem(profile, itemId, 1) then
		notify(player, "You don't have that item.", "warning")
		return
	end

	if record.EvolvedInto then
		notify(player, ("%s has already evolved -- nothing left to influence."):format(record.Name), "warning")
		return
	end

	if not isEligible(item, record) then
		notify(player, ("%s can't use a %s."):format(record.Name, item.Name), "warning")
		return
	end

	InventoryService.RemoveItem(profile, itemId, 1)

	if item.InfluenceType == "All" then
		if itemId == "void_candy" then
			record.VoidCandyUses += 1
		end
		for _, influenceType in ipairs(CritterDefinitions.InfluenceTypes) do
			record.Influences[influenceType] += item.InfluenceAmount
		end
	else
		record.Influences[item.InfluenceType] += item.InfluenceAmount
	end

	GrowthService.AddGrowthPoints(profile, record, GROWTH_POINTS_PER_USE)
	EvolutionService.CheckAndEvolve(player, profile, record)

	notify(player, ("Used %s on %s."):format(item.Name, record.Name), "success")
	local plot = HabitatManager.GetHabitatForOwner(player.UserId)
	if plot then
		CritterService.PlayReaction(plot, "Item")
	end
	StateService.Push(player, profile)
end

function MutationItemService.Init()
	Remotes.get("UseMutationItem").OnServerEvent:Connect(function(player, itemId)
		MutationItemService.UseItem(player, itemId)
	end)
end

return MutationItemService
