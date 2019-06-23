local blacklist = {
	"default:leaves",
	"default:jungleleaves",
	"default:pine_needles",
	"default:acacia_leaves",
	"default:aspen_leaves"
}

local function max(a, b)
	return (a > b) and a or b
end

local function get_is_player_pro(pstat)
	local kd = pstat.kills / max(pstat.deaths, 1)
	return pstat.score > 1000 and kd > 1.5
end

local colors = {"red", "blue"}
for _, chest_color in pairs(colors) do
	minetest.register_node("ctf_map:chest_" .. chest_color, {
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
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", "Chest")
			local inv = meta:get_inventory()
			inv:set_size("main", 4 * 7)
			inv:set_size("pro", 4 * 7)
			inv:set_size("helper", 1 * 1)
		end,
		on_rightclick = function(pos, node, player)
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
				minetest.set_node(pos, "ctf_map:chest_" .. territory_owner)
			end

			local formspec = table.concat({
				"size[8,12]",
				default.gui_bg,
				default.gui_bg_img,
				default.gui_slots,
				default.get_hotbar_bg(0,7.85),
				"list[current_player;main;0,7.85;8,1;]",
				"list[current_player;main;0,9.08;8,3;8]",
			}, "")

			local pstat = ctf_stats.player(name)
			if not pstat or not pstat.score or pstat.score < 10 then
				local msg = "You need at least 10 score to access the team chest.\n" ..
					"Try killing an enemy player, or at least try to capture the flag.\n" ..
					"Find resources in chests scattered around the map."
				formspec = formspec .. "label[0.75,3;" .. minetest.formspec_escape(msg) .. "]"
				minetest.show_formspec(name, "ctf_map:no_access", formspec)
				return
			end

			local is_pro = get_is_player_pro(pstat)
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
					minetest.formspec_escape("You need at least 1000" ..
					"\nscore and 1.5+ KD to\naccess the pro section") .. "]"
			end

			formspec = formspec ..
				"listring[" .. chestinv ..";main]" ..
				"listring[current_player;main]"

			minetest.show_formspec(name, "ctf_map:chest",  formspec)
		end,

		allow_metadata_inventory_move = function(pos, from_list, from_index,
				to_list, to_index, count, player)
			local name = player:get_player_name()
			if chest_color ~= ctf.player(name).team then
				minetest.chat_send_player(name, "You're not on team " .. chest_color)
				return 0
			end

			local pstat = ctf_stats.player(name)
			if not pstat or not pstat.score or pstat.score < 10 then
				return 0
			end

			if (from_list ~= "pro" and to_list ~= "pro") or get_is_player_pro(pstat) then
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
		end,
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if listname == "helper" then
				return 0
			end

			local name = player:get_player_name()
			if chest_color ~= ctf.player(name).team then
				minetest.chat_send_player(name, "You're not on team " .. chest_color)
				return 0
			end

			for _, itemstring in ipairs(blacklist) do
				if stack:get_name() == itemstring then
					return 0
				end
			end

			local pstat = ctf_stats.player(name)
			if not pstat or not pstat.score or pstat.score < 10 then
				return 0
			end

			if listname ~= "pro" or get_is_player_pro(pstat) then
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
		end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if listname == "helper" then
				return 0
			end

			local name = player:get_player_name()
			if chest_color ~= ctf.player(name).team then
				minetest.chat_send_player(name, "You're not on team " .. chest_color)
				return 0
			end

			local pstat = ctf_stats.player(name)
			if not pstat or not pstat.score or pstat.score < 10 then
				return 0
			end

			if listname ~= "pro" or get_is_player_pro(pstat) then
				return stack:get_count()
			else
				return 0
			end
		end,
		can_dig = function(pos, player)
			return false
		end,
		on_metadata_inventory_put = function(pos, listname, index, stack, player)
			minetest.log("action", player:get_player_name() ..
				" moves " .. (stack:get_name() or "stuff") .. " " ..
				(stack:get_count() or 0) .. " to chest at " ..
				minetest.pos_to_string(pos))
		end,
		on_metadata_inventory_take = function(pos, listname, index, stack, player)
			minetest.log("action", player:get_player_name() ..
				" takes " .. (stack:get_name() or "stuff") .. " " ..
				(stack:get_count() or 0) .. " from chest at " ..
				minetest.pos_to_string(pos))
		end
	})
end
