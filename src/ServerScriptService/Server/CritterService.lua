-- Owns Critter ownership (granting the starter Pip) and the procedural
-- model shown in a player's habitat. Growth/Influence math lives in
-- GrowthService/InfluenceService; this module only answers "what should
-- the player's Critter look like right now" and keeps that visual in sync
-- with the profile.
--
-- Visual note (see GAME_DESIGN.md "Placeholder Art Policy" and the visual
-- style pass that added silhouette/face/ambient-particle detail): every
-- model here is built from plain Roblox Parts at runtime -- no imported
-- meshes, no custom rig, no uploaded animations, because this environment
-- has no way to author or upload real 3D assets. This is the ceiling for a
-- procedural prototype; swapping in real modeled/animated Critters later
-- means replacing the functions in this file, not touching any gameplay
-- service that calls them.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
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

-- [plotIndex] = true while that plot's "look around" loop should keep
-- running; set false to signal the loop to exit on its next cycle.
local lookAroundActive = {}

-- Reaction particle colors/counts. Feed and Play read different entries
-- here so "different actions get different reactions" is a data lookup,
-- not copy-pasted animation code.
local REACTION_CONFIG = {
	Feed = { Color = Color3.fromRGB(255, 210, 120), Count = 10, Hop = false },
	Play = { Color = Color3.fromRGB(150, 220, 255), Count = 16, Hop = true },
	Item = { Color = Color3.fromRGB(200, 130, 230), Count = 14, Hop = false },
}

-- Continuous (not one-shot) low-rate particles unique to each evolved
-- form, tinted from that Critter's own HeadNubColor so they read as part
-- of the design rather than a generic sparkle bolted on.
local AMBIENT_PARTICLE_CONFIG = {
	Embers = { Rate = 3, Speed = NumberRange.new(1, 2), Lifetime = NumberRange.new(0.6, 1.1), Acceleration = Vector3.new(0, 4, 0) },
	Bubbles = { Rate = 2.5, Speed = NumberRange.new(0.6, 1.2), Lifetime = NumberRange.new(1, 1.6), Acceleration = Vector3.new(0, 2, 0) },
	Petals = { Rate = 2, Speed = NumberRange.new(0.4, 0.9), Lifetime = NumberRange.new(1.2, 2), Acceleration = Vector3.new(0, -0.5, 0) },
	Smoke = { Rate = 2, Speed = NumberRange.new(0.5, 1), Lifetime = NumberRange.new(1, 1.8), Acceleration = Vector3.new(0, 1.5, 0) },
	Motes = { Rate = 3, Speed = NumberRange.new(0.2, 0.6), Lifetime = NumberRange.new(1, 2), Acceleration = Vector3.new(0, 0.5, 0) },
}

-- How the face reads per Mood (see MoodService). BrowAngle tilts both
-- eyebrows symmetrically in degrees (positive = raised/cheerful "^ ^",
-- negative = drooping/worried); Curious is the one asymmetric case (one
-- brow up) since that's the classic "huh?" tell. Mouth sizes are
-- multipliers on its base size. These exact numbers are a first pass --
-- tune them once they're actually visible in Studio.
local FACE_PRESETS = {
	Hungry = { BrowL = -12, BrowR = -12, MouthSizeX = 0.7, MouthSizeY = 0.6 },
	Tired = { BrowL = -22, BrowR = -22, MouthSizeX = 0.9, MouthSizeY = 0.25 },
	Growing = { BrowL = 10, BrowR = 10, MouthSizeX = 0.8, MouthSizeY = 0.7 },
	Excited = { BrowL = 22, BrowR = 22, MouthSizeX = 1.3, MouthSizeY = 1.3 },
	Happy = { BrowL = 12, BrowR = 12, MouthSizeX = 1.1, MouthSizeY = 0.9 },
	Curious = { BrowL = -6, BrowR = 20, MouthSizeX = 0.6, MouthSizeY = 0.5 },
}
local DEFAULT_FACE = FACE_PRESETS.Curious

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

