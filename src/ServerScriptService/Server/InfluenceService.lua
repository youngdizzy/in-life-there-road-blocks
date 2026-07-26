-- The two v1 Influence actions: Feed and Play-at-a-Zone. Both are
-- server-validated (cooldowns, valid ids) -- the client only ever tells
-- the server *which* food or zone it picked, never an amount or an effect.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FoodConfig = require(ReplicatedStorage.Config.FoodConfig)
local EnvironmentConfig = require(ReplicatedStorage.Config.EnvironmentConfig)
local GrowthConfig = require(ReplicatedStorage.Config.GrowthConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local DataManager = require(script.Parent.DataManager)
local CritterService = require(script.Parent.CritterService)
local GrowthService = require(script.Parent.GrowthService)
local EvolutionService = require(script.Parent.EvolutionService)
local StateService = require(script.Parent.StateService)

local InfluenceService = {}

local function notify(player, message, kind)
	Remotes.get("Notify"):FireClient(player, { Text = message, Kind = kind or "info" })
end

local function applyInfluences(record, effects)
	for influenceType, delta in pairs(effects) do
		record.Influences[influenceType] = (record.Influences[influenceType] or 0) + delta
	end
end

local function afterAction(player, profile, record)
	if not record.EvolvedInto then
		EvolutionService.CheckAndEvolve(player, profile, record)
	end
	StateService.Push(player, profile)
end

local function handleFeed(player, foodId)
	local profile = DataManager.GetProfile(player)
	local record = profile and CritterService.GetActiveCritter(profile)
	if not record then
		return
	end

	local food = FoodConfig.Get(foodId)
	if not food then
		return
	end

	local now = os.time()
	if now - record.LastFeedAt < GrowthConfig.FeedCooldownSeconds then
		notify(player, "Not hungry again just yet -- give it a moment.", "warning")
		return
	end

	record.LastFeedAt = now
	record.Hunger = math.min(GrowthConfig.MaxHunger, record.Hunger + food.HungerRestore)
	applyInfluences(record, food.InfluenceEffects)
	if food.IsMysterious then
		record.MysteryMushroomFeeds += 1
	end

	if not record.EvolvedInto then
		GrowthService.AddGrowthPoints(record, food.GrowthPoints)
	end

	notify(player, ("%s happily ate the %s!"):format(record.Name, food.Name), "success")
	afterAction(player, profile, record)
end

-- Public (unlike handleFeed) because it's called directly from a habitat
-- Environment Zone's ProximityPrompt.Triggered in Init.server.lua, not from
-- a client-fired RemoteEvent -- the engine already guarantees the
-- triggering player was physically at the zone, so there's nothing for a
-- remote to add here.
function InfluenceService.HandlePlayAtZone(player, zoneId)
	local profile = DataManager.GetProfile(player)
	local record = profile and CritterService.GetActiveCritter(profile)
	if not record then
		return
	end

	local zone = EnvironmentConfig.Get(zoneId)
	if not zone then
		return
	end

	local now = os.time()
	if now - record.LastPlayAt < GrowthConfig.PlayCooldownSeconds then
		notify(player, "Pip wants a little break before playing again.", "warning")
		return
	end

	record.LastPlayAt = now
	record.Happiness = math.min(GrowthConfig.MaxHappiness, record.Happiness + zone.HappinessGain)
	applyInfluences(record, zone.InfluenceEffects)

	if not record.EvolvedInto then
		GrowthService.AddGrowthPoints(record, zone.GrowthPoints)
	end

	notify(player, ("%s loved playing at the %s!"):format(record.Name, zone.Name), "success")
	afterAction(player, profile, record)
end

function InfluenceService.Init()
	Remotes.get("FeedCritter").OnServerEvent:Connect(handleFeed)
end

return InfluenceService
