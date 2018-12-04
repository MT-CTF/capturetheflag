local blacklist = {
	"default:pick_wood",
	"default:axe_wood",
	"default:shovel_wood",
	"default:sword_wood",
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
local chest_name_to_team = {}
for _, chest_color in pairs(colors) do
	chest_name_to_team["ctf_team_base:chest_" .. chest_color] = chest_color
	minetest.register_node("ctf_team_base:chest_" .. chest_color, {
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
			inv:set_size("main", 5*4)
			inv:set_size("pro", 3*4)
		end,
		on_rightclick = function(pos, node, player)
			if chest_color ~= ctf.player(player:get_player_name()).team then
				minetest.chat_send_player(player:get_player_name(), "You're not on team " .. chest_color)
				return
			end

			local territory_owner = ctf.get_territory_owner(pos)
			if chest_color ~= territory_owner then
				if not territory_owner then
					ctf.warning("ctf_team_base", "Unowned team chest")
					minetest.set_node(pos, { name = "air" })
					return
				end
				ctf.warning("ctf_team_base", "Wrong chest, changing to " .. territory_owner .. " from " .. chest_color)
				minetest.set_node(pos, "ctf_team_base:chest_" .. territory_owner)
			end

			local formspec = table.concat({
				"size[8,9]",
				default.gui_bg,
				default.gui_bg_img,
				default.gui_slots,
				"list[current_player;main;0,4.85;8,1;]",
				"list[current_player;main;0,6.08;8,3;8]",
			}, "")

			local pstat = ctf_stats.player(player:get_player_name())
			if not pstat or not pstat.score or pstat.score < 10 then
				local msg = "You need at least 10 score to access the team chest.\n" ..
					"Try killing an enemy player, or at least attempting to capture the flag.\n" ..
					"Find resources in chests scattered around the map."
				formspec = formspec .. "label[1,1;" .. minetest.formspec_escape(msg) .. "]"
				minetest.show_formspec(player:get_player_name(), "ctf_team_base:no_access",  formspec)
				return
			end

			local is_pro = get_is_player_pro(pstat)
			local chestinv = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z

			formspec = formspec ..
				"label[0,-0.2;" .. minetest.formspec_escape("Any team member can take from here") .. "]" ..
				"list[" .. chestinv .. ";main;0,0.3;5,4;]" ..
				"background[5,-0.2;3.15,4.7;ctf_team_base_pro_only.png;false]" ..
				"list[" .. chestinv .. ";pro;5,0.3;3,4;]"

			if is_pro then
				formspec = formspec .. "listring[current_name;pro]" ..
					"label[5,-0.2;" .. minetest.formspec_escape("Pro players only (1k+ score, 1.5+ KD)") .. "]"
			else
				formspec = formspec .. "listring[current_name;pro]" ..
					"label[5,-0.2;" .. minetest.formspec_escape("You need 1k+ score and 1.5+ KD") .. "]"
			end

			formspec = formspec ..
				"listring[current_name;main]" ..
				"listring[current_player;main]" ..
				default.get_hotbar_bg(0,4.85)

			minetest.show_formspec(player:get_player_name(), "ctf_team_base:chest",  formspec)
		end,

		allow_metadata_inventory_move = function(pos, from_list, from_index,
				to_list, to_index, count, player)
			if chest_color ~= ctf.player(player:get_player_name()).team then
				minetest.chat_send_player(player:get_player_name(), "You're not on team " .. chest_color)
				return 0
			end

			local pstat = ctf_stats.player(player:get_player_name())
			if not pstat or not pstat.score or pstat.score < 10 then
				return 0
			end

			if (from_list ~= "pro" and to_list ~= "pro") or get_is_player_pro(pstat) then
				return count
			else
				return 0
			end
		end,
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if chest_color ~= ctf.player(player:get_player_name()).team then
				minetest.chat_send_player(player:get_player_name(), "You're not on team " .. chest_color)
				return 0
			end

			for _, itemstring in ipairs(blacklist) do
				if stack:get_name() == itemstring then
					return 0
				end
			end

			local pstat = ctf_stats.player(player:get_player_name())
			if not pstat or not pstat.score or pstat.score < 10 then
				return 0
			end

			if listname ~= "pro" or get_is_player_pro(pstat) then
				return stack:get_count()
			else
				return 0
			end
		end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if chest_color ~= ctf.player(player:get_player_name()).team then
				minetest.chat_send_player(player:get_player_name(), "You're not on team " .. chest_color)
				return 0
			end

			local pstat = ctf_stats.player(player:get_player_name())
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
				" moves " .. (stack:get_name() or "stuff") .. " " .. (stack:get_count() or 0)  .. " to chest at " .. minetest.pos_to_string(pos))
		end,
		on_metadata_inventory_take = function(pos, listname, index, stack, player)
			minetest.log("action", player:get_player_name() ..
				" takes " .. (stack:get_name() or "stuff") .. " " .. (stack:get_count() or 0) .. " from chest at " .. minetest.pos_to_string(pos))
		end
	})
end

minetest.register_abm({
	nodenames = {"group:team_chest"},
	interval = 10, -- Run every 10 seconds
	chance = 1, -- Select every 1 in 50 nodes
	action = function(pos, node, active_object_count, active_object_count_wider)
		local current_owner = assert(chest_name_to_team[node.name])

		local territory_owner = ctf.get_territory_owner(pos)
		if territory_owner and current_owner ~= territory_owner then
			ctf.warning("ctf_team_base", "Wrong chest, changing to " .. territory_owner .. " from " .. current_owner)
			minetest.set_node(pos, { name = "ctf_team_base:chest_" .. territory_owner })
		end
	end
})
