local blacklist = {
	"default:pine_needles",
	".*leaves$",
	"ctf_melee:sword_stone",
	"default:pick_stone",
}

local function get_chest_access(name)
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return false, false end

	return current_mode.get_chest_access(name)
end

function ctf_teams.is_allowed_in_team_chest(listname, stack, player)
	if listname == "helper" then
		return false
	end

	for _, itemstring in ipairs(blacklist) do
		if stack:get_name():match(itemstring) then
			return false
		end
	end

	return true
end

for _, team in ipairs(ctf_teams.teamlist) do
	if not ctf_teams.team[team].not_playing then
		local chestcolor = ctf_teams.team[team].color
		local function get_chest_texture(chest_side, color, mask, extra)
			return string.format(
				"(default_chest_%s.png" ..
				"^[colorize:%s:130)" ..
				"^(default_chest_%s.png" ..
				"^[mask:ctf_teams_chest_%s_mask.png" ..
				"^[colorize:%s:60)" ..
				"%s",
				chest_side,
				color,
				chest_side,
				mask,
				color,
				extra or ""
			)
		end

		local def = {
			description = HumanReadable(team).." Team's Chest",
			tiles = {
				get_chest_texture("top", chestcolor, "top"),
				get_chest_texture("top", chestcolor, "top"),
				get_chest_texture("side", chestcolor, "side"),
				get_chest_texture("side", chestcolor, "side"),
				get_chest_texture("side", chestcolor, "side"),
				get_chest_texture("front", chestcolor, "side", "^ctf_teams_lock.png"),
			},
			paramtype2 = "facedir",
			groups = {immortal = 1, team_chest=1},
			legacy_facedir_simple = true,
			is_ground_content = false,
			sounds = default.node_sound_wood_defaults(),
		}

		function def.on_construct(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", string.format("%s Team's Chest", HumanReadable(team)))

			local inv = meta:get_inventory()
			inv:set_size("main", 6 * 7)
			inv:set_size("pro", 4 * 7)
			inv:set_size("helper", 1 * 1)
		end

		function def.can_dig(pos, player)
			return false
		end

		function def.on_rightclick(pos, node, player)
			local name = player:get_player_name()

			local flag_captured = ctf_modebase.flag_captured[team]
			if not flag_captured and team ~= ctf_teams.get(name) then
				hud_events.new(player, {
					quick = true,
					text = "You're not on team " .. team,
					color = "warning",
				})
				return
			end

			local formspec = table.concat({
				"size[10,12]",
				default.get_hotbar_bg(1,7.85),
				"list[current_player;main;1,7.85;8,1;]",
				"list[current_player;main;1,9.08;8,3;8]",
			}, "")

			local reg_access, pro_access
			if not flag_captured then
				reg_access, pro_access = get_chest_access(name)
			else
				reg_access, pro_access = true, true
			end

			if reg_access ~= true then
				formspec = formspec .. "label[0.75,3;" ..
					minetest.formspec_escape(minetest.wrap_text(
						reg_access or "You aren't allowed to access the team chest",
						60
					)) ..
				"]"

				minetest.show_formspec(name, "ctf_teams:no_access", formspec)
				return
			end

			local chestinv = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z

			formspec = formspec .. "list[" .. chestinv .. ";main;0,0.3;6,7;]" ..
				"background[6,-0.2;4.15,7.7;ctf_map_pro_section.png;false]"

			if pro_access == true then
				formspec = formspec .. "list[" .. chestinv .. ";pro;6,0.3;4,7;]" ..
					"listring[" .. chestinv ..";pro]" ..
					"listring[" .. chestinv .. ";helper]" ..
					"label[7,-0.2;" ..
					minetest.formspec_escape("Pro players only") .. "]"
			else
				formspec = formspec .. "label[6.5,2;" ..
					minetest.formspec_escape(minetest.wrap_text(
						pro_access or "You aren't allowed to access the pro section",
						20
					)) ..
				"]"
			end

			formspec = formspec ..
				"listring[" .. chestinv ..";main]" ..
				"listring[current_player;main]"

			minetest.show_formspec(name, "ctf_teams:chest",  formspec)
		end

		function def.allow_metadata_inventory_move(pos, from_list, from_index,
				to_list, to_index, count, player)
			local name = player:get_player_name()

			if team ~= ctf_teams.get(name) then
				hud_events.new(player, {
					quick = true,
					text = "You're not on team " .. team,
					color = "warning",
				})
				return 0
			end

			local reg_access, pro_access = get_chest_access(name)

			if reg_access == true and (pro_access == true or from_list ~= "pro" and to_list ~= "pro") then
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

			if team ~= ctf_teams.get(name) then
				hud_events.new(player, {
					quick = true,
					text = "You're not on team " .. team,
					color = "warning",
				})
				return 0
			end

			if not ctf_teams.is_allowed_in_team_chest(listname, stack, player) then
				return 0
			end

			local reg_access, pro_access = get_chest_access(name)

			if reg_access == true and (pro_access == true or listname ~= "pro") then
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

			if ctf_modebase.flag_captured[team] then
				return stack:get_count()
			end

			local name = player:get_player_name()

			if team ~= ctf_teams.get(name) then
				hud_events.new(player, {
					quick = true,
					text = "You're not on team " .. team,
					color = "warning",
				})
				return 0
			end

			local reg_access, pro_access = get_chest_access(name)

			if reg_access == true and (pro_access == true or listname ~= "pro") then
				return stack:get_count()
			else
				return 0
			end
		end

		function def.on_metadata_inventory_put(pos, listname, index, stack, player)
			minetest.log("action", string.format("%s puts %s to team chest at %s",
				player:get_player_name(),
				stack:to_string(),
				minetest.pos_to_string(pos)
			))
		end

		function def.on_metadata_inventory_take(pos, listname, index, stack, player)
			minetest.log("action", string.format("%s takes %s from team chest at %s",
				player:get_player_name(),
				stack:to_string(),
				minetest.pos_to_string(pos)
			))
		end

		minetest.register_node("ctf_teams:chest_" .. team, def)
	end
end
