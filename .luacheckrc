unused_args = false

globals = {
	"ctf_core", "ctf_map", "ctf_teams", "ctf_modebase", "ctf_gui",
	"ctf_rankings", "ctf_playertag", "ctf_melee", "ctf_ranged", "ctf_combat_mode",
	"ctf_kill_list", "ctf_healing", "ctf_cosmetics",

	"PlayerObj", "PlayerName", "HumanReadable", "RunCallbacks",

	"chatcmdbuilder", "mhud", "rawf", "chatplus",

	"physics", "give_initial_stuff", "medkits", "grenades", "dropondie",
	"vote", "random_messages", "sfinv", "email", "hb", "wield3d", "irc",
	"default", "skybox", "crafting", "doors", "hud_events",

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
			"count",
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
