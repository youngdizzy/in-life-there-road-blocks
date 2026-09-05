-- Tiny shared helper for the procedural-Part builders (WorldBuilder,
-- HabitatBuilder): construct-and-configure in one call instead of five
-- lines of property assignment repeated at every call site.

local PartUtil = {}

function PartUtil.new(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		part[key] = value
	end
	return part
end

return PartUtil
