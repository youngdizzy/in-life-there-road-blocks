-- Habitat theme ownership + selection. "default" and "vip" are the two
-- real themes; VIP is gated on actually owning the VIPHabitat gamepass,
-- checked server-side every time (never trusted from the client), and the
-- chosen theme persists across sessions (profile.SelectedHabitatTheme).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HabitatThemeConfig = require(ReplicatedStorage.Config.HabitatThemeConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local DataManager = require(script.Parent.DataManager)
local HabitatManager = require(script.Parent.HabitatManager)

local HabitatThemeService = {}

-- See CollectionService for why this is deferred: StateService.Push's
-- payload includes HabitatThemeService.GetAvailableThemes, so a top-level
-- require here would be circular.
local function getStateService()
	return require(script.Parent.StateService)
end

local function notify(player, message, kind)
	Remotes.get("Notify"):FireClient(player, { Text = message, Kind = kind or "info" })
end

local function ownsTheme(profile, theme)
	return not theme.RequiresGamepass or profile.OwnedGamepasses[theme.RequiresGamepass] == true
end

function HabitatThemeService.GetAvailableThemes(profile)
	local available = {}
	for _, theme in pairs(HabitatThemeConfig.Themes) do
		if theme.Implemented and ownsTheme(profile, theme) then
			table.insert(available, { Id = theme.Id, Name = theme.Name })
		end
	end
	return available
end

-- Renders whatever profile.SelectedHabitatTheme currently is onto the
-- player's habitat. Re-checks ownership every time (a theme requiring a
-- gamepass never renders for someone who doesn't currently own it, even if
-- it was selected before -- can't happen with permanent gamepasses today,
-- but this keeps the invariant real rather than assumed).
function HabitatThemeService.ApplyToHabitat(player, profile)
	local plot = HabitatManager.GetHabitatForOwner(player.UserId)
	if not plot then
		return
	end

	local theme = HabitatThemeConfig.Get(profile.SelectedHabitatTheme)
	if theme and theme.Id == "vip" and ownsTheme(profile, theme) then
		HabitatManager.ApplyVIPVisual(plot)
	else
		HabitatManager.ClearVIPVisual(plot)
	end
end

function HabitatThemeService.SelectTheme(player, profile, themeId)
	local theme = HabitatThemeConfig.Get(themeId)
	if not theme or not theme.Implemented then
		notify(player, "That habitat theme isn't available yet.", "warning")
		return false
	end

	if not ownsTheme(profile, theme) then
		notify(player, "You don't own that habitat theme yet.", "warning")
		return false
	end

	profile.SelectedHabitatTheme = themeId
	HabitatThemeService.ApplyToHabitat(player, profile)
	getStateService().Push(player, profile)
	return true
end

function HabitatThemeService.Init()
	Remotes.get("SelectHabitatTheme").OnServerEvent:Connect(function(player, themeId)
		local profile = DataManager.GetProfile(player)
		if profile then
			HabitatThemeService.SelectTheme(player, profile, themeId)
		end
	end)
end

return HabitatThemeService
