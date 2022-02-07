ctf_gui.init()
local cooldowns = ctf_core.init_cooldowns()
local CLASS_SWITCH_COOLDOWN = 30

local classes = {}

local class_list = {"knight", "ranged", "support"}
local class_props = {
	knight = {
		name = "Knight",
		description = "High HP class with a sword capable of damage bursts",
		hp_max = 30,
		visual_size = vector.new(1.1, 1.05, 1.1),
		items = {
			"ctf_mode_classes:knight_sword",
		},
		disallowed_items = {
			"ctf_ranged:rifle",
			"ctf_ranged:smg",
		},
	},
	support = {
		name = "Support",
		description = "Helper class with healing bandages, an immunity ability, and building gear",
		physics = {speed = 1.1},
		items = {
			"ctf_mode_classes:support_bandage",
			"ctf_mode_classes:support_paxel",
			"default:cobble 99",
		},
		disallowed_items = {
			"ctf_ranged:rifle",
			"ctf_ranged:smg",
			"ctf_ranged:shotgun",
			"ctf_melee:",
		},
		disallowed_items_markup = {
			["ctf_melee:"] = "default_tool_steelsword.png^ctf_modebase_group.png",
		},
	},
	ranged = {
		name = "Scout",
		description = "Ranged class with a close-range knockback attack and a scaling ladder for reaching high places",
		visual_size = vector.new(0.9, 1, 0.9),
		items = {
			"ctf_mode_classes:ranged_rifle_loaded",
			"ctf_mode_classes:scaling_ladder"
		},
		disallowed_items = {
			"ctf_melee:",
		},
		disallowed_items_markup = {
			["ctf_melee:"] = "default_tool_steelsword.png^ctf_modebase_group.png",
		},
	}
}

minetest.register_on_mods_loaded(function()
	for k, class_prop in pairs(class_props) do
		local items_markup = ""
		local disallowed_items_markup = ""

		for _, iname in ipairs(class_prop.items or {}) do
			local item = ItemStack(iname)
			local count = item:get_count()

			if count <= 1 then
				count = nil
			else
				count = " x"..count
			end

			local desc = string.split(item:get_description(), "\n", false, 1)
			items_markup = string.format("%s%s\n<item name=%s float=left width=48>\n\n\n",
				items_markup,
				minetest.formspec_escape(desc[1]) .. (count and count or ""),
				item:get_name()
			)
		end

		for _, iname in ipairs(class_prop.disallowed_items or {}) do
			if minetest.registered_items[iname] then
				disallowed_items_markup = string.format("%s<item name=%s width=48>",
					disallowed_items_markup,
					iname
				)
			else
				disallowed_items_markup = string.format("%s<img name=%s width=48>",
					disallowed_items_markup,
					class_prop.disallowed_items_markup[iname]
				)
			end
		end

		class_props[k].items_markup = items_markup:sub(1, -2) -- Remove \n at the end of str
		class_props[k].disallowed_items_markup = disallowed_items_markup
	end
end)

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
	description = "Knight Sword\n" .. minetest.colorize("gold",
			"(Sneak/Run) + Rightclick to use Rage ability (Lasts "..
			KNIGHT_USAGE_TIME.."s, "..KNIGHT_COOLDOWN_TIME.."s cooldown)"),
	inventory_image = "default_tool_bronzesword.png",
	inventory_overlay = "ctf_modebase_special_item.png",
	wield_image = "default_tool_bronzesword.png",
	damage_groups = {fleshy = 7},
	full_punch_interval = 0.7,
	rightclick_func = function(itemstack, user, pointed)
		local ctl = user:get_player_control()
		if not ctl.sneak and not ctl.aux1 then return end

		local pname = user:get_player_name()

		if itemstack:get_wear() == 0 then
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
			end,
			function()
				local player = minetest.get_player_by_name(pname)

				if player then
					player:get_inventory():remove_item("main", "ctf_melee:sword_diamond")
				end
			end)

			return "ctf_melee:sword_diamond"
		end
	end,
})

--
--- Ranged Gun
--

local RANGED_COOLDOWN_TIME = 18

