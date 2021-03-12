-- Special nodes
do
	minetest.register_node(":ctf_map:ignore", {
		description = "Artificial Ignore", -- this may need to be given a more appropriate name
		drawtype = "airlike",
		paramtype = "light",
		sunlight_propagates = true,
		walkable     = true,
		pointable    = false,
		diggable     = false,
		buildable_to = false,
		air_equivalent = true,

		groups = {immortal = 1},
	})

	minetest.register_node(":ctf_map:ind_glass", {
		description = "Indestructible Barrier Glass",
		drawtype = "glasslike_framed_optional",
		tiles = {"default_glass.png", "default_glass_detail.png"},
		inventory_image = minetest.inventorycube("default_glass.png"),
		paramtype = "light",
		sunlight_propagates = true,
		is_ground_content = false,
		walkable = true,
		buildable_to = false,
		pointable = false,
		groups = {immortal = 1, not_in_creative_inventory = 1},
		sounds = default.node_sound_glass_defaults()
	})

	minetest.register_node(":ctf_map:ind_glass_red", {
		description = "Indestructible Red Barrier Glass",
		drawtype = "glasslike",
		tiles = {"ctf_map_glass_red.png"},
		inventory_image = minetest.inventorycube("ctf_map_glass_red.png"),
		paramtype = "light",
		sunlight_propagates = true,
		is_ground_content = false,
		walkable = true,
		buildable_to = false,
		use_texture_alpha = false,
		alpha = 0,
		pointable = false,
		groups = {immortal = 1, not_in_creative_inventory = 1},
		sounds = default.node_sound_glass_defaults()
	})

	minetest.register_node(":ctf_map:ind_stone_red", {
		description = "Indestructible Red Barrier Stone",
		groups = {immortal = 1, not_in_creative_inventory = 1},
		tiles = {"ctf_map_stone_red.png"},
		is_ground_content = false
	})

	minetest.register_node(":ctf_map:killnode", {
		description = "Kill Node",
		drawtype = "glasslike",
		tiles = {"ctf_map_killnode.png"},
		paramtype = "light",
		sunlight_propogates = true,
		walkable = false,
		pointable = false,
		damage_per_second = 20,
		is_ground_content = false,
		groups = {immortal = 1},
		sounds = default.node_sound_glass_defaults(),
	})

	minetest.register_node(":ctf_map:reinforced_cobble", {
		description = "Reinforced Cobblestone",
		tiles = {"ctf_map_reinforced_cobble.png"},
		is_ground_content = false,
		groups = {cracky = 1, stone = 2},
		sounds = default.node_sound_stone_defaults(),
	})
end

local mod_prefixes = {
	default = "";
	stairs = "";
	wool = "wool_";
}

-- See Lua API, section "Node-only groups"
local preserved_groups = {
	bouncy = true;
	connect_to_raillike = true;
	disable_jump = true;
	fall_damage_add_percent = true;
	slippery = true;
}

local function make_immortal(def)
	local groups = {immortal = 1}
	for group in pairs(preserved_groups) do
		groups[group] = def.groups[group]
	end
	def.groups = groups
	def.floodable = false
	def.description = def.description and ("Indestructible " .. def.description)
end

for name, def in pairs(minetest.registered_nodes) do
	local mod, nodename = name:match"(..-):(.+)"
	local prefix = mod_prefixes[mod]
	if nodename and prefix and name ~= "default:torch" and not (def.groups and (def.groups.immortal or def.groups.not_in_creative_inventory)) then
		-- HACK to preserve backwards compatibility
		local new_name = ":ctf_map:" .. prefix .. nodename
		local new_def = table.copy(def)
		if def.drop == name then
			new_def.drop = new_name
		end
		make_immortal(new_def)
		minetest.register_node(new_name, new_def)
	end
end

local torch_defs = table.copy(default.torch)
make_immortal(torch_defs.floor)
torch_defs.floor.drop = "ctf_map:torch"
default.register_torch("ctf_map:torch", torch_defs)
