-- Dofile the scripts only if ctf doesn't exist
if not minetest.global_exists("ctf") then
	map_maker = {}

	local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"
	dofile(modpath .. "gui.lua")
	dofile(modpath .. "map_maker.lua")
end
