-- Renders a cosmetic effect onto an already-built Critter model.
-- CritterService calls CosmeticService.Attach once after building a model;
-- it never needs to know how any individual effect works. Unlocking
-- (granting account-wide ownership) is separate from equipping (which
-- Critter is currently showing it) -- see DataManager profile.UnlockedCosmetics
-- vs a Critter record's EquippedCosmetic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CosmeticConfig = require(ReplicatedStorage.Config.CosmeticConfig)

local CosmeticService = {}

function CosmeticService.IsUnlocked(profile, cosmeticId)
	return profile.UnlockedCosmetics[cosmeticId] == true
end

function CosmeticService.Unlock(profile, cosmeticId)
	profile.UnlockedCosmetics[cosmeticId] = true
end

local function attachSparkles(model, body)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CosmeticSparkles"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 245, 200))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Rate = 6
	emitter.Speed = NumberRange.new(1, 2)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = body
end

local function attachGoldenEyes(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant.Name == "Pupil" then
			descendant.Color = Color3.fromRGB(255, 210, 60)
			descendant.Material = Enum.Material.Neon
		end
	end
end

local ATTACHERS = {
	sparkles = attachSparkles,
	golden_eyes = attachGoldenEyes,
}

-- No-op if cosmeticId is nil or refers to an unimplemented/unknown effect --
-- callers don't need to check Implemented themselves.
function CosmeticService.Attach(model, cosmeticId)
	if not cosmeticId then
		return
	end

	local config = CosmeticConfig.Get(cosmeticId)
	if not config or not config.Implemented then
		return
	end

	local attacher = ATTACHERS[cosmeticId]
	if not attacher then
		return
	end

	local body = model:FindFirstChild("Body")
	if not body then
		return
	end

	attacher(model, body)
end

return CosmeticService
