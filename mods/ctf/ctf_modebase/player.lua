ctf_modebase.player = {}

local S = minetest.get_translator(minetest.get_current_modname())

ctf_settings.register("auto_trash_stone_swords", {
	type = "bool",
	label = S("Auto-trash stone swords when you pick up a better sword"),
	description = S("Only triggers when picking up swords from the ground"),
	default = "false"
})

ctf_settings.register("manual_initial_stuff_ordering", {
	type = "bool",
	label = S("Manual initial stuff ordering"),
	description = S("Lets you manually choose the order of your items after respawning"),
	default = "false"
})

ctf_settings.register("auto_trash_stone_tools", {
	type = "bool",
	label = S("Auto-trash stone tools when you pick up a better one"),
	description = S("Only triggers when picking up tools from the ground"),
	default = "false"
})

ctf_settings.register("flag_sound_volume", {
	type = "bar",
	label = S("Flag Sound Volume"),
	default = "10",
	min = 0,
	max = 20,
	step = 1,
})

local DEFAULT_VOLUMETRIC_LIGHTING = 10
ctf_settings.register("volumetric_lighting", {
	type = "bar",
	label = S("Volumetric Lighting Strength"),
	default = tostring(DEFAULT_VOLUMETRIC_LIGHTING),
	min = 0,
	max = 50,
	step = 1,
	on_change = function(player)
		ctf_modebase.player.update(player)
	end
})

local simplify_item_name = function(iname)
	if not iname or iname == "" then return iname end

	local match

	match = iname:match("default:pick_(%S+)")
	if match then
		return "pick", match
	end

	match = iname:match("default:axe_(%S+)")
	if match then
		return "axe", match
	end

	match = iname:match("default:shovel_(%S+)")
	if match then
		return "shovel", match
	end

	match = iname:match("ctf_mode_nade_fight:(%S+)")
	if match then
		return "nade_fight_grenade", match
	end

	if
	iname == "ctf_mode_classes:knight_sword" or
	iname == "ctf_mode_classes:support_bandage" or
	iname == "ctf_mode_classes:ranged_rifle_loaded"
	then
		return "class_primary"
	end

	local mod
	mod, match = iname:match("(%S+):sword_(%S+)")

	if mod and (mod == "default" or mod == "ctf_melee") and match then
		return "sword", match
	end

	return iname
end

-- Changes made to this function should also be made to is_initial_stuff() above
local function get_initial_stuff(player, f)
	local mode = ctf_modebase:get_current_mode()
	if mode and mode.stuff_provider then
		for _, item in ipairs(mode.stuff_provider(player)) do
			f(ItemStack(item))
		end
	end

	if ctf_map.current_map and ctf_map.current_map.initial_stuff then
		for _, item in ipairs(ctf_map.current_map.initial_stuff) do
			f(ItemStack(item))
		end
	end
end

local initial_stuff_shown = {}
local moved = {}

local function handle_remaining_initial_stuff(player)
	local inv = player:get_inventory()

	if moved[player:get_player_name()] then
		moved[player:get_player_name()] = nil
		local last_added = 8
		for _, stack in ipairs(inv:get_list("initial_stuff")) do
			local added = false
			for i=last_added+1, 32, 1 do
				if inv:get_stack("main", i):is_empty() then
					inv:set_stack("main", i, stack)
					added = true
					break
				end
			end

			if not added then
				inv:add_item("main", stack)
			end
		end
	else
		inv:set_list("main", inv:get_list("initial_stuff"))
	end

	inv:set_list("initial_stuff", {})
	initial_stuff_shown[player:get_player_name()] = nil
end

local old_show_formspec = core.show_formspec
function core.show_formspec(playername, formname, ...)
	if initial_stuff_shown[playername] and formname ~= "ctf_modebase:initial_stuff" then
		handle_remaining_initial_stuff(core.get_player_by_name(playername))
	end

	old_show_formspec(playername, formname, ...)
end

local old_ctfgui_show_formspec = ctf_gui.show_formspec
function ctf_gui.show_formspec(player, formname, ...)
	local playername = PlayerName(player)
	if initial_stuff_shown[playername] and formname ~= "ctf_modebase:initial_stuff" then
		handle_remaining_initial_stuff(core.get_player_by_name(playername))
	end

	old_ctfgui_show_formspec(player, formname, ...)
end

