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
	start_time = nil,
	get_duration = function ()
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

-- Attempt to restore user's time speed after server close
local TIME_SPEED = minetest.settings:get("time_speed")

minetest.register_on_shutdown(function()
	minetest.settings:set("time_speed", TIME_SPEED)
end)