ctf_ranged.simple_register_gun("ctf_mode_classes:ranged_rifle", {
	type = "classes_rifle",
	description = "Scout Rifle\n" .. minetest.colorize("gold",
			"Rightclick enemy to bayonet stab (deals damage and knockback) ("..RANGED_COOLDOWN_TIME.."s cooldown)"),
	texture = "ctf_mode_classes_ranged_rifle.png",
	texture_overlay = "ctf_modebase_special_item.png^[transformFX",
	wield_texture = "ctf_mode_classes_ranged_rifle.png",
	fire_sound = "ctf_ranged_rifle",
	rounds = 0,
	range = 150,
	damage = 5,
	fire_interval = 0.8,
	liquid_travel_dist = 4,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if not pointed_thing or pointed_thing.type ~= "object" then
			return
		end

		local enemy = pointed_thing.ref

		if itemstack:get_wear() == 0 and enemy and enemy:is_player() then
			local p1, p2 = user:get_pos(), enemy:get_pos()

			if vector.distance(p1, p2) > 4.4 then -- The player hitboxes extend reach a bit
				minetest.log("[classes]: Cancelling bayonet hit for "..dump(user:get_player_name()))
				return
			end

			local dir = vector.direction(p1, p2)

			dir.y = 0.5

			enemy:punch(user, 1, {damage_groups = {fleshy = 6}}, dir)
			enemy:add_velocity(dir * 13)

			local step = math.floor(65534 / RANGED_COOLDOWN_TIME)
			ctf_modebase.update_wear.start_update(user:get_player_name(), "ctf_mode_classes:ranged_rifle_loaded", step, true)

			itemstack:set_wear(65534)
			return itemstack
		end
	end
})

--
--- Scaling Ladder
--

local SCALING_TIMEOUT = 4

-- Code borrowed from minetest_game default/nodes.lua -> default:ladder_steel
local scaling_def = {
	description = "Scaling Ladder\n"..
			minetest.colorize("gold", "(Infinite usage, self-removes after "..SCALING_TIMEOUT.."s)"),
	tiles = {"default_ladder_steel.png"},
	drawtype = "signlike",
	inventory_image = "default_ladder_steel.png",
	inventory_overlay = "ctf_modebase_special_item.png",
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
	groups = {pickaxe = 1, tier = 10},
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
		minetest.colorize("gold", "(Sneak/Run) + Rightclick to become immune to damage for %ds (%ds cooldown)"),
		HEAL_PERCENT * 100,
		IMMUNITY_TIME, IMMUNITY_COOLDOWN
	),
	inventory_image = "ctf_healing_bandage.png",
	inventory_overlay = "ctf_modebase_special_item.png",
	wield_image = "ctf_healing_bandage.png",
	heal_percent = HEAL_PERCENT,
	heal_min = 4,
	heal_max = 5,
	rightclick_func = function(itemstack, user, pointed)
		local ctl = user:get_player_control()
		if not ctl.sneak and not ctl.aux1 then return end

		local pname = user:get_player_name()

		if itemstack:get_wear() == 0 then
			if ctf_modebase.taken_flags[pname] then
				hud_events.new(user, {
					quick = true,
					text = "You can't become immune while holding the flag",
					color = "warning",
				})
				return
			end

			ctf_modebase.give_immunity(user)

			local step = math.floor(65534 / IMMUNITY_TIME)
			ctf_modebase.update_wear.start_update(pname, "ctf_mode_classes:support_bandage", step, false,
			function()
				ctf_modebase.remove_immunity(user)
				local dstep = math.floor(65534 / IMMUNITY_COOLDOWN)
				ctf_modebase.update_wear.start_update(pname, "ctf_mode_classes:support_bandage", dstep, true)
			end,
			function()
				ctf_modebase.remove_immunity(user)
			end)

			itemstack:set_wear(1)
			return itemstack
		end
	end
})

function classes.get_name(player)
	local meta = player:get_meta()

	local cname = meta:get_string("class")
	if not cname or not class_props[cname] then
		cname = "knight"
		meta:set_string("class", cname)
	end

	return cname
end

function classes.get(player)
	return class_props[classes.get_name(player)]
end

function classes.get_skin_overlay(player_or_class, class)
	if not class then
		return "^ctf_mode_classes_" .. classes.get_name(player_or_class) .. "_overlay.png"
	else
		return "^ctf_mode_classes_" .. player_or_class .. "_overlay.png"
	end
end

function classes.update(player)
	local class = classes.get(player)

	player:set_properties({
		hp_max = class.hp_max or minetest.PLAYER_MAX_HP_DEFAULT,
		visual_size = class.visual_size or vector.new(1, 1, 1)
	})

	if class.physics then
		physics.set(player:get_player_name(), "ctf_mode_classes:class_physics", {
			speed   = class.physics.speed or 1,
			jump    = class.physics.jump or 1,
			gravity = class.physics.gravity or 1,
		})
	else
		physics.remove(player:get_player_name(), "ctf_mode_classes:class_physics")
	end
end

function classes.set(player, classname)
	if classname == classes.get_name(player) then
		return
	end

	player:get_meta():set_string("class", classname)

	ctf_modebase.update_wear.cancel_player_updates(player)

	ctf_modebase.player.remove_bound_items(player)
	ctf_modebase.player.give_initial_stuff(player)

	player:set_properties({textures = {ctf_cosmetics.get_skin(player)}})

	classes.update(player)

	player:set_hp(player:get_properties().hp_max)
