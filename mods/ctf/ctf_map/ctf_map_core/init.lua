ctf_map = {}

function ctf_map.get_team_relative_z(player)
	local name = player:get_player_name()
	local tname = ctf.player(name).team
	return (tname == "red" and 1 or -1) * player:get_pos().z
end

-- Convenience function to check whether a file (or multiple files) exists in mapdir
function ctf_map.file_exists(subdir, target)
	local list = minetest.get_dir_list(ctf_map.mapdir .. subdir, false)
	if type(target) == "string" then
		return table.indexof(list, target) ~= -1
	elseif type(target) == "table" then
		for _, filename in pairs(target) do
			if table.indexof(list, filename) == -1 then
				return false
			end
		end
		return true
	end
end

-- Overridden by server mods
function ctf_map.can_cross(player)
	return false
end

-- Modify MTG's stone pickaxe to be capable of breaking cracky=1 nodes
-- Do it here, for lack of a better place
do
local tool_caps = minetest.registered_items["default:pick_stone"].tool_capabilities
tool_caps.groupcaps.cracky.times[1] = 12.0
minetest.override_item("default:pick_stone", {
	tool_capabilities = tool_caps
})
end

local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/emerge.lua")
dofile(modpath .. "/barrier.lua")

if minetest.get_modpath("ctf") then
	dofile(modpath .. "/base.lua")
	dofile(modpath .. "/chest.lua")
	dofile(modpath .. "/meta_helpers.lua")
	dofile(modpath .. "/schem_map.lua")
	dofile(modpath .. "/maps_catalog.lua")

	ctf_match.register_on_build_time_end(ctf_map.remove_middle_barrier)

	give_initial_stuff.register_stuff_provider(function(player)
		return ctf_map.map and ctf_map.map.initial_stuff or {
			"default:pick_stone",
			"default:torch 3",
		}
	end)
end
