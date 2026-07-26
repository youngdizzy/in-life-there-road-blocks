-- Player persistence. Keeps one in-memory profile per online player, backed
-- by a single DataStore key, with retrying loads/saves and periodic autosave.
-- This is a v1: no cross-server session locking, which is fine for a single
-- place with no reserved/private servers. Add ProfileService-style locking
-- before you spin up multiple linked places sharing player data.

local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("PlayerData_v1")

local DataManager = {}
local profiles = {}

local MAX_RETRIES = 3
local RETRY_DELAY = 1.5
local MAX_PROCESSED_RECEIPTS = 200

-- Bump this whenever DefaultProfile/DefaultCritterRecord gains or changes a
-- field in a way that needs more than the additive backfill fillDefaults
-- already does. Right now every change so far has been additive (a new
-- field with a safe default), so there's no real migration step yet --
-- this exists so the day a field needs an actual transformation, there's
-- already a version number on every saved profile to branch on.
DataManager.SCHEMA_VERSION = 3

local function attempt(fn)
	local lastErr
	for i = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(RETRY_DELAY * i)
	end
	return false, lastErr
end

-- One Critter's persisted record. Kept as its own function (rather than
-- inlined in DefaultProfile) so CritterService can backfill a single
-- record and so a future schema change only needs to update one place.
function DataManager.DefaultCritterRecord(definitionId, name)
	return {
		DefinitionId = definitionId,
		Name = name,
		GrowthPoints = 0,
		Stage = "Baby",
		Influences = { Fire = 0, Water = 0, Nature = 0, Shadow = 0 },
		Hunger = 100,
		Happiness = 100,
		MysteryMushroomFeeds = 0,
		VoidCandyUses = 0, -- see MutationLabService's "unstable mutation" hint
		EvolvedInto = nil,
		EquippedCosmetic = nil, -- cosmeticId from CosmeticConfig, or nil
		EvolutionHistory = {}, -- snapshots captured right before each evolution (see EvolutionService); also read by MutationLabService for "previously discovered" hints
		LastFeedAt = 0,
		LastPlayAt = 0,
	}
end

function DataManager.DefaultProfile()
	return {
		SchemaVersion = DataManager.SCHEMA_VERSION,
		Critters = {}, -- [uid] = critter record, see DefaultCritterRecord
		ActiveCritterUid = nil,
		SecondCritterGranted = false, -- see MilestoneService
		Inventory = {}, -- [itemId] = quantity, see InventoryService
		HabitatIndex = nil,
		NextCritterUid = 1,

		Gems = 0,
		Discoveries = 0, -- count of Rare Discoveries found so far, see DiscoveryService
		OwnedGamepasses = {}, -- [gamepassKey] = true, cached from UserOwnsGamePassAsync
		UnlockedCosmetics = {}, -- [cosmeticId] = true, account-wide unlocks
		ActiveBoosts = {}, -- [boostType] = { ExpiresAt = number }, see BoostService
		ProcessedReceipts = {}, -- purchaseIds already granted, see MonetizationService.ProcessReceipt
		EventProgress = {}, -- [eventId] = { RewardClaimed = bool }, see EventService
		SelectedHabitatTheme = "default", -- see HabitatThemeService
		DiscoveredSpecies = {}, -- [definitionId] = true, see DiscoveryLogService. Distinct from
		-- `Discoveries` above (the Rare Discovery item-find counter) -- unfortunate near-miss in
		-- naming history, kept because renaming Discoveries now would just churn every save file.
	}
end

local function fillCritterDefaults(record)
	local default = DataManager.DefaultCritterRecord(record.DefinitionId, record.Name)
	for key, value in pairs(default) do
		if record[key] == nil then
			record[key] = value
		end
	end
	return record
end

local function fillDefaults(profile)
	local default = DataManager.DefaultProfile()
	for key, value in pairs(default) do
		if profile[key] == nil then
			profile[key] = value
		end
	end
	for _, record in pairs(profile.Critters) do
		fillCritterDefaults(record)
	end
	return profile
end

function DataManager.LoadProfile(player)
	local key = "Player_" .. player.UserId
	local ok, data = attempt(function()
		return store:GetAsync(key)
	end)

	local profile
	if ok and data then
		profile = fillDefaults(data)
	else
		if not ok then
			warn(("DataManager: failed to load data for %s, using defaults: %s"):format(player.Name, tostring(data)))
		end
		profile = DataManager.DefaultProfile()
	end
	profile.SchemaVersion = DataManager.SCHEMA_VERSION

	profiles[player.UserId] = profile
	return profile
end

function DataManager.GetProfile(player)
	return profiles[player.UserId]
end

function DataManager.SaveProfile(player)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end

	local key = "Player_" .. player.UserId
	local ok, err = attempt(function()
		store:SetAsync(key, profile)
	end)

	if not ok then
		warn(("DataManager: failed to save data for %s: %s"):format(player.Name, tostring(err)))
	end
end

function DataManager.ReleaseProfile(player)
	DataManager.SaveProfile(player)
	profiles[player.UserId] = nil
end

function DataManager.NewCritterUid(profile)
	local uid = tostring(profile.NextCritterUid)
	profile.NextCritterUid += 1
	return uid
end

-- Records a MarketplaceService purchase id so ProcessReceipt can be safely
-- retried by Roblox (it *will* retry) without ever granting a product
-- twice. A bounded ring buffer, not an ever-growing list.
function DataManager.HasProcessedReceipt(profile, purchaseId)
	for _, id in ipairs(profile.ProcessedReceipts) do
		if id == purchaseId then
			return true
		end
	end
	return false
end

function DataManager.MarkReceiptProcessed(profile, purchaseId)
	table.insert(profile.ProcessedReceipts, purchaseId)
	while #profile.ProcessedReceipts > MAX_PROCESSED_RECEIPTS do
		table.remove(profile.ProcessedReceipts, 1)
	end
end

function DataManager.AutosaveAll()
	for userId in pairs(profiles) do
		local player = game:GetService("Players"):GetPlayerByUserId(userId)
		if player then
			DataManager.SaveProfile(player)
		end
	end
end

return DataManager
