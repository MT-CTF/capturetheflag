unused_args = false

globals = {
	"PlayerObj", "PlayerName", "HumanReadable", "RunCallbacks",

	"ctf_gui", "hud_events", "mhud", "physics", "rawf", "ctf_settings",

	"ctf_api", "ctf_chat", "ctf_combat_mode", "ctf_core", "ctf_cosmetics",
	"ctf_healing", "ctf_kill_list", "ctf_map", "ctf_melee", "ctf_modebase",
	"ctf_ranged", "ctf_rankings", "ctf_report", "ctf_teams", "ctf_player",

	"dropondie", "grenades",

	"chatcmdbuilder", "crafting", "hpbar", "playertag", "random_messages",
	"skybox", "throwable_snow", "worldedit", "filter",

	"default", "doors", "player_api", "sfinv", "binoculars",

	"vector",
	math = {
		fields = {
			"round",
			"hypot",
			"sign",
			"factorial",
			"ceil",
		}
	},

	"minetest", "core",
}

exclude_files = {
	"mods/other/crafting",
	"mods/mtg/mtg_*",
	"mods/other/real_suffocation",
	"mods/other/lib_chatcmdbuilder",
	"mods/other/email",
	"mods/other/select_item",
}

read_globals = {
	"DIR_DELIM",
	"dump", "dump2",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "PcgRandom",
	"ItemStack",
	"Settings",
	"unpack",
	"loadstring",

	table = {
		fields = {
			"copy",
			"indexof",
			"insert_all",
			"key_value_swap",
			"shuffle",
			"random",
		}
	},

	string = {
		fields = {
			"split",
			"trim",
		}
	},
}
