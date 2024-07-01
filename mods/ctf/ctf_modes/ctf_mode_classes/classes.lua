ctf_gui.init()

local cooldowns = ctf_core.init_cooldowns()
local CLASS_SWITCH_COOLDOWN = 30

local classes = {}

local class_list = {"knight", "ranged", "support"}
local class_props = {
	knight = {
		name = "Knight",
		color = "grey",
		description = "High HP class with a sword capable of short damage bursts",
		hp_max = 30,
		visual_size = vector.new(1.1, 1.05, 1.1),
		items = {
			"ctf_mode_classes:knight_sword",
		},
		disallowed_items = {
			"ctf_ranged:rifle",
			"ctf_ranged:smg",
			"ctf_ranged:sniper_magnum",
		},
	},
	support = {
		name = "Support",
		color = "cyan",
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
			"ctf_ranged:sniper_magnum",
		},
		disallowed_items_markup = {
			["ctf_melee:"] = "default_tool_steelsword.png^ctf_modebase_group.png",
		},
	},
	ranged = {
		name = "Scout",
		color = "orange",
		description = "Ranged class with a scoped rifle/grenade launcher and a scaling ladder for reaching high places",
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


			items_markup = string.format("%s <item name=%s width=48>",
				items_markup,
				item:get_name()
			)
		end

		for _, iname in ipairs(class_prop.disallowed_items or {}) do
			if minetest.registered_items[iname] then
				disallowed_items_markup = string.format("%s <item name=%s width=48>",
					disallowed_items_markup,
					iname
				)
			else
				disallowed_items_markup = string.format("%s <img name=%s width=48>",
					disallowed_items_markup,
					class_prop.disallowed_items_markup[iname]
				)
			end
		end

		class_props[k].items_markup = items_markup.."\n"
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

-- ctf_melee.register_sword("ctf_mode_classes:knight_sword", {
-- 	description = "Knight Sword",
-- 	inventory_image = "default_tool_bronzesword.png",
-- 	damage_groups = {fleshy = 5},
-- })

local KNIGHT_COOLDOWN_TIME = 26
local KNIGHT_USAGE_TIME = 8

ctf_settings.register("ctf_mode_classes:simple_knight_activate", {
	type = "bool",
	label = "[Classes] Simple Knight sword activation",
	description = "If enabled you don't need to hold Sneak/Run to activate the rage ability",
	default = "false",
})

ctf_settings.register("ctf_mode_classes:simple_support_activate", {
	type = "bool",
	label = "[Classes] Simple Support bandage immunity activation",
	description = "If enabled you don't need to hold Sneak/Run to activate the immunity ability",
	default = "false",
})

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
		if ctf_settings.get(user, "ctf_mode_classes:simple_knight_activate") ~= "true" then
			local ctl = user:get_player_control()
			if not ctl.sneak and not ctl.aux1 then return end
		end

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

local RANGED_COOLDOWN_TIME = 31
local RANGED_ZOOM_MULT = 3

local scoped = ctf_ranged.scoped
ctf_ranged.simple_register_gun("ctf_mode_classes:ranged_rifle", {
	type = "classes_rifle",
	description = "Scout Rifle\n" .. minetest.colorize("gold",
			"(Sneak/Run) + Rightclick to launch grenade ("..RANGED_COOLDOWN_TIME.."s cooldown), otherwise will toggle scope"),
	texture = "ctf_mode_classes_ranged_rifle.png",
	texture_overlay = "ctf_modebase_special_item.png^[transformFX",
	wield_texture = "ctf_mode_classes_ranged_rifle.png",
	fire_sound = "ctf_ranged_rifle",
	rounds = 0,
	range = 150,
	damage = 5,
	fire_interval = 0.8,
	liquid_travel_dist = 4,
	rightclick_func = function(itemstack, user, pointed)
		local ctl = user:get_player_control()

		if not ctl.sneak and not ctl.aux1 then
			local uname = user:get_player_name()

			if not ctl.zoom then
				if scoped[uname] then
					ctf_ranged.hide_scope(uname)
				else
					ctf_ranged.show_scope(uname, itemstack:get_name(), RANGED_ZOOM_MULT)
				end
			end

			return
		end

		if itemstack:get_wear() == 0 then
			grenades.throw_grenade("grenades:frag", 24, user)

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
		if ctf_settings.get(user, "ctf_mode_classes:simple_support_activate") ~= "true" then
		    local ctl = user:get_player_control()
		    if not ctl.sneak and not ctl.aux1 then return end
        end

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
	return "^ctf_mode_classes_" .. (class and player_or_class or classes.get_name(player_or_class)) .. "_overlay.png"
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

	player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))

	classes.update(player)

	player:set_hp(player:get_properties().hp_max)
end

local function select_class(player, classname)
	player = PlayerObj(player)
	if not player then return end

	if classname == classes.get_name(player) then
		return
	end

	if ctf_modebase.current_mode == "classes" and dist_from_flag(player) <= 5 then
		cooldowns:set(player, CLASS_SWITCH_COOLDOWN)
		classes.set(player, classname)
	end
end

local function wrap_class(idx)
	if idx > #class_list then
		idx = 1
	elseif idx < 1 then
		idx = #class_list
	end

	return idx
end

function classes.show_class_formspec(player)
	player = PlayerObj(player)
	if not player then return end

	if ctf_modebase.current_mode ~= "classes" then return end

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
		local pad = 0.3

		local bw = 3

		local class = context.class
		local class_prop = context.class_props[class]

		local out = {
			"formspec_version[4]",
			{"size[%f,%f]", form_x, form_y+1.1},
			"real_coordinates[true]",
			{"hypertext[0,0.2;%f,1.6;title;<big><center><b>Class Info: %s</b></center></big>]", form_x, class_prop.name},

			{"box[%s,1.2;%f,%f;#00000077]", pad, ((form_x/2)-0.7) - pad, form_y-2.4},
			{"model[%s,1.4;%f,%f;classpreview;character.b3d;%s,blank.png;{0,160};;;]",
				pad,
				((form_x/2)-0.7) - pad,
				form_y-2.6,
				ctf_cosmetics.get_colored_skin(context.player, context.pteam and ctf_teams.team[context.pteam].color) ..
						context.classes.get_skin_overlay(class, true) or ""
			},
			{[[hypertext[%f,1.2;%f,%f;info;<global margin=20 font=mono background=#00000044>
				</b>
				<center>%s</center>


				<img name=heart.png width=20 float=left> %d HP
				%s
				Special items
				%s
				Disallowed Items
				%s
				] ]],
				(form_x/2)-0.6,
				(form_x/2)+0.6 - pad,
				form_y-2.4,
				class_prop.description,
				class_prop.hp_max or minetest.PLAYER_MAX_HP_DEFAULT,
				class_prop.physics and class_prop.physics.speed and
						"<img name=sprint_stamina_icon.png width=20 float=left> "..class_prop.physics.speed.."x Speed\n" or "",
				class_prop.items_markup,
				class_prop.disallowed_items_markup
			},
		}

		local tb = #context.class_list -- total buttons
		for i, c in pairs(context.class_list) do
			local sect = (i-1)/(tb-1)
			local font_color = "#ffffff"
			if cooldowns:get(player) then
				font_color = "#f23f42"
				table.insert(out,
					{"tooltip[select_%s;You can only change your class every "..CLASS_SWITCH_COOLDOWN.." seconds, ]", c}
				)
			end
			table.insert(out, {
				"style[select_%s;textcolor=".. font_color ..
				";font_size=*1.4;content_offset=-%f,0;bgcolor="..context.class_props[c].color.."]" ..
				"style[show_%s;padding=8,8;bgcolor="..context.class_props[c].color.."]",
				c,
				20 + 8,
				c,
			})
			if not cooldowns:get(player) then
				table.insert(out, {
					"button_exit[%f,%f;%f,1;select_%s;%s]",
					pad + (((form_x-(pad*2 + bw))) * sect),
					form_y-0.5,
					bw,
					c,
					context.class_props[c].name,
				})
			else
				table.insert(out, {
					"button[%f,%f;%f,1;select_%s;%s]",
					pad + (((form_x-(pad*2 + bw))) * sect),
					form_y-0.5,
					bw,
					c,
					context.class_props[c].name,
				})
			end
			table.insert(out, {
				"image_button[%f,%f;1,1;settings_info.png;show_%s;]",
				pad + (((form_x-(pad*2 + bw))) * sect) + bw - 1,
				form_y-0.5,
				c,
			})
			table.insert(out,
				{"tooltip[show_%s;Click to show class info]", c}
			)
		end
		return ctf_gui.list_to_formspec_str(out)
	end, {
		classes = classes,
		player = player,
		pteam = pteam,
		wrap_class = wrap_class,
		class_list = class_list,
		class_props = class_props,
		class = classes.get_name(player) or "knight",
		_on_formspec_input = function(pname, context, fields)
			if ctf_modebase.current_mode ~= "classes" then return end

			if cooldowns:get(player) then
				for _, class in pairs(context.class_list) do
					if fields["select_"..class] then
						context.class = class
						return "refresh"
					end
				end
			end
			for _, class in pairs(context.class_list) do
				if fields["show_"..class] then
					context.class = class
					return "refresh"
				end

				if fields["select_"..class] then
					if dist_from_flag(player) > 5 then
						hud_events.new(player, {
							quick = true,
							text = "You can only change class at your flag!",
							color = "warning",
						})

						return
					end

					select_class(pname, class)
				end
			end
		end,
	})
end

function classes.is_restricted_item(player, name)
	-- Don't check restricted items for players not in a team
	if not ctf_teams.get(player) then
		return
	end

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

function classes.reset_class_cooldowns(player)
	if not player then
		minetest.log("action", "Resetting class cooldowns for all players")

		for _, p in pairs(minetest.get_connected_players()) do
			if cooldowns:get(p) then
				cooldowns:set(p)
			end
		end
	else
		minetest.log("action", "Resetting class cooldowns for player "..dump(PlayerName(player)))

		if cooldowns:get(player) then
			cooldowns:set(player)
		end
	end
end

function classes.finish()
	for _, player in pairs(minetest.get_connected_players()) do
		classes.reset_class_cooldowns()

		player:set_properties({hp_max = minetest.PLAYER_MAX_HP_DEFAULT, visual_size = vector.new(1, 1, 1)})
		physics.remove(player:get_player_name(), "ctf_mode_classes:class_physics")
	end
end

return classes
