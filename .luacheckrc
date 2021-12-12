unused_args = false

globals = {
	"ctf_api", "ctf_core", "ctf_map", "ctf_chat", "ctf_teams", "ctf_modebase",
	"ctf_rankings", "ctf_playertag", "ctf_melee", "ctf_ranged", "ctf_combat_mode",
	"ctf_kill_list", "ctf_healing", "ctf_cosmetics", "ctf_report", "ctf_hpbar",

	"mhud", "rawf", "physics", "hud_events", "ctf_gui",

	"PlayerObj", "PlayerName", "HumanReadable", "RunCallbacks",

	"grenades", "email", "hb", "dropondie", "random_messages", "default",
	"skybox", "crafting", "doors", "throwable_snow", "chatcmdbuilder",

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
