ctf_map = {}

function ctf_map.get_team_relative_z(player)
	local name = player:get_player_name()
	local tname = ctf.player(name).team
	return (tname == "red" and 1 or -1) * player:get_pos().z
end

-- Overridden by server mods
function ctf_map.can_cross(player)
	return false
end

dofile(minetest.get_modpath("ctf_map") .. "/nodes.lua")
dofile(minetest.get_modpath("ctf_map") .. "/emerge.lua")
dofile(minetest.get_modpath("ctf_map") .. "/barrier.lua")
dofile(minetest.get_modpath("ctf_map") .. "/base.lua")

if minetest.get_modpath("ctf") then
	dofile(minetest.get_modpath("ctf_map") .. "/chest.lua")
	dofile(minetest.get_modpath("ctf_map") .. "/schem_map.lua")
	dofile(minetest.get_modpath("ctf_map") .. "/give_initial_stuff.lua")

	assert(ctf_match)
	ctf_match.register_on_build_time_end(ctf_map.remove_middle_barrier)
else
	dofile(minetest.get_modpath("ctf_map") .. "/map_maker.lua")
end
