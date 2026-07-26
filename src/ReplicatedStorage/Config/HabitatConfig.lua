-- Layout for the personal habitat grid. No income tick, no theft, no
-- multiplayer interaction between plots in v1 -- just a home for Pip.
-- (See GAME_DESIGN.md: habitats become the social flex zone later, once
-- SHOW OFF/TRADE are built; v1 only needs a place for Pip to live.)

local HabitatConfig = {
	GridColumns = 5,
	GridRows = 4,
	PlotSize = Vector2.new(28, 28),
	PlotSpacing = 10,
	ZoneRadius = 9, -- distance from plot center each Environment Zone prop sits at
}

return HabitatConfig
