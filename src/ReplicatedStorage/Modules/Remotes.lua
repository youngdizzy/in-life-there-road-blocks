-- Thin accessor over the RemoteEvent/RemoteFunction instances defined in
-- default.project.json under ReplicatedStorage.Remotes, so both client and
-- server code can do `Remotes.get("FeedCritter"):FireServer(foodId)`
-- without repeating WaitForChild calls.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local cache = {}

local Remotes = {}

function Remotes.get(name)
	if not cache[name] then
		cache[name] = remotesFolder:WaitForChild(name)
	end
	return cache[name]
end

return Remotes
