unused_args = false
allow_defined_top = true

globals = {
	"minetest", "awards",
}

read_globals = {
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},
	"vector", "default", "ItemStack",
	"dump", "sfinv", "intllib",
	"unified_inventory",
}
