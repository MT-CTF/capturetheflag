if not ctf_core.settings.server_mode or ctf_core.settings.server_mode == "play" then
	assert(
		minetest.get_mapgen_setting("mg_name") == "singlenode",
		"You must use singlenode mapgen when ctf_server_mode is set to 'play'"
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
	barrier_nodes = {}, -- populated in nodes.lua
	treasurefy_node = function(pos) end, -- See ctf_modebase for function
}

minetest.register_on_mods_loaded(function()
	local skyboxlist = skybox.get_skies()

	for _, s in ipairs(skyboxlist) do
		table.insert(ctf_map.skyboxes, s[1])
	end
end)

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
	"mapedit_gui.lua"
)

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

			if not ctf_core.settings.server_mode == "mapedit" then
				minetest.chat_send_player(name,
						minetest.colorize("red", "It is not recommended to edit maps unless the server is in mapedit mode"))
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

-- Attempt to restore user's time speed after server close
local TIME_SPEED = minetest.settings:get("time_speed")

minetest.register_on_shutdown(function()
	minetest.settings:set("time_speed", TIME_SPEED)
end)
