if not ctf_core.settings.server_mode or ctf_core.settings.server_mode == "play" then
	assert(
		minetest.get_mapgen_setting("mg_name") == "singlenode",
		"If you create a map, you must enable creative mode. If you want to play, you must use the singlenode mapgen."
	)
end

minetest.register_alias("mapgen_singlenode", "ctf_map:ignore")

ctf_map = {
	DEFAULT_CHEST_AMOUNT = 42,
	DEFAULT_START_TIME = 5900,
	CHAT_COLOR = "orange",
	maps_dir = minetest.get_modpath("ctf_map").."/maps/",
	skyboxes = {"none"},
	current_map = false,
	barrier_nodes = {}, -- populated in nodes.lua,
	start_time = false,
	get_duration = function()
		if not ctf_map.start_time then
			return "-"
		end

		local time = os.time() - ctf_map.start_time
		return string.format("%02d:%02d:%02d",
			math.floor(time / 3600),        -- hours
			math.floor((time % 3600) / 60), -- minutes
			math.floor(time % 60))          -- seconds
	end,
}

ctf_api.register_on_match_start(function()
	ctf_map.start_time = os.time()
end)

ctf_api.register_on_match_end(function()
	minetest.after(0, function()
		ctf_map.start_time = nil
	end)
end)

for _, s in ipairs(skybox.get_skies()) do
	table.insert(ctf_map.skyboxes, s[1])
end

local old_add_skies = skybox.add
skybox.add = function(def, ...)
	table.insert(ctf_map.skyboxes, def[1])
	old_add_skies(def, ...)
end

minetest.register_tool("ctf_map:adminpick", {
	description = "Admin pickaxe used to break indestructible nodes.\nRightclick to remove non-indestructible nodes",
	inventory_image = "default_tool_diamondpick.png^default_obsidian_shard.png",
	range = 16,
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level = 3,
		groupcaps = {
			immortal = {times = {[1] = 0.2}, uses = 0, maxlevel = 3}
		},
		damage_groups = {fleshy = 10000}
	},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing and pointed_thing.under then
			minetest.remove_node(pointed_thing.under)
		end
	end,
})

minetest.register_privilege("ctf_map_editor", {
	description = "Allows use of map editing features",
	give_to_singleplayer = false,
	give_to_admin = false,
})

local registered_commands = {}
local command_params = {}
function ctf_map.register_map_command(match, func)
	registered_commands[match] = func
	table.insert(command_params, "["..match.."]")
end

ctf_core.include_files(
	"emerge.lua",
	"nodes.lua",
	"map_meta.lua",
	"map_functions.lua",
	"editor_functions.lua",
	"mapedit_gui.lua",
	"ctf_traps.lua"
)

local directory = minetest.get_modpath(minetest.get_current_modname()) .. "/maps/"

for _, entry in ipairs(minetest.get_dir_list(directory, true)) do
	for _, filename in ipairs(minetest.get_dir_list(directory .. "/" .. entry .. "/", false)) do
		if filename == "init.lua" then
			dofile(directory .. "/" .. entry .. "/"..filename)
		end
	end
end


minetest.register_chatcommand("ctf_map", {
	description = "Run map related commands",
	privs = {ctf_map_editor = true},
	params = "[editor | e] | "..table.concat(command_params, " | "),
	func = function(name, params)
		if not params or params == "" then
			return false, "/ctf_map [editor | e] | "..table.concat(command_params, " | ")
		end

		params = string.split(params, " ")

		if params[1] == "e" or params[1] == "editor" then
			local inv = PlayerObj(name):get_inventory()

			if not inv:contains_item("main", "ctf_map:adminpick") then
				inv:add_item("main", "ctf_map:adminpick")
			end

			if ctf_core.settings.server_mode ~= "mapedit" then
				minetest.chat_send_player(name,
						minetest.colorize("red", "It is not recommended to edit maps unless the server is in mapedit mode\n"..
							"To enable mapedit mode, enable creative mode."))
			end

			ctf_map.show_map_editor(name)

			return true
		end

		for match, func in pairs(registered_commands) do
			if params[1]:match(match) then
				table.remove(params, 1)
				return func(name, params)
			end
		end

		return false
	end
})

minetest.register_chatcommand("map", {
	description = "Prints the current map name and map author",
	func = function()
		local map = ctf_map.current_map

		if not map then
			return false, "There is no map currently in play"
		end

		local mapName = map.name or "Unknown"
		local mapAuthor = map.author or "Unknown Author"
		local mapDuration =  ctf_map.get_duration()

		return true, string.format("The current map is %s by %s. Map duration: %s", mapName, mapAuthor, mapDuration)
	end
})