-- WeldConstraint locks the relative transform between two parts at the
-- moment it's created -- it does not let you keep dragging the welded part
-- around afterward (the constraint solver just snaps it back). So
-- re-expressing a mood isn't "tween the welded eyebrow"; it's "destroy the
-- old eyebrow/weld and build a fresh one at the current body pose." This
-- finds and removes the specific WeldConstraint for `part` (parented under
-- `primary`, per `weld()` above) before destroying `part` itself, so mood
-- changes don't leave broken WeldConstraints piling up under the body.
local function destroyWelded(part, primary)
	for _, child in ipairs(primary:GetChildren()) do
		if child:IsA("WeldConstraint") and child.Part1 == part then
			child:Destroy()
		end
	end
	part:Destroy()
end

local function eyeOffsetCFrame(side, bodyRadius)
	return CFrame.new(side * bodyRadius * 0.4, bodyRadius * 0.2, -bodyRadius * 0.82)
end

-- Eyes only (with an optional glow color for Nox/Wisp). Eyebrows and the
-- mouth are built separately by buildFace, since those two are the parts
-- that get rebuilt whenever Mood changes -- see ApplyMood.
local function buildEyes(body, bodyRadius, eyeColor)
	local eyeSize = bodyRadius * 0.55
	body:SetAttribute("EyeSize", eyeSize)

	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Anchored = false
		eye.CanCollide = false
		eye.Material = eyeColor and Enum.Material.Neon or Enum.Material.SmoothPlastic
		eye.Color = eyeColor or Color3.new(1, 1, 1)
		eye.Size = Vector3.new(eyeSize, eyeSize, eyeSize)
		eye.CFrame = body.CFrame * eyeOffsetCFrame(side, bodyRadius)
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

-- Eyebrows (tilt) + mouth (size), both driven by a FACE_PRESETS entry.
-- Rebuildable: called once at construction with DEFAULT_FACE, and again
-- (after destroying the previous copies) whenever ApplyMood changes it.
local function buildFace(body, bodyRadius, preset)
	local eyeSize = body:GetAttribute("EyeSize") or bodyRadius * 0.55

	for _, side in ipairs({ -1, 1 }) do
		local sideName = side < 0 and "L" or "R"
		local angle = side < 0 and preset.BrowL or preset.BrowR

		local eyebrow = Instance.new("Part")
		eyebrow.Name = "Eyebrow_" .. sideName
		eyebrow.Shape = Enum.PartType.Block
		eyebrow.Anchored = false
		eyebrow.CanCollide = false
		eyebrow.Material = Enum.Material.SmoothPlastic
		eyebrow.Color = Color3.fromRGB(30, 25, 25)
		eyebrow.Size = Vector3.new(eyeSize * 0.9, eyeSize * 0.2, eyeSize * 0.25)
		-- Sits above and slightly forward of the eye, in the eye's own local
		-- space, tilted by this Mood's brow angle for that eye.
		eyebrow.CFrame = body.CFrame
			* eyeOffsetCFrame(side, bodyRadius)
			* CFrame.new(0, eyeSize * 0.85, eyeSize * 0.15)
			* CFrame.Angles(0, 0, math.rad(-side * angle))
		eyebrow.Parent = body.Parent
		weld(eyebrow, body)
	end

	local mouth = Instance.new("Part")
	mouth.Name = "Mouth"
	mouth.Shape = Enum.PartType.Ball
	mouth.Anchored = false
	mouth.CanCollide = false
	mouth.Material = Enum.Material.SmoothPlastic
	mouth.Color = Color3.fromRGB(40, 30, 30)

	local baseSize = bodyRadius * 0.22
	mouth.Size = Vector3.new(baseSize * preset.MouthSizeX, baseSize * preset.MouthSizeY, baseSize * 0.6)
	mouth.CFrame = body.CFrame * CFrame.new(0, -bodyRadius * 0.15, -bodyRadius * 0.88)
	mouth.Parent = body.Parent
	weld(mouth, body)
