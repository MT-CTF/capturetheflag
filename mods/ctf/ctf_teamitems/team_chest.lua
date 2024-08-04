local blacklist = {
	"default:pine_needles",
	".*leaves$",
	"ctf_melee:sword_stone",
	"default:pick_stone",
}

--[[
local item_value = {
	["grenades:poison"] = 5,
	["grenades:frag"] = 6,
	["grenades:smoke"] = 2,
	["ctf_ranged:pistol_loaded"] = 2,
	["ctf_ranged:pistol"] = 1,
	["ctf_ranged:rifle"] = 4,
	["ctf_ranged:rifle_loaded"] = 5,
	["ctf_ranged:smg"] = 4,
	["ctf_ranged:smg_loaded"] = 5,
	["ctf_ranged:sniper_magnum"] = 8,
	["ctf_ranged:sniper_magnum_loaded"] = 10,
	["ctf_ranged:ammo"] = 4,
	["default:diamond"] = 2.5,
	["default:mese_crystal"] = 2,
	["default:mese"] = 18,
	["default:steel_ingot"] = 1,
	["default:iron_lump"] = 1,
	["default:sword_diamond"] = 16,
	["default:sword_steel"] = 7,
	["default:sword_mese"] = 13,
	["default:pick_steel"] = 3,
	["default:pick_mese"] = 6,
	["default:pick_diamond"] = 7,
	["default:axe_steel"] = 3,
	["default:axe_mese"] = 6,
	["default:axe_diamond"] = 7,
	["default:shovel_steel"] = 2,
	["default:shovel_mese"] = 3,
	["default:shovel_diamond"] = 4,
	["default:stick"] = 0.5,
	["default:wood"] = 1,
	["default:cobble"] = 1,
	["ctf_map:reinforced_cobble"] = 3,
	["ctf_map:damage_cobble"] = 3,
	["ctf_map:unwalkable_cobble"] = 1,
	["ctf_map:unwalkable_stone"] = 1,
	["ctf_map:unwalkable_dirt"] = 1,
	["default:steelblock"] = 2.5,
	["default:bronzeblock"] = 2.5,
	["default:obsidian_block"] = 3.5,
	["ctf_map:spike"] = 2.5,
	["default:apple"] = 1.5,
	["ctf_healing:medkit"] = 6,
	["ctf_healing:bandage"] = 6,
}
--]]

local open_chests = {
	-- team_color = {
	--     opener0,
	--     opener1,
	--     opener2,
	--     ...
	-- },
	-- ...
}

local function is_chest_open(team_name)
	if open_chests[team_name] and #open_chests[team_name] ~= 0 then
		return true
	else
		return false
	end
end

local function can_open_teamchest(teamname, pname)
	if ctf_teams.get(pname) == teamname then
		return true
	elseif ctf_modebase.flag_captured[teamname] then
		return true
	elseif is_chest_open(teamname) and ctf_modebase.current_mode == "classic" then
		return true
	else
		return false
	end
end

local function get_chest_access(name)
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then
		return false, false
	end

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

local TEAMCHEST_FORMSPEC_NAME = "ctf_teamitemss:chest"

