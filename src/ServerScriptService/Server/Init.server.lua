-- Server entrypoint. Builds the world (the shared Meadow/zones/landmarks,
-- then the player-habitat neighborhood), wires the four public Environment
-- Zone prompts, and runs the player join/leave lifecycle. Runs once when
-- the server starts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Remotes)
local WorldConfig = require(ReplicatedStorage.Config.WorldConfig)

local DataManager = require(script.Parent.DataManager)
local WorldBuilder = require(script.Parent.WorldBuilder)
local HabitatBuilder = require(script.Parent.HabitatBuilder)
local HabitatManager = require(script.Parent.HabitatManager)
local CritterService = require(script.Parent.CritterService)
local InfluenceService = require(script.Parent.InfluenceService)
local StateService = require(script.Parent.StateService)
local MonetizationService = require(script.Parent.MonetizationService)
local MutationLabService = require(script.Parent.MutationLabService)
local MutationItemService = require(script.Parent.MutationItemService)
local CosmeticService = require(script.Parent.CosmeticService)
local CollectionService = require(script.Parent.CollectionService)
local EventService = require(script.Parent.EventService)
local HabitatThemeService = require(script.Parent.HabitatThemeService)

local function notify(player, message, kind)
	Remotes.get("Notify"):FireClient(player, { Text = message, Kind = kind or "info" })
end

-- 1. Build the shared overworld (Meadow, the four public Environment
-- Zones, Archive, Plaza, Sanctum), then the player-habitat neighborhood,
-- and hand HabitatManager the resulting habitat list.
local worldFolder = WorldBuilder.Build()
local plots = HabitatBuilder.Build()
HabitatManager.Init(plots)

-- 2. Wire each of the four shared Environment Zone prompts once, at server
-- start. These are public world destinations now, not part of anyone's
-- habitat, so -- unlike the old per-habitat zones -- there's no owner
-- check: any player standing there can play with their own active Critter.
for _, zoneId in ipairs(WorldConfig.ZoneOrder) do
	local zonePart = worldFolder:FindFirstChild(zoneId, true)
	if zonePart then
		zonePart.PlayPrompt.Triggered:Connect(function(playerWhoTriggered)
			InfluenceService.HandlePlayAtZone(playerWhoTriggered, zoneId)
		end)
	end
end

InfluenceService.Init()
MonetizationService.Init()
MutationLabService.Init()
MutationItemService.Init()
CollectionService.Init()
EventService.Init()
HabitatThemeService.Init()
InfluenceService.StartAutoCareLoop()

Remotes.get("EquipCosmetic").OnServerEvent:Connect(function(player, cosmeticId)
	local profile = DataManager.GetProfile(player)
	local record = profile and CritterService.GetActiveCritter(profile)
	if not record then
		return
	end

	if cosmeticId ~= nil and not CosmeticService.IsUnlocked(profile, cosmeticId) then
		return
	end

	record.EquippedCosmetic = cosmeticId

	local plot = HabitatManager.GetHabitatForOwner(player.UserId)
	if plot then
		CritterService.RefreshVisual(plot, profile)
	end
	StateService.Push(player, profile)
end)

-- 3. Player lifecycle.
local function onPlayerAdded(player)
	local profile = DataManager.LoadProfile(player)
	MonetizationService.CheckOwnedGamepasses(player, profile)
	CritterService.GrantStarterPipIfNeeded(profile)

	local plot = HabitatManager.AssignHabitat(player, profile.HabitatIndex)
	if plot then
		profile.HabitatIndex = plot.Index
		CritterService.RefreshVisual(plot, profile)
		HabitatThemeService.ApplyToHabitat(player, profile)
	else
		notify(player, "The habitat grid is full right now, sorry! Try again shortly.", "warning")
	end

	StateService.Push(player, profile)
end

local function onPlayerRemoving(player)
	local plotIndex = HabitatManager.GetHabitatIndexForOwner(player.UserId)
	if plotIndex then
		HabitatManager.ReleaseHabitat(player, function(releasedPlot)
			CritterService.ClearPlotVisual(releasedPlot)
		end)
	end
	DataManager.ReleaseProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	DataManager.AutosaveAll()
end)

-- Periodic safety-net autosave in case a server runs for a long time without
-- restarting (long-running servers don't otherwise get a save point).
task.spawn(function()
	while true do
		task.wait(120)
		DataManager.AutosaveAll()
	end
end)
