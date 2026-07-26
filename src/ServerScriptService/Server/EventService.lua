-- Minimal runtime for the limited-time event framework: checks whether an
-- event is currently active (a manual Active flag AND, if set, a real
-- start/end time window), lets InfluenceService ask for its Influence
-- bonus, and grants its one-time reward. Proven against exactly one real
-- event ("eclipse" / "First Eclipse") -- see EventConfig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventConfig = require(ReplicatedStorage.Config.EventConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)
local DataManager = require(script.Parent.DataManager)
local InventoryService = require(script.Parent.InventoryService)

local EventService = {}

-- See CollectionService for why this is deferred instead of a top-level
-- require: StateService.Push's payload includes EventService.GetActiveEvents,
-- so requiring StateService at load time here would be circular.
local function getStateService()
	return require(script.Parent.StateService)
end

local function notify(player, message, kind)
	Remotes.get("Notify"):FireClient(player, { Text = message, Kind = kind or "info" })
end

function EventService.IsActive(eventId)
	local event = EventConfig.Events[eventId]
	if not event or not event.Active then
		return false
	end

	local now = os.time()
	if event.StartTime and now < event.StartTime then
		return false
	end
	if event.EndTime and now > event.EndTime then
		return false
	end

	return true
end

function EventService.GetActiveEvents()
	local active = {}
	for id, event in pairs(EventConfig.Events) do
		if EventService.IsActive(id) then
			table.insert(active, { Id = id, Name = event.Name, Description = event.Description })
		end
	end
	return active
end

-- Additive Influence bonus this event grants to a given type on every
-- Feed/Play action while active. 0 for every event/type that doesn't
-- define one -- callers never need to special-case "no bonus."
function EventService.GetInfluenceBonus(influenceType)
	local total = 0
	if EventService.IsActive("eclipse") and influenceType == "Shadow" then
		total += EventConfig.Events.eclipse.EclipseShadowBonusPerAction
	end
	return total
end

function EventService.HasClaimedReward(profile, eventId)
	local progress = profile.EventProgress[eventId]
	return progress ~= nil and progress.RewardClaimed == true
end

function EventService.ClaimReward(player, eventId)
	local profile = DataManager.GetProfile(player)
	if not profile then
		return
	end

	if not EventService.IsActive(eventId) then
		notify(player, "That event isn't running right now.", "warning")
		return
	end

	if EventService.HasClaimedReward(profile, eventId) then
		notify(player, "You've already claimed this event's reward.", "warning")
		return
	end

	local event = EventConfig.Events[eventId]
	if event.RewardGems then
		profile.Gems += event.RewardGems
	end
	if event.RewardItemId then
		InventoryService.AddItem(profile, event.RewardItemId, 1)
	end

	profile.EventProgress[eventId] = { RewardClaimed = true }
	notify(player, ("Claimed the %s reward!"):format(event.Name), "success")
	getStateService().Push(player, profile)
end

function EventService.Init()
	Remotes.get("ClaimEventReward").OnServerEvent:Connect(function(player, eventId)
		EventService.ClaimReward(player, eventId)
	end)
end

return EventService
