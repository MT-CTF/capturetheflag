-- The flag
minetest.register_node("ctf_flag:flag", {
	description = "Flag",
	drawtype="nodebox",
	paramtype = "light",
	walkable = false,
	inventory_image = "flag_silver2.png",
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500}
		}
	},
	groups = {immortal=1,is_flag=1,flag_bottom=1},
	on_punch = ctf_flag.on_punch,
	on_rightclick = ctf_flag.on_rightclick,
	on_construct = ctf_flag.on_construct,
	after_place_node = ctf_flag.after_place_node,
	on_timer = ctf_flag.flag_tick
})

for color, _ in pairs(ctf.flag_colors) do
	minetest.register_node("ctf_flag:flag_top_"..color,{
		description = "You are not meant to have this! - flag top",
		drawtype="nodebox",
		paramtype = "light",
		walkable = false,
		tiles = {
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"flag_"..color.."2.png",
			"flag_"..color..".png"
		},
		node_box = {
			type = "fixed",
			fixed = {
				{0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500},
				{-0.5,0,0.000000,0.250000,0.500000,0.062500}
			}
		},
		groups = {immortal=1,is_flag=1,flag_top=1,not_in_creative_inventory=1},
		on_punch = ctf_flag.on_punch_top,
		on_rightclick = ctf_flag.on_rightclick_top
	})
end

minetest.register_node("ctf_flag:flag_captured_top",{
	description = "You are not meant to have this! - flag captured",
	drawtype = "nodebox",
	paramtype = "light",
	walkable = false,
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500}
		}
	},
	groups = {immortal=1,is_flag=1,flag_top=1,not_in_creative_inventory=1},
	on_punch = ctf_flag.on_punch_top,
	on_rightclick = ctf_flag.on_rightclick_top
})

if ctf.setting("flag.crafting") then
	minetest.register_craft({
	output = "ctf_flag:flag",
	recipe = {
		{"default:stick", "group:wool"},
		{"default:stick", "",},
		{"default:stick", ""}
	}
})
end
