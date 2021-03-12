local blacklist = {
	"default:leaves",
	"default:jungleleaves",
	"default:pine_needles",
	"default:acacia_leaves",
	"default:aspen_leaves"
}


function ctf_map.is_item_allowed_in_team_chest(listname, stack, player)
	if listname == "helper" then
		return false
	end

	for _, itemstring in ipairs(blacklist) do
		if stack:get_name() == itemstring then
			return false
		end
	end

	return true
end

local colors = {"red", "blue"}
for _, chest_color in pairs(colors) do
	local def = {
		description = "Chest",
		tiles = {
			"default_chest_top_" .. chest_color .. ".png",
			"default_chest_top_" .. chest_color .. ".png",
			"default_chest_side_" .. chest_color .. ".png",
			"default_chest_side_" .. chest_color .. ".png",
			"default_chest_side_" .. chest_color .. ".png",
			"default_chest_front_" .. chest_color .. ".png"},
		paramtype2 = "facedir",
		groups = {immortal = 1, team_chest=1},
		legacy_facedir_simple = true,
		is_ground_content = false,
		sounds = default.node_sound_wood_defaults(),
	}

	function def.on_construct(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Chest")
		local inv = meta:get_inventory()
		inv:set_size("main", 4 * 7)
		inv:set_size("pro", 4 * 7)
		inv:set_size("helper", 1 * 1)
	end

	function def.can_dig(pos, player)
		return false
	end

	function def.on_rightclick(pos, node, player)
		local name = player:get_player_name()
		if chest_color ~= ctf.player(name).team then
			minetest.chat_send_player(name, "You're not on team " .. chest_color)
			return
		end

		local territory_owner = ctf.get_territory_owner(pos)
		if chest_color ~= territory_owner then
			if not territory_owner then
				ctf.warning("ctf_map", "Unowned team chest")
				minetest.set_node(pos, { name = "air" })
				return
			end
			ctf.warning("ctf_map", "Wrong chest, changing to " ..
					territory_owner .. " from " .. chest_color)
			minetest.set_node(pos, "ctf_map_core:chest_" .. territory_owner)
		end

		local formspec = table.concat({
			"size[8,12]",
			default.get_hotbar_bg(0,7.85),
			"list[current_player;main;0,7.85;8,1;]",
			"list[current_player;main;0,9.08;8,3;8]",
		}, "")

		if ctf_stats.player(name).score < 10 then
			local msg = "You need at least 10 score to access the team chest.\n" ..
				"Try killing an enemy player, or at least try to capture the flag.\n" ..
				"Find resources in chests scattered around the map."
			formspec = formspec .. "label[0.75,3;" .. minetest.formspec_escape(msg) .. "]"
			minetest.show_formspec(name, "ctf_map_core:no_access", formspec)
			return
		end

		local is_pro = ctf_stats.is_pro(name)
		local chestinv = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z

		formspec = formspec .. "list[" .. chestinv .. ";main;0,0.3;4,7;]" ..
			"background[4,-0.2;4.15,7.7;ctf_map_pro_section.png;false]"

		if is_pro then
			formspec = formspec .. "list[" .. chestinv .. ";pro;4,0.3;4,7;]" ..
				"listring[" .. chestinv ..";pro]" ..
				"listring[" .. chestinv .. ";helper]" ..
				"label[5,-0.2;" ..
				minetest.formspec_escape("Pro players only") .. "]"
		else
			formspec = formspec .. "label[4.75,3;" ..
				minetest.formspec_escape("You need at least 10000" ..
				"\nscore, 1.5+ KD, and 10+\ncaptures to access the\npro section") .. "]"
		end

		formspec = formspec ..
			"listring[" .. chestinv ..";main]" ..
			"listring[current_player;main]"

		minetest.show_formspec(name, "ctf_map_core:chest",  formspec)
	end

	function def.allow_metadata_inventory_move(pos, from_list, from_index,
			to_list, to_index, count, player)
		local name = player:get_player_name()
		if chest_color ~= ctf.player(name).team then
			minetest.chat_send_player(name, "You're not on team " .. chest_color)
			return 0
		end

		if ctf_stats.player(name).score < 10 then
			return 0
		end

		if (from_list ~= "pro" and to_list ~= "pro") or ctf_stats.is_pro(name) then
			if to_list == "helper" then
				-- handle move & overflow
				local chestinv = minetest.get_inventory({type = "node", pos = pos})
				local playerinv = player:get_inventory()
				local stack = chestinv:get_stack(from_list, from_index)
				local leftover = playerinv:add_item("main", stack)
				local n_stack = stack
				n_stack:set_count(stack:get_count() - leftover:get_count())
				chestinv:remove_item("helper", stack)
				chestinv:remove_item("pro", n_stack)
				return 0
			elseif from_list == "helper" then
				return 0
			else
				return count
			end
		else
			return 0
		end
	end

	function def.allow_metadata_inventory_put(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if chest_color ~= ctf.player(name).team then
			minetest.chat_send_player(name, "You're not on team " .. chest_color)
			return 0
		end

		local pstat = ctf_stats.player(name)
		if not pstat or not pstat.score or pstat.score < 10 then
			return 0
		end

		if not ctf_map.is_item_allowed_in_team_chest(listname, stack, player) then
			return 0
		end

		if listname ~= "pro" or ctf_stats.is_pro(name) then
			local chestinv = minetest.get_inventory({type = "node", pos = pos})
			if chestinv:room_for_item("pro", stack) then
				return stack:get_count()
			else
				-- handle overflow
				local playerinv = player:get_inventory()
				local leftovers = chestinv:add_item("pro", stack)
				local leftover = chestinv:add_item("main", leftovers)
				local n_stack = stack
				n_stack:set_count(stack:get_count() - leftover:get_count())
				playerinv:remove_item("main", n_stack)
				return 0
			end
		else
			return 0
		end
	end

	function def.allow_metadata_inventory_take(pos, listname, index, stack, player)
		if listname == "helper" then
			return 0
		end

		local name = player:get_player_name()
		if chest_color ~= ctf.player(name).team then
			minetest.chat_send_player(name, "You're not on team " .. chest_color)
			return 0
		end

		if ctf_stats.player(name).score < 10 then
			return 0
		end

		if listname ~= "pro" or ctf_stats.is_pro(name) then
			return stack:get_count()
		else
			return 0
		end
	end

	function def.on_metadata_inventory_put(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() ..
			" moves " .. (stack:get_name() or "stuff") .. " " ..
			(stack:get_count() or 0) .. " to chest at " ..
			minetest.pos_to_string(pos))
	end

	function def.on_metadata_inventory_take(pos, listname, index, stack, player)
		local chestinv = minetest.get_inventory({type = "node", pos = pos})
		local swapped_item = chestinv:get_stack(listname, index)

		if not ctf_map.is_item_allowed_in_team_chest(listname, swapped_item, player) then
			chestinv:remove_item(listname, swapped_item)
			player:get_inventory():add_item("main", swapped_item)
		end

		minetest.log("action", player:get_player_name() ..
			" takes " .. (stack:get_name() or "stuff") .. " " ..
			(stack:get_count() or 0) .. " from chest at " ..
			minetest.pos_to_string(pos))
	end

	minetest.register_node("ctf_map_core:chest_" .. chest_color, def)
end