minetest.register_chatcommand("ctf_barrier", {
	description = "Place or remove map barriers\n" ..
		"place_buildtime: Within the selected area, replace certain nodes with the " ..
		"corresponding build-time barrier\nremove_buildtime: Remove build-time " ..
		"barriers within the selected area\nplace_outer: Surrounds the selected area " ..
		"with an indestructible glass/stone barrier",
	privs = {ctf_map_editor = true},
	params = "[place_buildtime] | [remove_buildtime] | [place_outer]",
	func = function(name, params)
		if not params or params == "" then
			return false, "See /help ctf_barrier for usage instructions"
		end

		if ctf_core.settings.server_mode ~= "mapedit" then
			return false, minetest.colorize("red", "You have to be in mapedit mode to run this")
		end

		if params ~= "place_buildtime" and params ~= "remove_buildtime" and params ~= "place_outer" then
			return false
		end

		if params == "place_outer" then
			minetest.chat_send_player(name,
				minetest.colorize("yellow", "Warning: this action can't be undone"))
		end

		ctf_map.get_pos_from_player(name, 2, function(p, positions)
			local pos1, pos2 = vector.sort(positions[1], positions[2])

			if params == "place_buildtime" and pos1.x ~= pos2.x and pos1.z ~= pos2.z then
				minetest.chat_send_player(name, minetest.colorize("yellow",
					"Warning: your build-time barrier is more than 1 node thick, " ..
					"use /ctf_barrier remove_buildtime to remove unwanted parts"))
			end

			local vm = minetest.get_voxel_manip()
			local emin, emax = vm:read_from_map(pos1, pos2)
			local a = VoxelArea:new{
				MinEdge = emin,
				MaxEdge = emax
			}
			local data = vm:get_data()

			for x = pos1.x, pos2.x do
				for y = pos1.y, pos2.y do
					for z = pos1.z, pos2.z do
						local vi = a:index(x, y, z)
						if params == "place_buildtime" then
							if data[vi] == minetest.get_content_id("air") then
								data[vi] = minetest.get_content_id("ctf_map:ind_glass_red")
							elseif data[vi] == minetest.get_content_id("default:stone") then
								data[vi] = minetest.get_content_id("ctf_map:ind_stone_red")
							elseif data[vi] == minetest.get_content_id("default:water_source") then
								data[vi] = minetest.get_content_id("ctf_map:ind_water")
							elseif data[vi] == minetest.get_content_id("default:lava_source") then
								data[vi] = minetest.get_content_id("ctf_map:ind_lava")
							end
						elseif params == "remove_buildtime" then
							if data[vi] == minetest.get_content_id("ctf_map:ind_glass_red") then
								data[vi] = minetest.get_content_id("air")
							elseif data[vi] == minetest.get_content_id("ctf_map:ind_stone_red") then
								data[vi] = minetest.get_content_id("default:stone")
							elseif data[vi] == minetest.get_content_id("ctf_map:ind_water") then
								data[vi] = minetest.get_content_id("default:water_source")
							elseif data[vi] == minetest.get_content_id("ctf_map:ind_lava") then
								data[vi] = minetest.get_content_id("default:lava_source")
							end
						elseif params == "place_outer" then
							if x == pos1.x or x == pos2.x or y == pos1.y
								or z == pos1.z or z == pos2.z then
								if data[vi] == minetest.get_content_id("air") or
									data[vi] == minetest.get_content_id("ignore") or
									data[vi] == minetest.get_content_id("ctf_map:ignore") then
									data[vi] = minetest.get_content_id("ctf_map:ind_glass")
								else
									data[vi] = minetest.get_content_id("ctf_map:stone")
								end
							end
						end
					end
				end
			end

			vm:set_data(data)
			vm:write_to_map(true)

			local message =
				(params == "place_buildtime" and "Build-time barrier placed") or
				(params == "remove_buildtime" and "Build-time barrier removed") or
				(params == "place_outer" and "Outer barrier placed")
			minetest.chat_send_player(name, message)
		end)
	end
})

-- Attempt to restore user's time speed after server close
local TIME_SPEED = minetest.settings:get("time_speed")

minetest.register_on_shutdown(function()
	minetest.settings:set("time_speed", TIME_SPEED)
end)
