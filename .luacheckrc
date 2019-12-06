unused_args = false
allow_defined_top = true

exclude_files = {
	"mods/mtg/default",
	"mods/ctf_pvp_engine",
	"mods/pvp/shooter",
	"mods/other/wield3d",
	"mods/other/treasurer",
}

ignore = {"631"}

globals = {
	"crafting", "vector", "table", "minetest", "worldedit", "ctf", "ctf_flag",
	"ctf_colors", "hudkit", "default", "treasurer", "ChatCmdBuilder", "ctf_map",
	"ctf_match", "ctf_stats", "ctf_treasure", "ctf_playertag", "chatplus", "irc",
	"armor", "vote", "give_initial_stuff", "hud_score", "physics", "tsm_chests"
}

read_globals = {
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	"dump", "DIR_DELIM",
	"sfinv", "creative",
	"VoxelArea", "ItemStack",
	"Settings",
	"prometheus", "hb",
	"awards",


	-- Testing
	"describe",
	"it",
	"assert",
}