end

-- Two symmetric shapes on top of the head -- the single biggest lever on
-- silhouette, since it's the one part of the shape that's genuinely
-- different per evolution (see CritterDefinitions.HeadNubShape). "Round"
-- is Pip's own baby-form nubs; everything else is a real evolution.
local function buildHeadNubs(body, bodyRadius, shape, color)
	for _, side in ipairs({ -1, 1 }) do
		local nub = Instance.new("Part")
		nub.Name = "HeadNub"
		nub.Anchored = false
		nub.CanCollide = false
		nub.Material = Enum.Material.SmoothPlastic
		nub.Color = color

		local baseOffset = CFrame.new(side * bodyRadius * 0.45, bodyRadius * 0.8, -bodyRadius * 0.1)
		local tilt = CFrame.Angles(0, 0, math.rad(-side * 18))

		if shape == "Flame" then
			nub.Shape = Enum.PartType.Ball
			nub.Size = Vector3.new(bodyRadius * 0.35, bodyRadius * 0.6, bodyRadius * 0.35)
			nub.CFrame = body.CFrame * baseOffset * tilt
		elseif shape == "Fin" then
			nub.Shape = Enum.PartType.Wedge
			nub.Size = Vector3.new(bodyRadius * 0.15, bodyRadius * 0.55, bodyRadius * 0.4)
			nub.CFrame = body.CFrame * baseOffset * tilt * CFrame.Angles(math.rad(20), 0, 0)
		elseif shape == "Leaf" then
			nub.Shape = Enum.PartType.Block
			nub.Size = Vector3.new(bodyRadius * 0.55, bodyRadius * 0.1, bodyRadius * 0.35)
			nub.CFrame = body.CFrame * baseOffset * tilt
		elseif shape == "Horn" then
			nub.Shape = Enum.PartType.Block
			nub.Size = Vector3.new(bodyRadius * 0.16, bodyRadius * 0.65, bodyRadius * 0.16)
			nub.CFrame = body.CFrame * baseOffset * CFrame.Angles(0, 0, math.rad(-side * 28))
		elseif shape == "Spark" then
			nub.Shape = Enum.PartType.Ball
			nub.Material = Enum.Material.Neon
			nub.Size = Vector3.new(bodyRadius * 0.28, bodyRadius * 0.28, bodyRadius * 0.28)
			nub.CFrame = body.CFrame * baseOffset

			local light = Instance.new("PointLight")
			light.Color = color
			light.Brightness = 2
			light.Range = 8
			light.Parent = nub
		else -- "Round" (Pip's default ear-buds)
			nub.Shape = Enum.PartType.Ball
			nub.Size = Vector3.new(bodyRadius * 0.32, bodyRadius * 0.4, bodyRadius * 0.32)
			nub.CFrame = body.CFrame * baseOffset * tilt
		end

		nub.Parent = body.Parent
		weld(nub, body)
	end
end

-- A small tail with its own gentle, continuous wag -- cheap personality
-- that never conflicts with the body's idle bob (different part,
-- different property lineage).
local function buildTail(body, bodyRadius, color)
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Shape = Enum.PartType.Ball
	tail.Anchored = false
	tail.CanCollide = false
	tail.Material = Enum.Material.SmoothPlastic
	tail.Color = color
	tail.Size = Vector3.new(bodyRadius * 0.32, bodyRadius * 0.32, bodyRadius * 0.5)

	local restCFrame = body.CFrame * CFrame.new(0, -bodyRadius * 0.1, bodyRadius * 0.95) * CFrame.Angles(math.rad(15), 0, 0)
	tail.CFrame = restCFrame
	tail.Parent = body.Parent
	weld(tail, body)

	local wag = TweenService:Create(
		tail,
		TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = restCFrame * CFrame.Angles(0, math.rad(22), 0) }
	)
	wag:Play()
end

