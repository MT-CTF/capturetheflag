ctf_gui.init()
local cooldowns = ctf_core.init_cooldowns()
local CLASS_SWITCH_COOLDOWN = 30

local readable_class_list = {"Knight", "Ranged", "Support"}
local class_list = {"knight", "ranged", "support"}
local classes = {
	knight = {
		name = "Knight",
		description = "High HP class with a sword capable of strong damage bursts",
		hp_max = 28,
		visual_size = vector.new(1.1, 1.1, 1.1),
		items = {
			"ctf_mode_classes:knight_sword",
		}
	},
	support = {
		name = "Support",
		description = "Normal HP class with healing bandages, an immunity ability, and building tools",
		items = {
			"ctf_mode_classes:support_bandage",
			"ctf_mode_classes:support_paxel",
			"default:cobble 99",
		}
	},
	ranged = {
		name = "Ranged",
		description = "Low HP ranged class with a rifle/grenade launcher gun, and a scaling ladder for reaching high places",
		hp_max = 10,
		physics = {speed = 1.1},
		visual_size = vector.new(0.95, 0.95, 0.95),
		items = {
			"ctf_mode_classes:ranged_rifle_loaded",
			"ctf_mode_classes:scaling_ladder"
		}
	}
}

local function dist_from_flag(player)
	local tname = ctf_teams.get(player)

	if not tname then return 0 end

	return vector.distance(ctf_map.current_map.teams[tname].flag_pos, player:get_pos())
end

--
--- Knight Sword
--

local KNIGHT_COOLDOWN_TIME = 42
local KNIGHT_USAGE_TIME = 12

ctf_melee.simple_register_sword("ctf_mode_classes:knight_sword", {
	description = "Knight Sword\nRightclick to use Rage ability (Lasts "..
			KNIGHT_USAGE_TIME.."s, "..KNIGHT_COOLDOWN_TIME.."s cooldown)",
	inventory_image = "default_tool_bronzesword.png",
	damage_groups = {fleshy = 7},
	full_punch_interval = 0.7,
	rightclick_func = function(itemstack, user, pointed)
		local pname = user:get_player_name()
		local pointed_nodedef = {}

		if pointed and pointed.type == "node" then
			pointed_nodedef = minetest.registered_nodes[minetest.get_node(pointed.under).name]
		end

		if (not pointed or not pointed_nodedef.on_rightclick) and itemstack:get_wear() == 0 then
			user:set_wielded_item("ctf_melee:sword_diamond")

			local step = math.floor(65534 / KNIGHT_USAGE_TIME)
			ctf_modebase.update_wear.start_update(pname, "ctf_melee:sword_diamond", step, false, function()
				local player = minetest.get_player_by_name(pname)

				if player then
					local pinv = player:get_inventory()
					local pos = ctf_modebase.update_wear.find_item(pinv, "ctf_melee:sword_diamond")

					if pos then
						local newstack = ItemStack("ctf_mode_classes:knight_sword")
						newstack:set_wear(65534)
						player:get_inventory():set_stack("main", pos, newstack)

						local dstep = math.floor(65534 / KNIGHT_COOLDOWN_TIME)
						ctf_modebase.update_wear.start_update(pname, "ctf_mode_classes:knight_sword", dstep, true)
					end
				end
			end)
		end

		minetest.item_place(itemstack, user, pointed)
	end,
})

--
--- Ranged Gun
--

local RANGED_COOLDOWN_TIME = 36

