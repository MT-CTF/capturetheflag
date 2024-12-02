-- beds/init.lua

-- Load support for MT game translation.
local S = minetest.get_translator("beds")

beds = {}
beds.bed_position = {}
beds.pos = {}
beds.get_translator = S



local modpath = minetest.get_modpath("beds")

-- Load files

dofile(modpath .. "/functions.lua")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/beds.lua")
