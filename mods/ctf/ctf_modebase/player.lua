ctf_modebase.player = {}

local simplify_for_saved_stuff = function(iname)
	if not iname or iname == "" then return iname end

	if iname:match("default:pick_(%a+)") then
		return "pick"
	elseif iname:match("default:axe_(%a+)") then
		return "axe"
	elseif iname:match("default:shovel_(%a+)") then
		return "shovel"
	elseif iname:match("ctf_mode_nade_fight:") then
		return "nade_fight_grenade"
	end

	local mod, match = iname:match("(%a+):sword_(%a+)")

	if mod and (mod == "default" or mod == "ctf_melee") and match then
		return "sword"
	end

	return iname
end

function ctf_modebase.player.save_initial_stuff_order(player, soft)
	if not ctf_modebase.current_mode then return end

	local inv = player:get_inventory()
	local meta = player:get_meta()
	local ssp = meta:get_string("ctf_modebase:player:initial_stuff_order:"..ctf_modebase.current_mode)

	if ssp == "" then
		ssp = {}
	else
		ssp = minetest.deserialize(ssp)
	end

	local done = {}
	for i, s in pairs(inv:get_list("main")) do
		if s:get_name() ~= "" then
			local k = simplify_for_saved_stuff(s:get_name():match("[^%s]*"))

			if not soft or not ssp[k] then
				if not done[k] or i < k then
					ssp[k] = i
					done[k] = true
				end
			end
		end
	end

	meta:set_string("ctf_modebase:player:initial_stuff_order:"..ctf_modebase.current_mode, minetest.serialize(ssp))
end

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
	ctf_modebase.player.save_initial_stuff_order(player, true)

	local saved_stuff_positions = meta:get_string("ctf_modebase:player:initial_stuff_order:"..ctf_modebase.current_mode)

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
		for i = 1, #new+1 do
			if new[i] then
				if idx < tmp[new[i]] then
					table.insert(new, i, stack)
					break
				end
			else
				new[i] = stack
				break
			end
		end
	end

	for _, stack in ipairs(current) do
		if stack then
			table.insert(new, stack)
		end
	end

	inv:set_list("main", new)
end

minetest.register_on_item_pickup(function(itemstack, picker)
	if ctf_modebase.current_mode and ctf_teams.get(picker) then
		for name, func in pairs(ctf_modebase:get_current_mode().initial_stuff_item_levels) do
			local priority = func(itemstack)

			if priority then
				local inv = picker:get_inventory()
				for i=1, 8 do -- loop through the top row of the player's inv
					local compare = inv:get_stack("main", i)
					local cprio = func(compare)

					if cprio and cprio < priority then
						inv:set_stack("main", i, itemstack)
						return compare
					end
				end

				break -- We already found a place for it, don't check for one held by a different item type
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
