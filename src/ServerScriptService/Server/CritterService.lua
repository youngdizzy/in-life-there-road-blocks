-- Owns Critter ownership (granting the starter Pip) and the procedural
-- model shown in a player's habitat. Growth/Influence math lives in
-- GrowthService/InfluenceService; this module only answers "what should
-- the player's Critter look like right now" and keeps that visual in sync
-- with the profile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CritterDefinitions = require(ReplicatedStorage.Config.CritterDefinitions)
local DataManager = require(script.Parent.DataManager)
local CritterSlotService = require(script.Parent.CritterSlotService)
local CosmeticService = require(script.Parent.CosmeticService)

local CritterService = {}

-- [plotIndex] = the currently spawned critter Model, so it can be cleanly
-- destroyed/replaced on leave, rebirth-style resets (future), or evolution.
local spawnedModels = {}

local STAGE_SCALE = {
	Baby = 0.65,
	Juvenile = 0.85,
	["Ready to Evolve"] = 1.0,
	Evolved = 1.0,
}

local function weld(part, primary)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = primary
	weldConstraint.Part1 = part
	weldConstraint.Parent = primary
end

local function buildEyes(body, bodyRadius)
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Anchored = false
		eye.CanCollide = false
		eye.Material = Enum.Material.SmoothPlastic
		eye.Color = Color3.new(1, 1, 1)
		local eyeSize = bodyRadius * 0.55
		eye.Size = Vector3.new(eyeSize, eyeSize, eyeSize)
		eye.CFrame = body.CFrame * CFrame.new(side * bodyRadius * 0.4, bodyRadius * 0.25, -bodyRadius * 0.8)
		eye.Parent = body.Parent
		weld(eye, body)

		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Shape = Enum.PartType.Ball
		pupil.Anchored = false
		pupil.CanCollide = false
		pupil.Material = Enum.Material.SmoothPlastic
		pupil.Color = Color3.fromRGB(20, 20, 25)
		local pupilSize = eyeSize * 0.5
		pupil.Size = Vector3.new(pupilSize, pupilSize, pupilSize)
		pupil.CFrame = eye.CFrame * CFrame.new(0, 0, -eyeSize * 0.35)
		pupil.Parent = body.Parent
		weld(pupil, body)
	end
end

-- Every evolution keeps Pip's round-body shape language (see
-- GAME_DESIGN.md "Placeholder Art Policy") and is only distinguished by
-- color and one small elemental accessory on top.
local function buildAccessory(body, bodyRadius, shape, color)
	if not shape then
		return
	end

	local accessory = Instance.new("Part")
	accessory.Name = "Accessory"
	accessory.Anchored = false
	accessory.CanCollide = false
	accessory.Material = Enum.Material.Neon
	accessory.Color = color

	if shape == "Flame" then
		accessory.Shape = Enum.PartType.Ball
		accessory.Size = Vector3.new(bodyRadius * 0.6, bodyRadius * 0.9, bodyRadius * 0.6)
	elseif shape == "Droplet" then
		accessory.Shape = Enum.PartType.Ball
		accessory.Size = Vector3.new(bodyRadius * 0.55, bodyRadius * 0.85, bodyRadius * 0.55)
	elseif shape == "Leaf" then
		accessory.Shape = Enum.PartType.Block
		accessory.Size = Vector3.new(bodyRadius * 0.9, bodyRadius * 0.15, bodyRadius * 0.5)
	elseif shape == "Spike" then
		accessory.Shape = Enum.PartType.Block
		accessory.Size = Vector3.new(bodyRadius * 0.3, bodyRadius * 1.1, bodyRadius * 0.3)
	elseif shape == "Spark" then
		accessory.Shape = Enum.PartType.Ball
		accessory.Size = Vector3.new(bodyRadius * 0.4, bodyRadius * 0.4, bodyRadius * 0.4)
		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = 3
		light.Range = 10
		light.Parent = accessory
	else
		accessory.Shape = Enum.PartType.Ball
		accessory.Size = Vector3.new(bodyRadius * 0.5, bodyRadius * 0.5, bodyRadius * 0.5)
	end

	accessory.CFrame = body.CFrame * CFrame.new(0, bodyRadius * 0.9, 0)
	accessory.Parent = body.Parent
	weld(accessory, body)
end

local function buildCritterModel(record)
	local definition = CritterDefinitions.Get(record.DefinitionId)
	assert(definition, "Unknown critter definition: " .. tostring(record.DefinitionId))

	local stageScale = STAGE_SCALE[record.Stage] or 1.0
	local scale = definition.BaseScale * stageScale
	local bodyDiameter = 3 * scale
	local bodyRadius = bodyDiameter / 2

	local model = Instance.new("Model")
	model.Name = record.Name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = definition.BodyColor
	body.Size = Vector3.new(bodyDiameter, bodyDiameter, bodyDiameter)
	body.Parent = model
	model.PrimaryPart = body

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Info"
	billboard.Size = UDim2.fromOffset(160, 46)
	billboard.StudsOffset = Vector3.new(0, bodyRadius + 1.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = record.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = billboard

	local stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "StageLabel"
	stageLabel.Size = UDim2.new(1, 0, 0.45, 0)
	stageLabel.Position = UDim2.new(0, 0, 0.55, 0)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text = record.Stage
	stageLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
	stageLabel.Font = Enum.Font.Gotham
	stageLabel.TextScaled = true
	stageLabel.Parent = billboard

	buildEyes(body, bodyRadius)
	buildAccessory(body, bodyRadius, definition.AccessoryShape, definition.AccessoryColor)
	CosmeticService.Attach(model, record.EquippedCosmetic)

	return model
end

-- Grants a fresh Pip if the player doesn't already have an active Critter.
-- Called once per join; safe to call on a returning player (no-op). Goes
-- through CritterSlotService like every other Critter grant would, even
-- though the base slot count guarantees room for a first Critter today.
function CritterService.GrantStarterPipIfNeeded(profile)
	if profile.ActiveCritterUid then
		return
	end

	local uid = CritterSlotService.AddCritter(profile, "pip", "Pip")
	if uid then
		profile.ActiveCritterUid = uid
	end
end

function CritterService.GetActiveCritter(profile)
	if not profile.ActiveCritterUid then
		return nil
	end
	return profile.Critters[profile.ActiveCritterUid]
end

-- (Re)builds the active Critter's model on its habitat pedestal, replacing
-- whatever was there before. Call after join, and after any change that
-- should be visible (growth stage change, evolution).
function CritterService.RefreshVisual(plot, profile)
	CritterService.ClearPlotVisual(plot)

	local record = CritterService.GetActiveCritter(profile)
	if not record then
		return
	end

	local model = buildCritterModel(record)
	model:PivotTo(plot.Pedestal.CFrame * CFrame.new(0, plot.Pedestal.Size.Y / 2 + 2, 0))
	model.Parent = plot.Model
	spawnedModels[plot.Index] = model
end

function CritterService.ClearPlotVisual(plot)
	local existing = spawnedModels[plot.Index]
	if existing then
		existing:Destroy()
		spawnedModels[plot.Index] = nil
	end
end

return CritterService