ctf_ranged.simple_register_gun("ctf_mode_classes:ranged_rifle", {
	type = "rifle",
	description = "Rifle\nRightclick to launch grenade ("..RANGED_COOLDOWN_TIME.."s cooldown)",
	texture = "ctf_mode_classes_ranged_rifle.png",
	fire_sound = "ctf_ranged_rifle",
	rounds = 0,
	range = 150,
	damage = 5,
	fire_interval = 0.8,
	liquid_travel_dist = 4,
	rightclick_func = function(itemstack, user, pointed)
		local pointed_nodedef = {}

		if pointed and pointed.type == "node" then
			pointed_nodedef = minetest.registered_nodes[minetest.get_node(pointed.under).name]
		end

		if (not pointed or not pointed_nodedef.on_rightclick) and itemstack:get_wear() == 0 then
			grenades.throw_grenade("grenades:frag", 24, user)
			itemstack:set_wear(65534)
			user:set_wielded_item(itemstack)

			local step = math.floor(65534 / RANGED_COOLDOWN_TIME)
			ctf_modebase.update_wear.start_update(user:get_player_name(), "ctf_mode_classes:ranged_rifle_loaded", step, true)
		end

		minetest.item_place(itemstack, user, pointed)
	end
})

--
--- Scaling Ladder
--

local SCALING_TIMEOUT = 4

-- Code borrowed from minetest_game default/nodes.lua -> default:ladder_steel
local scaling_def = {
	description = "Scaling Ladder (Infinite, self-removes after "..SCALING_TIMEOUT.."s)",
	tiles = {"default_ladder_steel.png"},
	drawtype = "signlike",
	inventory_image = "default_ladder_steel.png",
	wield_image = "default_ladder_steel.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	is_ground_content = false,
	groups = {},
	selection_box = {
		type = "wallmounted",
	},
	sounds = default.node_sound_metal_defaults(),
	on_place = function(itemstack, placer, pointed_thing, ...)
		if pointed_thing.type == "node" then
			itemstack:set_count(2)
			minetest.item_place(itemstack, placer, pointed_thing, ...)
		end
	end,
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(SCALING_TIMEOUT)
	end,
	on_timer = function(pos)
		minetest.remove_node(pos)
	end,
}

minetest.register_node("ctf_mode_classes:scaling_ladder", scaling_def)

--
--- Medic Paxel
--

minetest.register_tool("ctf_mode_classes:support_paxel", {
	description = "Paxel",
	inventory_image = "default_tool_bronzepick.png^default_tool_bronzeshovel.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=0, maxlevel=2},
			crumbly = {times={[1]=1.50, [2]=0.90, [3]=0.40}, uses=0, maxlevel=2},
			choppy={times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=0, maxlevel=2},
		},
		damage_groups = {fleshy=4},
		punch_attack_uses = 0,
	},
	groups = {pickaxe = 1, tier = 3},
	sound = {breaks = "default_tool_breaks"},
})

--
--- Medic Bandage
--

local IMMUNITY_TIME = 6
local IMMUNITY_COOLDOWN = 46
local HEAL_PERCENT = 0.8

ctf_healing.register_bandage("ctf_mode_classes:support_bandage", {
	description = string.format(
		"Bandage\nHeals teammates for 4-5 HP until target's HP is equal to %d%% of their maximum HP\n" ..
		"Rightclick to become immune to damage for %ds (%ds cooldown)",
		HEAL_PERCENT * 100,
		IMMUNITY_TIME, IMMUNITY_COOLDOWN
	),
	inventory_image = "ctf_healing_bandage.png",
	heal_percent = HEAL_PERCENT,
	heal_min = 4,
	heal_max = 5,
	rightclick_func = function(itemstack, user, pointed)
		local pointed_nodedef = {}
		local pname = user:get_player_name()

		if pointed and pointed.type == "node" then
			pointed_nodedef = minetest.registered_nodes[minetest.get_node(pointed.under).name]
		end

		if (not pointed or not pointed_nodedef.on_rightclick) and itemstack:get_wear() == 0 then
			local old_textures = user:get_properties().textures

			user:set_properties({pointable = false, textures = {old_textures[1].."^[brighten^[multiply:#7ba5ff"}})

			itemstack:set_wear(1)
			user:set_wielded_item(itemstack)

			local step = math.floor(65534 / IMMUNITY_TIME)
			ctf_modebase.update_wear.start_update(pname, "ctf_mode_classes:support_bandage", step, false, function()
				local player = minetest.get_player_by_name(pname)

				if player then
					player:set_properties({pointable = true, textures = old_textures})

					local dstep = math.floor(65534 / IMMUNITY_COOLDOWN)
					ctf_modebase.update_wear.start_update(pname, "ctf_mode_classes:support_bandage", dstep, true)
				end
			end)
		end

		minetest.item_place(itemstack, user, pointed)
	end
})

