ctf_modebase.player = {}

ctf_settings.register("auto_trash_stone_swords", {
	type = "bool",
	label = "Auto-trash stone swords when you pick up a better sword",
	description = "Only triggers when picking up swords from the ground",
	default = "false"
})

ctf_settings.register("auto_trash_stone_tools", {
	type = "bool",
	label = "Auto-trash stone tools when you pick up a better one",
	description = "Only triggers when picking up tools from the ground",
	default = "false"
})

local simplify_for_saved_stuff = function(iname)
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

local function is_initial_stuff(player, i)
	local mode = ctf_modebase:get_current_mode()
	if mode and mode.stuff_provider then
		for _, item in ipairs(mode.stuff_provider(player)) do
			if ItemStack(item):get_name() == i then
				return true
			end
		end
	end

	if ctf_map.current_map and ctf_map.current_map.initial_stuff then
		for _, item in ipairs(ctf_map.current_map.initial_stuff) do
			if ItemStack(item):get_name() == i then
				return true
			end
		end
	end
end

function ctf_modebase.player.save_initial_stuff_positions(player, soft)
	if not ctf_modebase.current_mode then return end

	local inv = player:get_inventory()
	local meta = player:get_meta()
	local ssp = meta:get_string("ctf_modebase:player:initial_stuff_positions:"..ctf_modebase.current_mode)

	if ssp == "" then
		ssp = {}
	else
		ssp = minetest.deserialize(ssp)
	end

	local done = {}
	for i, s in pairs(inv:get_list("main")) do
		local n = s:get_name()

		if n ~= "" and is_initial_stuff(player, n) then
			local k = simplify_for_saved_stuff(n:match("[^%s]*"))

			if not soft or not ssp[k] then
				if not done[k] or (i < ssp[k]) then
					ssp[k] = i
					done[k] = true
				end
			end
		end
	end

	meta:set_string("ctf_modebase:player:initial_stuff_positions:"..ctf_modebase.current_mode, minetest.serialize(ssp))
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

function ctf_modebase.player.give_initial_stuff(player)
	minetest.log("action", "Giving initial stuff to player " .. player:get_player_name())

	local inv = player:get_inventory()
	local meta = player:get_meta()

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

								inv:remove_item("main", item_level[itype].item)
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

		inv:remove_item("main", item)
		inv:add_item("main", item)
	end)

	-- Check for new items not yet in the order list
	ctf_modebase.player.save_initial_stuff_positions(player, true)

	local saved_stuff_positions = meta:get_string(
		"ctf_modebase:player:initial_stuff_positions:"..ctf_modebase.current_mode
	)

	if saved_stuff_positions == "" then
		saved_stuff_positions = {}
	else
		saved_stuff_positions = minetest.deserialize(saved_stuff_positions)
	end

	local new = {}
	local tmp = {}
	local current = inv:get_list("main")
	for search, idx in pairs(saved_stuff_positions) do
		for sidx, stack in ipairs(current) do
			if stack then
				local sname = simplify_for_saved_stuff(stack:get_name())

				if sname ~= "" and sname:match(search) then
					tmp[stack] = idx
					current[sidx] = false
				end
			end
		end
	end

	for stack, idx in pairs(tmp) do
		if not new[idx] then
			new[idx] = stack
		end
	end

	for stack, idx in pairs(tmp) do
		if new[idx] ~= stack then
			table.insert(new, stack)
		end
	end

	for _, stack in ipairs(current) do
		if stack then
			table.insert(new, stack)
		end
	end

	inv:set_list("main", new)
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
								local item, typ = simplify_for_saved_stuff(compare:get_name())
								minetest.log(dump(item)..dump(typ))
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

function ctf_modebase.player.update(player)
	-- Set skyboxes, shadows and physics

	local mode = ctf_modebase:get_current_mode()
	if mode and ctf_map.current_map then
		local map = ctf_map.current_map

		skybox.set(player, table.indexof(ctf_map.skyboxes, map.skybox)-1)

		player:set_lighting({shadows = {intensity = map.enable_shadows}})

		physics.set(player:get_player_name(), "ctf_modebase:map_physics", {
			speed = map.phys_speed,
			jump = map.phys_jump,
			gravity = map.phys_gravity,
		})

		if mode.physics then
			player:set_physics_override({
				sneak_glitch = mode.physics.sneak_glitch or false,
				new_move = mode.physics.new_move or true
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
	player:set_hp(player:get_properties().hp_max)

	local inv = player:get_inventory()

	if ctf_core.settings.server_mode == "play" then
		inv:set_list("main", {})
	end

	inv:set_list("craft", {})

	inv:set_size("craft", 1)
	inv:set_size("craftresult", 0)
	inv:set_size("hand", 0)

	ctf_modebase.player.update(player)
end)