core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
	if inventory_info.to_list == "initial_stuff" then
		return 0
	elseif inventory_info.from_list == "initial_stuff" then
		moved[player:get_player_name()] = true
	end
end)

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "ctf_modebase:initial_stuff" and fields.quit then
		handle_remaining_initial_stuff(player)
	end
end)

function ctf_modebase.player.give_initial_stuff(player)
	local pname = player:get_player_name()
	minetest.log("action", "Giving initial stuff to player " .. pname)

	local inv = player:get_inventory()

	local target_inv = "main"
	if ctf_settings.get(player, "manual_initial_stuff_ordering") == "true" then
		target_inv = "initial_stuff"
		inv:set_size("initial_stuff", 8*4)
		inv:set_list("initial_stuff", inv:get_list("main"))
		inv:set_list("main", {})
	end

	local item_level = {}
	get_initial_stuff(player, function(item)
		local mode = ctf_modebase:get_current_mode()

		if mode and mode.initial_stuff_item_levels then
			for itype, get_level in pairs(mode.initial_stuff_item_levels) do
				local ilevel, keep = get_level(item)

				if ilevel then
					if item_level[itype] then
						-- This item is a higher level than any of its type so far
						if ilevel > item_level[itype].level then
							-- remove the other lesser item unless it's a keeper
							if not item_level[itype].keep then
								-- minetest.log(dump(item_level[itype].item:get_name()).." r< "..dump(item:get_name()))

								inv:remove_item(target_inv, item_level[itype].item)
							end

							item_level[itype] = {level = ilevel, item = item, keep = keep}
						elseif not keep then
							-- minetest.log(dump(item:get_name()).." s< "..dump(item_level[itype].item:get_name()))

							return -- skip addition, something better is present
						end
					else
						-- First item of this type!
						item_level[itype] = {level = ilevel, item = item, keep = keep}
					end

					-- We can't break after discovering an item type, as it might have multiple types
				end
			end
		end

		inv:remove_item(target_inv, item)
		inv:add_item(target_inv, item)
	end)

	if ctf_settings.get(player, "manual_initial_stuff_ordering") == "true" then
		core.show_formspec(
			pname,
			"ctf_modebase:initial_stuff",
			sfinv.make_formspec(
				player,
				{nav_titles={}},
				"label[0,0;Items will be added to your inventory when form is closed]"..
					"list[current_player;initial_stuff;0,1;8,4;]listring[]",
				true
			)
		)
		initial_stuff_shown[pname] = true
	end
end

if minetest.register_on_item_pickup then
	minetest.register_on_item_pickup(function(itemstack, picker)
		if ctf_modebase.current_mode and ctf_teams.get(picker) then
			local mode = ctf_modebase:get_current_mode()
			for name, func in pairs(mode.initial_stuff_item_levels) do
				local priority = func(itemstack)

				if priority then
					local inv = picker:get_inventory()
					for i=1, 8 do -- loop through the top row of the player's inv
						local compare = inv:get_stack("main", i)

						if not mode.is_bound_item or not mode.is_bound_item(picker, compare:get_name()) then
							local cprio = func(compare)

							if cprio and cprio < priority then
								local item, typ = simplify_item_name(compare:get_name())
								--minetest.log(dump(item)..dump(typ))
								inv:set_stack("main", i, itemstack)

								if item == "sword" and typ == "stone" and
								ctf_settings.get(picker, "auto_trash_stone_swords") == "true" then
									return ItemStack("")
								end

								if item ~= "sword" and typ == "stone" and
								ctf_settings.get(picker, "auto_trash_stone_tools") == "true" then
									return ItemStack("")
								else
									local result = inv:add_item("main", compare):get_count()

									if result == 0 then
										return ItemStack("")
									else
										compare:set_count(result)
										return compare
									end
								end
							end
						end
					end
					break -- We already found a place for it, don't check for one held by a different item type
				end
			end
		end
	end)
else
	minetest.log("error", "You aren't using the latest version of Minetest, auto-trashing and auto-sort won't work")
end

