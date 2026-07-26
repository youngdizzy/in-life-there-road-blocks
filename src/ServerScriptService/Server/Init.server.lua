-- Server entrypoint. Builds the world, wires every habitat's Environment
-- Zone prompts, and runs the player join/leave lifecycle. Runs once when
-- the server starts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Remotes)

local DataManager = require(script.Parent.DataManager)
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

-- 1. Build the world and hand HabitatManager the resulting habitat list.
local plots = HabitatBuilder.Build()
HabitatManager.Init(plots)

-- 2. Wire each habitat's four Environment Zone prompts once, at server
-- start -- owner-only; a visiting player (once visiting is a thing) just
-- gets told it's not their habitat instead of affecting someone else's Pip.
for _, plot in ipairs(plots) do
	for zoneId, zonePart in pairs(plot.Zones) do
		zonePart.PlayPrompt.Triggered:Connect(function(playerWhoTriggered)
			if plot.OwnerUserId ~= playerWhoTriggered.UserId then
				notify(playerWhoTriggered, "This isn't your habitat.", "warning")
				return
			end
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
