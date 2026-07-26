-- Owns Critter ownership (granting the starter Pip) and the procedural
-- model shown in a player's habitat. Growth/Influence math lives in
-- GrowthService/InfluenceService; this module only answers "what should
-- the player's Critter look like right now" and keeps that visual in sync
-- with the profile.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CritterDefinitions = require(ReplicatedStorage.Config.CritterDefinitions)
local DataManager = require(script.Parent.DataManager)
local CritterSlotService = require(script.Parent.CritterSlotService)
local CosmeticService = require(script.Parent.CosmeticService)
local DiscoveryLogService = require(script.Parent.DiscoveryLogService)

local CritterService = {}

-- [plotIndex] = the currently spawned critter Model, so it can be cleanly
-- destroyed/replaced on leave, rebirth-style resets (future), or evolution.
local spawnedModels = {}

-- [plotIndex] = the looping idle-bob Tween, so a reaction can pause/resume
-- it instead of the two fighting over the same CFrame property.
local idleTweens = {}

-- Reaction particle colors/counts. Feed and Play read different entries
-- here so "different actions get different reactions" is a data lookup,
-- not copy-pasted animation code.
local REACTION_CONFIG = {
	Feed = { Color = Color3.fromRGB(255, 210, 120), Count = 10, Hop = false },
	Play = { Color = Color3.fromRGB(150, 220, 255), Count = 16, Hop = true },
	Item = { Color = Color3.fromRGB(200, 130, 230), Count = 14, Hop = false },
}

local STAGE_SCALE = {
	Baby = 0.65,
	Juvenile = 0.85,
	["Ready to Evolve"] = 1.0,
	Evolved = 1.0,
	Mature = 1.0, -- a species with no further evolution (see GrowthService)
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
	body:SetAttribute("BaseColor", definition.BodyColor)

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
		DiscoveryLogService.MarkDiscovered(profile, "pip")
	end
end

function CritterService.GetActiveCritter(profile)
	if not profile.ActiveCritterUid then
		return nil
	end
	return profile.Critters[profile.ActiveCritterUid]
end

-- A slow, gentle bob so Pip reads as alive even when nothing is happening --
-- not a walk cycle, just enough that it never looks like a frozen prop.
-- Captured on body.CFrame *after* the model is placed in the world, so the
-- "rest" position tweened around is wherever PivotTo actually put it.
local function startIdleAnimation(plotIndex, body)
	local restCFrame = body.CFrame
	local tween = TweenService:Create(
		body,
		TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = restCFrame * CFrame.new(0, 0.25, 0) }
	)
	tween:Play()
	idleTweens[plotIndex] = { Tween = tween, RestCFrame = restCFrame }
end

local function stopIdleAnimation(plotIndex)
	local entry = idleTweens[plotIndex]
	if entry then
		entry.Tween:Cancel()
		idleTweens[plotIndex] = nil
	end
end

-- Plays a short, visible reaction on the Critter currently on this plot's
-- pedestal -- a color pulse plus a particle burst always, and a one-shot
-- hop for the more energetic reactions (see REACTION_CONFIG). Safe to call
-- even if nothing is spawned there (e.g. a stale/racing remote).
function CritterService.PlayReaction(plot, reactionType)
	local model = spawnedModels[plot.Index]
	if not model then
		return
	end
	local body = model.PrimaryPart
	if not body then
		return
	end

	local config = REACTION_CONFIG[reactionType]
	if not config then
		return
	end

	local baseColor = body:GetAttribute("BaseColor") or body.Color
	local pulseUp = TweenService:Create(body, TweenInfo.new(0.12), { Color = config.Color })
	local pulseDown = TweenService:Create(body, TweenInfo.new(0.4), { Color = baseColor })
	pulseUp:Play()
	pulseUp.Completed:Once(function()
		pulseDown:Play()
	end)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(config.Color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(3, 5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = body
	emitter:Emit(config.Count)
	Debris:AddItem(emitter, 2)

	if config.Hop then
		local idleEntry = idleTweens[plot.Index]
		if idleEntry then
			idleEntry.Tween:Pause()
		end

		local restCFrame = idleEntry and idleEntry.RestCFrame or body.CFrame
		local hopUp = TweenService:Create(
			body,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = restCFrame * CFrame.new(0, 1.1, 0) }
		)
		local hopDown = TweenService:Create(
			body,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = restCFrame }
		)
		hopUp:Play()
		hopUp.Completed:Once(function()
			hopDown:Play()
			hopDown.Completed:Once(function()
				if idleEntry then
					idleEntry.Tween:Play()
				end
			end)
		end)
	end
end

-- A bigger, showier burst than PlayReaction, timed to fire right as
-- EvolutionService swaps the model -- "the environment reacts" (see
-- GAME_DESIGN.md Phase 4), not just a UI popup. Colored to match the new
-- form's own accessory color so the flash itself hints at the outcome
-- concretely tied to what the player did, not a generic effect.
function CritterService.PlayEvolutionEffect(plot, color)
	color = color or Color3.fromRGB(255, 255, 255)
	local originPart = plot.Pedestal

	local flashPart = Instance.new("Part")
	flashPart.Anchored = true
	flashPart.CanCollide = false
	flashPart.Transparency = 1
	flashPart.Size = Vector3.new(1, 1, 1)
	flashPart.CFrame = originPart.CFrame * CFrame.new(0, originPart.Size.Y / 2 + 2, 0)
	flashPart.Parent = plot.Model

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 24
	light.Brightness = 0
	light.Parent = flashPart

	TweenService:Create(light, TweenInfo.new(0.2), { Brightness = 8 }):Play()
	task.delay(0.2, function()
		TweenService:Create(light, TweenInfo.new(1.2), { Brightness = 0 }):Play()
	end)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = flashPart
	emitter:Emit(40)

	Debris:AddItem(flashPart, 3)
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
	startIdleAnimation(plot.Index, model.PrimaryPart)
end

function CritterService.ClearPlotVisual(plot)
	stopIdleAnimation(plot.Index)
	local existing = spawnedModels[plot.Index]
	if existing then
		existing:Destroy()
		spawnedModels[plot.Index] = nil
	end
end

return CritterService
