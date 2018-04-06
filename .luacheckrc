unused_args = false
allow_defined_top = true

exclude_files = {
	"mods/default",
	"mods/ctf_pvp_engine",
	"mods/shooter",
	"mods/wield3d",
	"mods/treasurer",
}


globals = {
	"crafting", "vector", "table", "minetest",
	"worldedit", "ctf", "ctf_flag", "ctf_colors",
	"hudkit", "default", "treasurer", "ChatCmdBuilder",
}

read_globals = {
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},

	"dump", "DIR_DELIM",
	"sfinv", "creative",
	"irc",
	"VoxelArea", "ItemStack",
	"Settings",
	"prometheus", "hb",


	-- Testing
	"describe",
	"it",
	"assert",
}