end

local function select_class(player, classname)
	player = PlayerObj(player)
	if not player then return end

	if dist_from_flag(player) <= 5 then
		cooldowns:set(player, CLASS_SWITCH_COOLDOWN)
		classes.set(player, classname)
	end
end

function classes.show_class_formspec(player)
	player = PlayerObj(player)
	if not player then return end

	if not cooldowns:get(player) then
		if dist_from_flag(player) > 5 then
			hud_events.new(player, {
				quick = true,
				text = "You can only change class at your flag!",
				color = "warning",
			})
			return
		end

		local pteam = ctf_teams.get(player)

		ctf_gui.show_formspec(player, "ctf_mode_classes:class_form", function(context)
			local form_x, form_y = 12, 10

			local bar_h = 2.2
			local bw = 5

			local class = context.class
			local class_prop = class_props[class]

			return (table.concat({
				"formspec_version[4]",
				("size[%f,%f]"):format(form_x, form_y+1.1),
				"real_coordinates[true]",
				"hypertext[0,0.2;"..form_x..",1.3;title;<bigger><center><b>Class Selection</b></center></bigger>]",

				("hypertext[0,%f;%f,1;classname;<bigger><center><style color=#0DD>%s</style></center></bigger>]"):format(
					bar_h-0.9,
					form_x,
					class_prop.name
				),
				("box[0,%f;%f,0.8;#00000022]"):format(bar_h-0.9, form_x),
				"image_button[0.1,"..(bar_h-0.9)..";0.8,0.8;creative_prev_icon.png;prev_class;]",
				("image_button[%f,%f;0.8,0.8;creative_next_icon.png;next_class;]"):format(form_x-0.9, bar_h-0.9),

				("box[0.1,2.3;%f,%f;#00000077]"):format((form_x/2)-0.8, form_y-2.4),
				("model[0.1,2.3;%f,%f;classpreview;character.b3d;%s;{0,160};;;]"):format(
					(form_x/2)-0.8,
					form_y-2.4,
					ctf_cosmetics.get_colored_skin(player, pteam and ctf_teams.team[pteam].color) ..
							classes.get_skin_overlay(class, true)
				),
				([[hypertext[%f,2.3;%f,%f;info;<global font=mono background=#00000044>
					<center>%s</center>
					<img name=heart.png width=20 float=left> %d HP
					%s
					%s
					Disallowed Items
					%s
				]].."]"):format(
					(form_x/2)-0.6,
					(form_x/2)+0.5,
					form_y-2.4,
					class_prop.description,
					class_prop.hp_max or minetest.PLAYER_MAX_HP_DEFAULT,
					class_prop.physics and class_prop.physics.speed and
							"<img name=sprint_stamina_icon.png width=20 float=left> "..class_prop.physics.speed.."x Speed\n" or "",
					class_prop.items_markup,
					class_prop.disallowed_items_markup
				),
				"style[select;font_size=*1.5]",
				"button_exit["..((form_x/2) - (bw/2))..","..(form_y)..";"..bw..",1;select;Choose Class]",
			}, "\n"))
		end, {
			class = classes.get_name(player) or "knight",
			elements = {
				prev_class = function(pname, fields, context)
					local classidx = table.indexof(class_list, context.class) - 1

					if classidx < 1 then
						classidx = #class_list
					end

					context.class = class_list[classidx]

					return "refresh", context
				end,
				next_class = function(pname, fields, context)
					local classidx = table.indexof(class_list, context.class) + 1

					if classidx > #class_list then
						classidx = 1
					end

					context.class = class_list[classidx]

					return "refresh", context
				end,
				select = function(pname, fields, context)
					if dist_from_flag(player) > 5 then
						hud_events.new(player, {
							quick = true,
							text = "You can only change class at your flag!",
							color = "warning",
						})
						return
					end

					select_class(pname, context.class)
				end
			}
		})
	else
		hud_events.new(player, {
			quick = true,
			text = "You can only change your class every "..CLASS_SWITCH_COOLDOWN.." seconds",
			color = "warning",
		})
	end
end

function classes.is_restricted_item(player, name)
	for _, disallowed in pairs(classes.get(player).disallowed_items) do
		if name:match(disallowed) then
			hud_events.new(player, {
				quick = true,
				text = "Your class can't use that item!",
				color = "warning",
			})
			return true
		end
	end
end

function classes.finish()
	for _, player in pairs(minetest.get_connected_players()) do
		player:set_properties({hp_max = minetest.PLAYER_MAX_HP_DEFAULT, visual_size = vector.new(1, 1, 1)})
		physics.remove(player:get_player_name(), "ctf_mode_classes:class_physics")
	end
end

return classes
