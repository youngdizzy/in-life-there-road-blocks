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
		EvolvedInto = nil,
		LastFeedAt = 0,
		LastPlayAt = 0,
	}
end

function DataManager.DefaultProfile()
	return {
		Critters = {}, -- [uid] = critter record, see DefaultCritterRecord
		ActiveCritterUid = nil,
		Inventory = {}, -- reserved for future item types; unused in v1 (food is free)
		HabitatIndex = nil,
		NextCritterUid = 1,
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

function DataManager.AutosaveAll()
	for userId in pairs(profiles) do
		local player = game:GetService("Players"):GetPlayerByUserId(userId)
		if player then
			DataManager.SaveProfile(player)
		end
	end
end

return DataManager