-- Two stubby feet peeking out from under the body -- the second biggest
-- lever on "this is a creature sitting somewhere," not a floating ball.
local function buildFeet(body, bodyRadius, color)
	for _, side in ipairs({ -1, 1 }) do
		local foot = Instance.new("Part")
		foot.Name = "Foot"
		foot.Shape = Enum.PartType.Ball
		foot.Anchored = false
		foot.CanCollide = false
		foot.Material = Enum.Material.SmoothPlastic
		foot.Color = color
		foot.Size = Vector3.new(bodyRadius * 0.4, bodyRadius * 0.3, bodyRadius * 0.4)
		foot.CFrame = body.CFrame * CFrame.new(side * bodyRadius * 0.42, -bodyRadius * 0.78, -bodyRadius * 0.25)
		foot.Parent = body.Parent
		weld(foot, body)
	end
end

-- A lighter belly patch, mostly embedded in the body so only its
-- outward-facing cap shows -- the cheapest possible two-tone read without
-- CSG, and a very common trick in stylized creature design.
local function buildBelly(body, bodyRadius, accentColor)
	local belly = Instance.new("Part")
	belly.Name = "Belly"
	belly.Shape = Enum.PartType.Ball
	belly.Anchored = false
	belly.CanCollide = false
	belly.Material = Enum.Material.SmoothPlastic
	belly.Color = accentColor
	belly.Size = Vector3.new(bodyRadius * 1.5, bodyRadius * 1.1, bodyRadius * 1.7)
	belly.CFrame = body.CFrame * CFrame.new(0, -bodyRadius * 0.7, bodyRadius * 0.1)
	belly.Parent = body.Parent
	weld(belly, body)
end

local function buildAmbientParticle(body, particleType, color)
	local config = particleType and AMBIENT_PARTICLE_CONFIG[particleType]
	if not config then
		return
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AmbientParticle"
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = config.Lifetime
	emitter.Speed = config.Speed
	emitter.Acceleration = config.Acceleration
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Rate = config.Rate
	emitter.Parent = body
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

	-- A slightly squashed, elongated ellipsoid instead of a true sphere --
	-- the single cheapest change that stops this from reading as "a ball."
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = definition.BodyColor
	body.Size = Vector3.new(bodyDiameter * 1.02, bodyDiameter * 0.92, bodyDiameter * 1.18)
	body.Parent = model
	model.PrimaryPart = body
	body:SetAttribute("BaseColor", definition.BodyColor)
	body:SetAttribute("BodyRadius", bodyRadius)

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

	buildBelly(body, bodyRadius, definition.AccentColor or definition.BodyColor)
	buildEyes(body, bodyRadius, definition.EyeColor)
	buildFace(body, bodyRadius, DEFAULT_FACE)
	buildHeadNubs(body, bodyRadius, definition.HeadNubShape or "Round", definition.HeadNubColor or definition.BodyColor)
	buildTail(body, bodyRadius, definition.HeadNubColor or definition.AccentColor or definition.BodyColor)
	buildFeet(body, bodyRadius, definition.HeadNubColor or definition.BodyColor)
	buildAmbientParticle(body, definition.AmbientParticle, definition.HeadNubColor or definition.BodyColor)
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

