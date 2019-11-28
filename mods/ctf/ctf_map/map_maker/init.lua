-- Dofile the scripts only if ctf doesn't exist
if not minetest.global_exists("ctf") then
	local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"
	dofile(modpath .. "map_maker.lua")
end
