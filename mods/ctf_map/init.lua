ctf_map = {}

dofile(minetest.get_modpath("ctf_map") .. "/nodes.lua")
dofile(minetest.get_modpath("ctf_map") .. "/emerge.lua")
dofile(minetest.get_modpath("ctf_map") .. "/barrier.lua")


if minetest.get_modpath("ctf") then
	dofile(minetest.get_modpath("ctf_map") .. "/schem_map.lua")
	dofile(minetest.get_modpath("ctf_map") .. "/give_initial_stuff.lua")

	assert(ctf_match)
	ctf_match.register_on_build_time_end(ctf_map.remove_middle_barrier)
else
	dofile(minetest.get_modpath("ctf_map") .. "/map_maker.lua")
end