for _, team in ipairs(ctf_teams.teamlist) do
	if not ctf_teams.team[team].not_playing then
		local chestcolor = ctf_teams.team[team].color
		local team_name = tostring(team)
		local function get_chest_texture(chest_side, color, mask, extra)
			return string.format(
				"(default_chest_%s.png"
					.. "^[colorize:%s:130)"
					.. "^(default_chest_%s.png"
					.. "^[mask:ctf_teamitems_chest_%s_mask.png"
					.. "^[colorize:%s:60)"
					.. "%s",
				chest_side,
				color,
				chest_side,
				mask,
				color,
				extra or ""
			)
		end

		minetest.register_on_player_receive_fields(function(player, formname, fields)
			if formname ~= TEAMCHEST_FORMSPEC_NAME then
				return
			end
			if fields.quit ~= "true" then
				return
			end

			local pname = player:get_player_name()
			if pname == "" then
				return
			end
			local pteam = ctf_teams.get(pname)
			for idx, name in ipairs(open_chests[pteam] or {}) do
				if name == pname then
					table.remove(open_chests[pteam], idx)
				end
			end
		end)
		local def = {
			description = HumanReadable(team) .. " Team's Chest",
			tiles = {
				get_chest_texture("top", chestcolor, "top"),
				get_chest_texture("top", chestcolor, "top"),
				get_chest_texture("side", chestcolor, "side"),
				get_chest_texture("side", chestcolor, "side"),
				get_chest_texture("side", chestcolor, "side"),
				get_chest_texture("front", chestcolor, "side", "^ctf_teamitems_lock.png"),
			},
			paramtype2 = "facedir",
			groups = { immortal = 1, team_chest = 1 },
			legacy_facedir_simple = true,
			is_ground_content = false,
			sounds = default.node_sound_wood_defaults(),
		}

		function def.on_construct(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string(
				"infotext",
				string.format("%s Team's Chest", HumanReadable(team))
			)

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
			local flag_captured = ctf_modebase.flag_captured[team_name]
			minetest.log("info", "open_chests" .. minetest.serialize(open_chests))
			if not can_open_teamchest(team_name, name) then
				hud_events.new(player, {
					quick = true,
					text = "You're not on team " .. team,
					color = "warning",
				})
				return
			end
			if ctf_teams.get(name) == team_name then
				if not open_chests[team_name] then
					open_chests[team_name] = {}
				end
				table.insert(open_chests[team_name], name)
				minetest.after(30, function()
					for idx, name2 in ipairs(open_chests[team_name]) do
						if name2 == name then
							table.remove(open_chests[team_name], idx)
						end
					end
				end)
			end

			local formspec = table.concat({
				"size[10,12]",
				default.get_hotbar_bg(1, 7.85),
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
				formspec = formspec
					.. "label[0.75,3;"
					.. minetest.formspec_escape(
						minetest.wrap_text(
							reg_access or "You aren't allowed to access the team chest",
							60
						)
					)
					.. "]"

				minetest.show_formspec(name, "ctf_teamitems:no_access", formspec)
				return
			end

			local chestinv = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z

			formspec = formspec
				.. "list["
				.. chestinv
				.. ";main;0,0.3;6,7;]"
				.. "background[6,-0.2;4.15,7.7;ctf_map_pro_section.png;false]"

			if pro_access == true then
				formspec = formspec
					.. "list["
					.. chestinv
					.. ";pro;6,0.3;4,7;]"
					.. "listring["
					.. chestinv
					.. ";pro]"
					.. "listring["
					.. chestinv
					.. ";helper]"
					.. "label[7,-0.2;"
					.. minetest.formspec_escape("Pro players only")
					.. "]"
			else
				formspec = formspec
					.. "label[6.5,2;"
					.. minetest.formspec_escape(
						minetest.wrap_text(
							pro_access or "You aren't allowed to access the pro section",
							20
						)
					)
					.. "]"
			end

			formspec = formspec
				.. "listring["
				.. chestinv
				.. ";main]"
				.. "listring[current_player;main]"

			minetest.show_formspec(name, TEAMCHEST_FORMSPEC_NAME, formspec)
		end

		function def.allow_metadata_inventory_move(
			pos,
			from_list,
			from_index,
			to_list,
			to_index,
			count,
			player
		)
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

			if
				reg_access == true
				and (pro_access == true or from_list ~= "pro" and to_list ~= "pro")
			then
				if to_list == "helper" then
					-- handle move & overflow
					local chestinv = minetest.get_inventory({ type = "node", pos = pos })
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
				local chestinv = minetest.get_inventory({ type = "node", pos = pos })
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

			if not can_open_teamchest(team_name, name) then
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
			minetest.log(
				"action",
				string.format(
					"%s puts %s to team chest at %s",
					player:get_player_name(),
					stack:to_string(),
					minetest.pos_to_string(pos)
				)
			)
			local meta = stack:get_meta()
			local dropped_by = meta:get_string("dropped_by")
			local pname = player:get_player_name()
			if dropped_by ~= pname and dropped_by ~= "" then
				local cur_mode = ctf_modebase:get_current_mode()
				if pname and cur_mode then
					--local score = (item_value[stack:get_name()] or 0) * stack:get_count()
					cur_mode.recent_rankings.add(pname, { score = 1 }, false)
				end
			end
			meta:set_string("dropped_by", "")
			local inv = minetest.get_inventory({ type = "node", pos = pos })
			local stack_ = inv:get_stack(listname, index)
			stack_:get_meta():set_string("dropped_by", "")
			inv:set_stack(listname, index, stack_)
		end

		function def.on_metadata_inventory_take(pos, listname, index, stack, player)
			minetest.log(
				"action",
				string.format(
					"%s takes %s from team chest at %s",
					player:get_player_name(),
					stack:to_string(),
					minetest.pos_to_string(pos)
				)
			)
			if ctf_teams.get(player:get_player_name()) ~= team_name then
				for _i = 1, stack:get_count(), 0 do
					minetest.sound_play(
						{ name = "ctf_teamitems_teamchest_steal" },
						{ pos = pos, max_hearing_distance = 12 }
					)
				end
				for pname, pteam in pairs(ctf_teams.player_team) do
					if pteam == team then
						hud_events.new(pname, {
							text = player:get_player_name()
								.. " is stealing from your team's chest!",
							color = "warning",
							quick = true,
						})
					end
				end
			end
		end

		minetest.register_node("ctf_teamitems:chest_" .. team, def)
	end
end
