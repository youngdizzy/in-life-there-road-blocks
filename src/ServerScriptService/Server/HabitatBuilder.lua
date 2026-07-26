-- Procedurally builds the player-habitat neighborhood: a ground patch
-- connecting it to the Meadow's south path (see WorldBuilder), and a grid
-- of personal habitats (platform + fence + Pip's pedestal + owner sign).
-- Building it in code means there's no binary .rbxl to keep in sync with
-- git -- the whole world lives here as real source.
--
-- The four Environment Zones used to live one-per-habitat; they're now the
-- shared public Verdant Wilds / Ember Zone / Tidepool / Gloom Grove
-- destinations built by WorldBuilder, so a habitat's job is now just "a
-- home for Pip and a display for your Critter," per the map's own brief.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HabitatConfig = require(ReplicatedStorage.Config.HabitatConfig)
local WorldConfig = require(ReplicatedStorage.Config.WorldConfig)
local PartUtil = require(ReplicatedStorage.Modules.PartUtil)

local HabitatBuilder = {}

local newPart = PartUtil.new

-- A single, small "welcome mat" under the pedestal -- one deliberate touch
-- of coziness, not a decorating system. Sits flush with the platform so it
-- reads as a rug, not another step.
local function buildPedestal(plotModel, platformCFrame)
	newPart({
		Name = "Rug",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.1, 7, 7),
		Color = Color3.fromRGB(200, 110, 90),
		Material = Enum.Material.Fabric,
		CanCollide = false,
		CFrame = platformCFrame * CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = plotModel,
	})

	local pedestal = newPart({
		Name = "Pedestal",
		Size = Vector3.new(5, 1, 5),
		Color = Color3.fromRGB(230, 220, 190),
		Material = Enum.Material.Sand,
		CFrame = platformCFrame * CFrame.new(0, 0.5, 0),
		Parent = plotModel,
	})
	return pedestal
end

-- A low perimeter fence around the platform edge -- just enough that a
-- habitat reads as "this is MY space" (see GAME_DESIGN.md Phase 6), not a
-- decorating system. Non-collide so it never blocks the player.
local FENCE_HEIGHT = 1.5
local FENCE_THICKNESS = 0.4

local function buildPerimeterFence(plotModel, platformCFrame)
	local halfX = HabitatConfig.PlotSize.X / 2
	local halfZ = HabitatConfig.PlotSize.Y / 2
	local railY = 1 + FENCE_HEIGHT / 2 -- platform top (Size.Y/2 = 1) plus half the fence's own height

	local rails = {
		{ Size = Vector3.new(HabitatConfig.PlotSize.X, FENCE_HEIGHT, FENCE_THICKNESS), Offset = CFrame.new(0, railY, halfZ) },
		{
			Size = Vector3.new(HabitatConfig.PlotSize.X, FENCE_HEIGHT, FENCE_THICKNESS),
			Offset = CFrame.new(0, railY, -halfZ),
		},
		{ Size = Vector3.new(FENCE_THICKNESS, FENCE_HEIGHT, HabitatConfig.PlotSize.Y), Offset = CFrame.new(halfX, railY, 0) },
		{
			Size = Vector3.new(FENCE_THICKNESS, FENCE_HEIGHT, HabitatConfig.PlotSize.Y),
			Offset = CFrame.new(-halfX, railY, 0),
		},
	}

	for i, rail in ipairs(rails) do
		newPart({
			Name = "FenceRail" .. i,
			Size = rail.Size,
			Color = Color3.fromRGB(120, 90, 60),
			Material = Enum.Material.WoodPlanks,
			CanCollide = false,
			CFrame = platformCFrame * rail.Offset,
			Parent = plotModel,
		})
	end
end

local function buildOwnerSign(plotModel, platformCFrame)
	local signPart = newPart({
		Name = "SignPart",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CFrame = platformCFrame * CFrame.new(0, 6, -(HabitatConfig.PlotSize.Y / 2) - 1),
		Parent = plotModel,
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OwnerBillboard"
	billboard.Size = UDim2.fromOffset(220, 50)
	billboard.AlwaysOnTop = true
	billboard.Parent = signPart

	local label = Instance.new("TextLabel")
	label.Name = "OwnerName"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Empty Habitat"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	return signPart
end

function HabitatBuilder.Build()
	local workspace = game:GetService("Workspace")

	local totalWidth = HabitatConfig.GridColumns * (HabitatConfig.PlotSize.X + HabitatConfig.PlotSpacing)
	local totalDepth = HabitatConfig.GridRows * (HabitatConfig.PlotSize.Y + HabitatConfig.PlotSpacing)
	local center = WorldConfig.HabitatNeighborhoodCenter

	-- Ground runs from the entrance sign (where WorldBuilder's south path
	-- ends) all the way past the last row of plots, so there's no gap
	-- between "the path from the Meadow" and "the neighborhood itself."
	local groundNorthZ = WorldConfig.HabitatEntrance.Z
	local groundSouthZ = center.Z + totalDepth / 2 + 20
	local groundDepth = groundSouthZ - groundNorthZ
	local groundCenterZ = (groundNorthZ + groundSouthZ) / 2

	newPart({
		Name = "NeighborhoodGround",
		Size = Vector3.new(totalWidth + 40, 4, groundDepth),
		Color = Color3.fromRGB(150, 190, 150),
		Material = Enum.Material.Grass,
		CFrame = CFrame.new(center.X, -2, groundCenterZ),
		Parent = workspace,
	})

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Habitats"
	plotsFolder.Parent = workspace

	local plots = {}
	local startX = center.X - (HabitatConfig.GridColumns - 1) * (HabitatConfig.PlotSize.X + HabitatConfig.PlotSpacing) / 2
	local startZ = center.Z - (HabitatConfig.GridRows - 1) * (HabitatConfig.PlotSize.Y + HabitatConfig.PlotSpacing) / 2

	local index = 0
	for row = 0, HabitatConfig.GridRows - 1 do
		for col = 0, HabitatConfig.GridColumns - 1 do
			index += 1

			local x = startX + col * (HabitatConfig.PlotSize.X + HabitatConfig.PlotSpacing)
			local z = startZ + row * (HabitatConfig.PlotSize.Y + HabitatConfig.PlotSpacing)
			local platformCFrame = CFrame.new(x, 0, z)

			local plotModel = Instance.new("Folder")
			plotModel.Name = "Habitat" .. index
			plotModel.Parent = plotsFolder

			local platform = newPart({
				Name = "Platform",
				Size = Vector3.new(HabitatConfig.PlotSize.X, 2, HabitatConfig.PlotSize.Y),
				Color = Color3.fromRGB(150, 190, 150),
				Material = Enum.Material.Ground,
				CFrame = platformCFrame,
				Parent = plotModel,
			})

			buildPerimeterFence(plotModel, platformCFrame)
			local pedestal = buildPedestal(plotModel, platformCFrame)
			local sign = buildOwnerSign(plotModel, platformCFrame)

			plots[index] = {
				Index = index,
				Model = plotModel,
				Platform = platform,
				Pedestal = pedestal,
				Sign = sign,
				CFrame = platformCFrame,
				OwnerUserId = nil,
			}
		end
	end

	return plots
end

return HabitatBuilder
