-- Backwards compat

local S = core.get_translator(core.get_current_modname())

core.register_alias("ctf_map:ind_stone", "ctf_map:stone")

-- Special nodes
core.register_node("ctf_map:ignore", {
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

core.register_node("ctf_map:ind_glass", {
	description = S("Indestructible Barrier Glass"),
	drawtype = "glasslike_framed",
	tiles = {"default_glass.png", "default_glass_detail.png"},
	inventory_image = core.inventorycube("default_glass.png"),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	buildable_to = false,
	pointable = ctf_core.settings.server_mode == "mapedit",
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults()
})

core.register_node("ctf_map:ind_glass_red", {
	description = S("Indestructible Red Barrier Glass"),
	drawtype = "glasslike",
	tiles = {"ctf_map_glass_red.png"},
	inventory_image = core.inventorycube("ctf_map_glass_red.png"),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	buildable_to = false,
	use_texture_alpha = false,
	alpha = 0,
	pointable = ctf_core.settings.server_mode == "mapedit",
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults()
})
ctf_map.barrier_nodes[core.get_content_id("ctf_map:ind_glass_red")] = core.CONTENT_AIR

core.register_node("ctf_map:ind_water", {
	description = S("Indestructible Water Barrier Glass"),
	drawtype = "glasslike",
	tiles = {"ctf_map_ind_water.png"},
	inventory_image = core.inventorycube("ctf_map_ind_water.png"),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	buildable_to = false,
	use_texture_alpha = false,
	alpha = 0,
	pointable = ctf_core.settings.server_mode == "mapedit",
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults()
})
ctf_map.barrier_nodes[core.get_content_id("ctf_map:ind_water")] = core.get_content_id("default:water_source")

core.register_node("ctf_map:ind_river_water", {
	description = S("Indestructible River Water Barrier Glass"),
	drawtype = "glasslike",
	tiles = {"ctf_map_ind_river_water.png"},
	inventory_image = core.inventorycube("ctf_map_ind_river_water.png"),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	buildable_to = false,
	use_texture_alpha = false,
	alpha = 0,
	pointable = ctf_core.settings.server_mode == "mapedit",
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults()
})
ctf_map.barrier_nodes[core.get_content_id("ctf_map:ind_river_water")] =
		core.get_content_id("default:river_water_source")

core.register_node("ctf_map:ind_poison_water", {
	description = S("Indestructible Poisonous Water Barrier Glass"),
	drawtype = "glasslike",
	tiles = {"ctf_map_ind_poison_water.png"},
	inventory_image = core.inventorycube("ctf_map_ind_poison_water.png"),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	buildable_to = false,
	use_texture_alpha = false,
	alpha = 0,
	pointable = ctf_core.settings.server_mode == "mapedit",
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults()
})
ctf_map.barrier_nodes[core.get_content_id("ctf_map:ind_poison_water")] =
		core.get_content_id("poison_water:poisonous_water")

core.register_node("ctf_map:ind_lava", {
	description = S("Indestructible Lava Barrier Glass"),
	groups = {immortal = 1},
	tiles = {"ctf_map_ind_lava.png"},
	is_ground_content = false
})
ctf_map.barrier_nodes[core.get_content_id("ctf_map:ind_lava")] = core.get_content_id("default:lava_source")

core.register_node("ctf_map:ind_stone_red", {
	description = S("Indestructible Red Barrier Stone"),
	groups = {immortal = 1},
	tiles = {"ctf_map_stone_red.png"},
	is_ground_content = false
})
ctf_map.barrier_nodes[core.get_content_id("ctf_map:ind_stone_red")] = core.get_content_id("default:stone")

core.register_node("ctf_map:killnode", {
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
	walls = "walls_";
}

-- See Lua API, section "Node-only groups"
local preserved_groups = {
	bouncy = true;
	fence = true;
	connect_to_raillike = true;
	wall = true;
	disable_jump = true;
	fall_damage_add_percent = true;
	slippery = true;
	tree = true;
	wood = true;
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

core.register_on_player_hpchange(function(player, hp_change, reason)
	local pos = player:get_pos()
	local def = core.registered_nodes[reason.node]

	if reason.type == 'node_damage' and def.groups.immortal and def.drawtype == "normal" and def.walkable ~= false then
		for _, flagteam in ipairs(ctf_teams.current_team_list) do
			if flagteam ~= ctf_teams.get(player) and ctf_map.current_map.teams[flagteam] then
				local fdist = vector.distance(pos, ctf_map.current_map.teams[flagteam].flag_pos)
				if fdist <= 6 then
					return hp_change
				end
			end
		end

		return 0
	end

	return hp_change
end, true)

local queue = {}
for name, def in pairs(core.registered_nodes) do
	local mod, nodename = name:match"(..-):(.+)"
	local prefix = mod_prefixes[mod]
	if nodename and prefix and name ~= "default:torch" and
			not (def.groups and (def.groups.immortal or def.groups.not_in_creative_inventory)) then
		local new_name = "ctf_map:" .. prefix .. nodename -- HACK to preserve backwards compatibility
		local new_def = table.copy(def)
		if def.drop == name then
			new_def.drop = new_name
		end
		if ctf_core.settings.server_mode ~= "mapedit" and def.drawtype == "normal" and def.walkable ~= false then
			new_def.damage_per_second = 100
		end
		make_immortal(new_def)
		table.insert(queue, {name = new_name, def = new_def})
	end
end

for _, node in pairs(queue) do
	core.register_node(node.name, node.def)
end

core.register_alias("ctf_map:torch", "default:torch")
core.register_alias("ctf_map:torch_wall", "default:torch_wall")
core.register_alias("ctf_map:torch_ceiling", "default:torch_ceiling")

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
local chestv = S("Treasure Chest (visited)")

local not_allowed_timer = {}
local chest_def = {
	description = S("Treasure Chest"),
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
	paramtype2 = "facedir",
	groups = {immortal = 1},
	light_source = 2,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("infotext", S("Treasure Chest"))
		meta:set_string("formspec", chest_formspec)

		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if player then
			local name = player:get_player_name()

			if not not_allowed_timer[name] then
				core.chat_send_player(name,
					S("You're not allowed to put things in treasure chests!"))

				not_allowed_timer[name] = true
				core.after(1, function() not_allowed_timer[name] = nil end)
			end
			return 0
		end
	end,
	can_dig = function(pos,player)
		local meta = core.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
		core.log("action", player:get_player_name() ..
			" moves stuff in chest at " .. core.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		core.log("action", string.format("%s puts %s to treasure chest at %s",
			player:get_player_name(),
			stack:to_string(),
			core.pos_to_string(pos)
		))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		core.log("action", string.format("%s takes %s from treasure chest at %s",
			player:get_player_name(),
			stack:to_string(),
			core.pos_to_string(pos)
		))

		local inv = core.get_inventory({type = "node", pos = pos})
		if not inv or inv:is_empty("main") then
			core.close_formspec(player:get_player_name(), "")
			core.after(0, function()
				core.set_node(pos, {name = "air"})
			end)
		end
		core.swap_node(pos, {name = "ctf_map:chest_opened"})
		core.get_meta(pos):set_string("infotext", chestv)
	end,
}

local ochest_def = table.copy(chest_def)
ochest_def.description = chestv
ochest_def.drawtype = "mesh"
ochest_def.tiles[5] = "default_chest_front.png"
ochest_def.tiles[6] = "default_chest_inside.png"
ochest_def.mesh = "chest_open.obj"
ochest_def.light_source = 1
ochest_def.on_rightclick = nil
ochest_def.on_metadata_inventory_take = function(pos, listname, index, stack, player)
	core.log("action", string.format("%s takes %s from treasure chest at %s",
		player:get_player_name(),
		stack:to_string(),
		core.pos_to_string(pos)
	))
	local inv = core.get_inventory({type = "node", pos = pos})
	if not inv or inv:is_empty("main") then
		core.close_formspec(player:get_player_name(), "")
		core.after(0, function()
			core.set_node(pos, {name = "air"})
		end)
	end
end

core.register_node("ctf_map:chest_opened", ochest_def)
core.register_node("ctf_map:chest", chest_def)