minetest.register_on_player_inventory_action(function(player, action, inv, inv_info)
	if action == "put" and inv_info.listname == "main" then
		if ctf_modebase.current_mode and ctf_teams.get(player) then
			local mode = ctf_modebase:get_current_mode()
			for name, func in pairs(mode.initial_stuff_item_levels) do
				local priority = func(inv_info.stack)

				if priority then
					for i=1, 8 do -- loop through the top row of the player's inv
						local compare = inv:get_stack("main", i)

						local cprio = func(compare)

						if cprio and cprio < priority then
							local item, typ = simplify_item_name(compare:get_name())
							--minetest.log(dump(item)..dump(typ))
							inv:set_stack("main", i, inv_info.stack)

							if item == "sword" and typ == "stone" and
							ctf_settings.get(player, "auto_trash_stone_swords") == "true" then
								inv:set_stack("main", inv_info.index, ItemStack(""))
								break
							end

							if item ~= "sword" and typ == "stone" and
							ctf_settings.get(player, "auto_trash_stone_tools") == "true" then
								inv:set_stack("main", inv_info.index, ItemStack(""))
								break
							end

							inv:set_stack("main", inv_info.index, compare)
							break
						end
					end
					break -- We already found a place for it, don't check for one held by a different item type
				end
			end
		end
	end
end)

function ctf_modebase.player.empty_inv(player)
	player:get_inventory():set_list("main", {})
end

function ctf_modebase.player.remove_bound_items(player)
	local mode = ctf_modebase:get_current_mode()
	if mode and mode.is_bound_item then
		local inv = player:get_inventory()

		local list = inv:get_list("main")
		for i, item in ipairs(list) do
			if mode.is_bound_item(player, item:get_name()) then
				list[i] = ItemStack()
			end
		end
		inv:set_list("main", list)
	end
end

function ctf_modebase.player.remove_initial_stuff(player)
	local inv = player:get_inventory()
	get_initial_stuff(player, function(item)
		inv:remove_item("main", item)
	end)
end

local function nil_to_default(x, default)
	if x == nil then
		return default
	else
		return x
	end
end

function ctf_modebase.player.update(player)
	-- Set skyboxes, shadows and physics

	local mode = ctf_modebase:get_current_mode()
	if mode and ctf_map.current_map then
		local map = ctf_map.current_map

		skybox.set(player, table.indexof(ctf_map.skyboxes, map.skybox)-1)

		player:set_lighting({
			shadows = {
				intensity = map.enable_shadows,
			},
			volumetric_light = {
				strength = (tonumber(ctf_settings.get(player, "volumetric_lighting")) or DEFAULT_VOLUMETRIC_LIGHTING)/100,
			},
		})

		physics.set(player:get_player_name(), "ctf_modebase:map_physics", {
			speed = map.phys_speed,
			jump = map.phys_jump,
			gravity = map.phys_gravity,
		})

		if mode.physics then
			player:set_physics_override({
				sneak_glitch = nil_to_default(mode.physics.sneak_glitch, false),
				new_move = nil_to_default(mode.physics.new_move, true),
			})
		end
	end
end

function ctf_modebase.player.is_playing(player)
	return true
end

ctf_api.register_on_new_match(function()
	for _, player in pairs(minetest.get_connected_players()) do
		if ctf_modebase.player.is_playing(player) then
			ctf_modebase.player.empty_inv(player)
			ctf_modebase.player.update(player)
		end
	end
end)

if ctf_core.settings.server_mode ~= "mapedit" then
	ctf_api.register_on_respawnplayer(function(player)
		if ctf_teams.get(player) then
			ctf_modebase.player.empty_inv(player)
			ctf_modebase.player.give_initial_stuff(player)
		end
	end)
end

minetest.register_on_joinplayer(function(player)
	player:set_properties({hp_max = (minetest.PLAYER_MAX_HP_DEFAULT * 10)})
	player:set_hp(player:get_properties().hp_max)

	local inv = player:get_inventory()

	if ctf_core.settings.server_mode == "play" then
		inv:set_list("main", {})
	end

	inv:set_list("craft", {})
	inv:set_list("crafting", {})
	inv:set_list("craftresult", {})

	inv:set_size("craft", 0)
	inv:set_size("crafting", 0)
	inv:set_size("craftresult", 0)
	inv:set_size("hand", 0)

	ctf_modebase.player.update(player)
end)

minetest.register_on_item_pickup(function(itemstack, picker)
	local playerinv = picker:get_inventory()
	local leftovers = playerinv:add_item("main", itemstack)
	if leftovers:get_count() > 0 then
		hud_events.new(picker, {
			text= "Your inventory is full !",
			color= "warning",
			quick=true
		})
	end
	return leftovers
end)