return {
	finish = function()
		for _, player in pairs(minetest.get_connected_players()) do
			player:set_properties({hp_max = minetest.PLAYER_MAX_HP_DEFAULT, visual_size = vector.new(1, 1, 1)})
			physics.remove(player:get_player_name(), "ctf_mode_classes:class_physics")
		end
	end,
	set = function(player, classname)
		local meta = player:get_meta()
		local pteam = ctf_teams.get(player)
		local oldclassname = meta:get_string("class")

		if classname == oldclassname then
			return
		end

		if not classname then
			classname = oldclassname
		end

		if not classes[classname] then
			classname = "knight"
		end

		meta:set_string("class", classname)

		ctf_modebase.update_wear.cancel_player_updates(player)

		player:set_properties({
			textures = {ctf_cosmetics.get_colored_skin(player, pteam and ctf_teams.team[pteam].color or "white")},
			hp_max = classes[classname].hp_max or minetest.PLAYER_MAX_HP_DEFAULT,
			visual_size = classes[classname].visual_size or vector.new(1, 1, 1)
		})

		player:set_hp(classes[classname].hp_max or minetest.PLAYER_MAX_HP_DEFAULT)

		if classes[classname].physics then
			physics.set(player:get_player_name(), "ctf_mode_classes:class_physics", {
				speed   = classes[classname].physics.speed or 1,
				jump    = classes[classname].physics.jump or 1,
				gravity = classes[classname].physics.gravity or 1,
			})
		else
			physics.remove(player:get_player_name(), "ctf_mode_classes:class_physics")
		end

		dropondie.drop_all(player)
		give_initial_stuff(player)
	end,
	get = function(player)
		local cname = player:get_meta():get_string("class")

		return cname and (classes[cname] or {}) or false
	end,
	get_name = function(player)
		return player:get_meta():get_string("class") or false
	end,
	select_class = function(self, player, classname)
		player = PlayerObj(player)
		if not player then return end

		if dist_from_flag(player) <= 5 then
			cooldowns:set(player, CLASS_SWITCH_COOLDOWN)
			self.set(player, classname)
		end
	end,
	show_class_formspec = function(self, player, selected)
		player = PlayerObj(player)
		if not player then return end

		if not selected then
			local name = self.get_name(player)
			if name then
				selected = table.indexof(class_list, name)
			end
		end

		selected = selected or 1

		if not cooldowns:get(player) then
			if dist_from_flag(player) > 5 then
				minetest.chat_send_player(player:get_player_name(), "You can only change class at your flag!")
				return
			end

			local elements = {}

			elements.class_select = {
				type = "dropdown",
				items = readable_class_list,
				default_idx = selected,
				pos = {x = 0, y = 0.5},
				func = function(playername, fields, field_name)
					local new_idx = table.indexof(readable_class_list, fields[field_name])

					if new_idx ~= selected then
						self:show_class_formspec(playername, new_idx)
					end
				end,
			}

			elements.select_class = {
				type = "button",
				exit = true,
				label = "Choose Class",
				pos = {x = ctf_gui.ELEM_SIZE.x + 0.5, y = 0.5},
				func = function(playername, fields, field_name)
					self:select_class(playername, class_list[selected])
				end,
			}

			ctf_gui.show_formspec(player, "ctf_mode_classes:class_form", {
				size = {x = (ctf_gui.ELEM_SIZE.x * 2) + 1, y = 3.5},
				title = classes[class_list[selected]].name,
				description = classes[class_list[selected]].description,
				privs = {interact = true},
				elements = elements,
			})
		else
			minetest.chat_send_player(
				player:get_player_name(),
				"You can only change your class every "..CLASS_SWITCH_COOLDOWN.." seconds"
			)
		end
	end,
}