-- Occasionally turns to face the nearest player (or just glances around if
-- no one's close) -- cheap personality ("this Critter notices you") on top
-- of the idle bob. Reuses the same pause/resume handshake PlayReaction
-- already does for its hop; a reaction landing mid-turn is a known,
-- purely-cosmetic edge case (the idle bob may resume a beat early), not a
-- correctness risk.
local function startLookAroundLoop(plot)
	lookAroundActive[plot.Index] = true

	task.spawn(function()
		while lookAroundActive[plot.Index] do
			task.wait(6 + math.random() * 5)
			if not lookAroundActive[plot.Index] then
				break
			end

			local idleEntry = idleTweens[plot.Index]
			local model = spawnedModels[plot.Index]
			if not idleEntry or not model or not model.PrimaryPart then
				continue
			end

			local body = model.PrimaryPart
			local restCFrame = idleEntry.RestCFrame
			local targetAngle

			local nearestDistance = 40
			local nearestPosition = nil
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					local distance = (root.Position - restCFrame.Position).Magnitude
					if distance < nearestDistance then
						nearestDistance = distance
						nearestPosition = root.Position
					end
				end
			end

			if nearestPosition then
				local lookCFrame = CFrame.lookAt(restCFrame.Position, nearestPosition)
				local _, relativeYaw = (restCFrame:Inverse() * lookCFrame):ToEulerAnglesYXZ()
				targetAngle = math.clamp(relativeYaw, math.rad(-50), math.rad(50))
			else
				targetAngle = math.rad((math.random() * 50) - 25)
			end

			idleEntry.Tween:Pause()
			local turnTo = TweenService:Create(
				body,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ CFrame = restCFrame * CFrame.Angles(0, targetAngle, 0) }
			)
			turnTo:Play()
			turnTo.Completed:Wait()

			task.wait(1.5 + math.random())

			if lookAroundActive[plot.Index] and idleTweens[plot.Index] == idleEntry then
				local turnBack =
					TweenService:Create(body, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						CFrame = restCFrame,
					})
				turnBack:Play()
				turnBack.Completed:Wait()
				if lookAroundActive[plot.Index] and idleTweens[plot.Index] == idleEntry then
					idleEntry.Tween:Play()
				end
			end
		end
	end)
end

local function stopLookAroundLoop(plotIndex)
	lookAroundActive[plotIndex] = false
end

-- Retunes the standing face (eyebrows + mouth) to the current Mood.
-- Rebuilds those two parts rather than tweening them in place: they're
-- WeldConstraint'd to the body for correct bob/hop/turn tracking, and a
-- WeldConstraint locks the relative transform it was given at creation --
-- fighting that with a live Tween would just get overridden by the
-- constraint. Destroy-and-recreate at the body's *current* pose is simpler
-- and correct. Called from StateService.Push, which already fires on
-- essentially every meaningful action, so the face stays current without
-- needing its own separate trigger plumbing.
function CritterService.ApplyMood(plot, mood)
	local model = spawnedModels[plot.Index]
	if not model or not mood then
		return
	end

	local body = model.PrimaryPart
	if not body then
		return
	end

	local bodyRadius = body:GetAttribute("BodyRadius")
	if not bodyRadius then
		return
	end

	local preset = FACE_PRESETS[mood.Label] or DEFAULT_FACE

	for _, name in ipairs({ "Eyebrow_L", "Eyebrow_R", "Mouth" }) do
		local existing = model:FindFirstChild(name)
		if existing then
			destroyWelded(existing, body)
		end
	end

	buildFace(body, bodyRadius, preset)
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

-- A brief, intensifying pulse on the *current* (pre-evolution) model --
-- "a short buildup begins" before the actual transform. Plays entirely on
-- the outgoing model, which RefreshVisual destroys right after, so nothing
-- here needs to be reset to a clean state.
function CritterService.PlayEvolutionBuildup(plot, color)
	local model = spawnedModels[plot.Index]
	if not model or not model.PrimaryPart then
		return 0
	end
	local body = model.PrimaryPart

	local pulse = TweenService:Create(
		body,
		TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true),
		{ Color = color }
	)
	pulse:Play()

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.4, 0.7)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 30
	emitter.Parent = body
	Debris:AddItem(emitter, 2)

	return 1.8 -- seconds the caller should wait before swapping the model
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
	startLookAroundLoop(plot)
end

function CritterService.ClearPlotVisual(plot)
	stopIdleAnimation(plot.Index)
	stopLookAroundLoop(plot.Index)
	local existing = spawnedModels[plot.Index]
	if existing then
		existing:Destroy()
		spawnedModels[plot.Index] = nil
	end
end

return CritterService
