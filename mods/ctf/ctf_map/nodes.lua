-- Backwards compat

minetest.register_alias("ctf_map:ind_stone", "ctf_map:stone")

-- Special nodes
minetest.register_node("ctf_map:ignore", {
	description = "Artificial Ignore", -- this may need to be given a more appropriate name
	drawtype = "airlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable     = true,
	pointable    = false,
	diggable     = false,
	buildable_to = false,
	air_equivalent = true,

	groups = {immortal = 1, disable_suffocation = 1},
})

minetest.register_node("ctf_map:ind_glass", {
	description = "Indestructible Barrier Glass",
	drawtype = "glasslike_framed",
	tiles = {"default_glass.png", "default_glass_detail.png"},
	inventory_image = minetest.inventorycube("default_glass.png"),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	buildable_to = false,
	pointable = ctf_core.settings.server_mode == "mapedit",
	groups = {immortal = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_glass_defaults()
})

minetest.register_node("ctf_map:ind_glass_red", {
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
	pointable = ctf_core.settings.server_mode == "mapedit",
	groups = {immortal = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_glass_defaults()
})
ctf_map.barrier_nodes[minetest.get_content_id("ctf_map:ind_glass_red")] = minetest.CONTENT_AIR

minetest.register_node("ctf_map:ind_stone_red", {
	description = "Indestructible Red Barrier Stone",
	groups = {immortal = 1, not_in_creative_inventory = 1},
	tiles = {"ctf_map_stone_red.png"},
	is_ground_content = false
})
ctf_map.barrier_nodes[minetest.get_content_id("ctf_map:ind_stone_red")] = minetest.get_content_id("default:stone")

minetest.register_node("ctf_map:killnode", {
	description = "Kill Node",
	drawtype = "glasslike",
	tiles = {"ctf_map_killnode.png"},
	paramtype = "light",
	sunlight_propogates = true,
	walkable = false,
	pointable = ctf_core.settings.server_mode == "mapedit",
	damage_per_second = 20,
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults(),
})

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

local queue = {}
for name, def in pairs(minetest.registered_nodes) do
	if name:find("stair_junglewood") then
		minetest.log(dump(name))
	end
	local mod, nodename = name:match"(..-):(.+)"
	local prefix = mod_prefixes[mod]
	if nodename and prefix and name ~= "default:torch" and
			not (def.groups and (def.groups.immortal or def.groups.not_in_creative_inventory)) then
		local new_name = "ctf_map:" .. prefix .. nodename -- HACK to preserve backwards compatibility
		local new_def = table.copy(def)
		if def.drop == name then
			new_def.drop = new_name
		end
		make_immortal(new_def)
		table.insert(queue, {name = new_name, def = new_def})
	end
end

for _, node in pairs(queue) do
	minetest.register_node(node.name, node.def)
end

minetest.register_alias("ctf_map:torch", "default:torch")
minetest.register_alias("ctf_map:torch_wall", "default:torch_wall")
minetest.register_alias("ctf_map:torch_ceiling", "default:torch_ceiling")

--
--- credit for most of code goes to tsm_chests mod used by CTF 2.0

local chest_formspec =
	"size[8,9]" ..
	"list[current_name;main;0,0.3;8,4;]" ..
	"list[current_player;main;0,4.85;8,1;]" ..
	"list[current_player;main;0,6.08;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0,4.85)

minetest.register_node("ctf_map:chest", {
	description = "Loot Chest",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
	paramtype2 = "facedir",
	groups = {immortal = 1},
	light_source = 2,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if player then
			minetest.chat_send_player(player:get_player_name(),
				"You're not allowed to put things in treasure chests!")
			return 0
		end
	end,
	on_rightclick = function(pos, node, clicker, ...)
		if not clicker:is_player() then return end

		local meta = minetest.get_meta(pos)
		local pname = clicker:get_player_name()

		if meta:get_string("treasured") == "yes" then
			return
		else
			minetest.registered_nodes[node.name].on_construct(pos)
			ctf_map.treasurefy_node(pos, node, clicker, ...)
			meta:set_string("treasured", "yes")
		end

		local special_form = chest_formspec
		special_form = special_form:gsub("current_player", "player:"..pname)
		special_form = special_form:gsub("current_name", string.format("nodemeta:%d,%d,%d", pos.x, pos.y, pos.z))

		minetest.after(0, function() minetest.show_formspec(pname, "ctf_map:chest_formspec", special_form) end)
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", chest_formspec)
		meta:set_string("infotext", "Loot Chest")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
		minetest.log("action", player:get_player_name() ..
			" moves stuff in chest at " .. minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() ..
			" moves stuff to chest at " .. minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local inv = minetest.get_inventory({type = "node", pos = pos})
		local swapped_item = inv:get_stack(listname, index)

		if swapped_item:get_name() ~= "" then
			inv:remove_item(listname, swapped_item)
			player:get_inventory():add_item("main", swapped_item)
		end

		minetest.log("action", player:get_player_name() ..
			" takes stuff from chest at " .. minetest.pos_to_string(pos))

		if not inv or inv:is_empty("main") then
			minetest.set_node(pos, {name="air"})
			minetest.show_formspec(player:get_player_name(), "", player:get_inventory_formspec())
		end
	end,
})
