local blacklist = {
	"default:pine_needles",
	".*leaves$",
	"ctf_melee:sword_stone",
	"default:pick_stone",
}


local item_value = {
	["ctf_melee:sword_diamond"        ] = 16,
	["ctf_melee:sword_mese"             ] = 13,
	["ctf_ranged:shotgun_loaded"      ] = 12,
	["ctf_ranged:shotgun"             ] = 10,
	-- ["ctf_ranged:sniper_magnum_loaded"] = 10,
	-- ["ctf_ranged:sniper_magnum"       ] = 8,
	["default:sword_steel"            ] = 7,
	["default:pick_diamond"           ] = 7,
	["default:axe_diamond"            ] = 7,
	["ctf_grenades:frag"                  ] = 6,
	["default:pick_mese"              ] = 6,
	["ctf_healing:medkit"             ] = 6,
	["default:axe_mese"               ] = 6,
	["ctf_grenades:poison"                ] = 5,
	["ctf_ranged:rifle_loaded"        ] = 5,
	["ctf_ranged:smg_loaded"          ] = 5,
	["ctf_ranged:rifle"               ] = 4,
	["ctf_ranged:smg"                 ] = 4,
	["ctf_healing:bandage"            ] = 4,
	["default:shovel_diamond"         ] = 4,
	["default:pick_steel"             ] = 3,
	["default:axe_steel"              ] = 3,
	["default:shovel_mese"            ] = 3,
	["ctf_grenades:smoke"                 ] = 2,
	["ctf_ranged:pistol_loaded"       ] = 2,
	["default:mese_crystal"           ] = 2,
	["default:shovel_steel"           ] = 2,
	["ctf_ranged:pistol"              ] = 1,
}

local S = minetest.get_translator(minetest.get_current_modname())

local function get_chest_access(name)
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return false, false end

	return current_mode.get_chest_access(name)
end

local function get_store_access(team, player)
	local name = player:get_player_name()

	if team ~= ctf_teams.get(name) then
		hud_events.new(player, {
			quick = true,
			text = S("You're not on team") .. " " .. team,
			color = "warning",
		})
		return nil
	end

	local reg_access, pro_access = get_chest_access(name)

	if ctf_rankings.backend == "dummy" then
		reg_access, pro_access = true, true
	end

	if reg_access ~= true then
		return nil
	end

	return pro_access == true
end

local function award_enemy_return_score(pname, stack)
	local dropped_by = stack:get_meta():get_string("dropped_by")
	if dropped_by == "" or dropped_by == pname then
		return
	end

	local dropteam = ctf_teams.get(dropped_by)
	if not dropteam or ctf_teams.get(pname) == dropteam then
		return
	end

	local dropinfo = core.get_player_information(dropped_by)
	local pinfo = core.get_player_information(pname)
	if not dropinfo or not pinfo or dropinfo.address == pinfo.address then
		return
	end

	local mode = ctf_modebase:get_current_mode()
	if not mode or not mode.recent_rankings then
		return
	end

	local score = item_value[stack:get_name()] or 1
	mode.recent_rankings.add(pname, { score = score }, false)
end

local function is_blacklisted(stack)
	for _, itemstring in ipairs(blacklist) do
		if stack:get_name():match(itemstring) then
			return true
		end
	end

	return false
end

-- Returns unstored count; excess goes back to the player (or drops at their feet).
local function drain_helper_slot(chestinv, player, use_pro)
	local item = chestinv:get_stack("helper", 1)

	if item:is_empty() then
		return 0
	end

	local mark = item:get_meta():get_string("dropped_by")
	item:get_meta():set_string("dropped_by", "")

	if use_pro and ctf_teams.is_allowed_in_team_chest("pro", item, player) then
		item = chestinv:add_item("pro", item)
	end

	if not item:is_empty() and ctf_teams.is_allowed_in_team_chest("main", item, player) then
		item = chestinv:add_item("main", item)
	end

	-- Check remaining stack after adding
	if item:is_empty() then
		chestinv:set_stack("helper", 1, item)

		return 0
	else
		item:get_meta():set_string("dropped_by", mark)

		local back = player:get_inventory():add_item("main", item)
		if not back:is_empty() then
			if core.add_item(player:get_pos(), back) ~= nil then
				back = ItemStack("")
			end
		end

		chestinv:set_stack("helper", 1, back)

		return item:get_count()
	end
end

function ctf_teams.is_allowed_in_team_chest(listname, stack, player)
	if listname == "helper" then
		return false
	end

	return not is_blacklisted(stack)
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
			meta:set_string("infotext", S("@1 Team's Chest", HumanReadable(team)))

			local inv = meta:get_inventory()
			inv:set_size("main", 6 * 7)
			inv:set_size("pro", 4 * 7)
			inv:set_size("helper", 1)
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
					text = S("You're not on team") .. " " .. team,
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
			if not flag_captured and ctf_rankings.backend ~= "dummy" then
				reg_access, pro_access = get_chest_access(name)
			else
				reg_access, pro_access = true, true
			end

			if reg_access ~= true then
				formspec = formspec .. "label[0.75,3;" ..
					minetest.formspec_escape(minetest.wrap_text(
						reg_access or S("You aren't allowed to access the team chest"),
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
					"listring[current_player;main]" ..
					"listring[" .. chestinv .. ";helper]" ..
					"label[7,-0.2;" ..
					minetest.formspec_escape(S("Pro players only")) .. "]"
			else
				formspec = formspec .. "label[6.5,2;" ..
					minetest.formspec_escape(minetest.wrap_text(
						pro_access or S("You aren't allowed to access the pro section"),
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
					text = S("You're not on team") .. " " .. team,
					color = "warning",
				})
				return 0
			end

			local reg_access, pro_access = get_chest_access(name)

			if ctf_rankings.backend == "dummy" then
				reg_access, pro_access = true, true
			end

			if reg_access == true and (pro_access == true or from_list ~= "pro" and to_list ~= "pro") then
				if to_list == "helper" or from_list == "helper" then
					return 0
				else
					return count
				end
			else
				return 0
			end
		end

		function def.allow_metadata_inventory_put(pos, listname, index, stack, player)
			local use_pro = get_store_access(team, player)
			if use_pro == nil then
				return 0
			end

			-- Shift-clicked
			if listname == "helper" then
				if is_blacklisted(stack) then
					return 0
				end

				return stack:get_count()
			end

			if not ctf_teams.is_allowed_in_team_chest(listname, stack, player) then
				return 0
			end

			if listname == "pro" and not use_pro then
				return 0
			end

			local chestinv = core.get_inventory({type = "node", pos = pos})
			if chestinv:room_for_item(listname, stack) then
				return stack:get_count()
			end
			return 0
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
					text = S("You're not on team") .. " " .. team,
					color = "warning",
				})
				return 0
			end

			local reg_access, pro_access = get_chest_access(name)

			if ctf_rankings.backend == "dummy" then
				reg_access, pro_access = true, true
			end

			if reg_access == true and (pro_access == true or listname ~= "pro") then
				return stack:get_count()
			else
				return 0
			end
		end


	function def.on_metadata_inventory_put(pos, listname, index, stack, player)
		local pname = player:get_player_name()
		local inv = core.get_inventory({type = "node", pos = pos})

		-- Handle shift-clicks
		if listname == "helper" then
			local use_pro = get_store_access(team, player)
			if use_pro == nil then
				return
			end

			local placed = stack:get_count() - drain_helper_slot(inv, player, use_pro)
			if placed > 0 then
				local done = ItemStack(stack)
				done:set_count(placed)

				core.log("action", string.format("%s puts %s to team chest at %s",
					pname,
					done:to_string(),
					core.pos_to_string(pos)
				))
				award_enemy_return_score(pname, stack)
			end

			return
		end

		minetest.log("action", string.format("%s puts %s to team chest at %s",
			pname,
			stack:to_string(),
			minetest.pos_to_string(pos)
		))

		award_enemy_return_score(pname, stack)
		local stack_ = inv:get_stack(listname,index)
		stack_:get_meta():set_string("dropped_by", "")
		inv:set_stack(listname, index, stack_)
	end

		function def.on_metadata_inventory_take(pos, listname, index, stack, player)
			minetest.log("action", string.format("%s takes %s from team chest at %s",
				player:get_player_name(),
				stack:to_string(),
				minetest.pos_to_string(pos)
			))
		end

		function def.on_metadata_inventory_move(pos, from_list, from_index,
				to_list, to_index, count, player)
			core.log("action", string.format("%s moves %d from %s to %s in team chest at %s",
				player:get_player_name(),
				count,
				from_list,
				to_list,
				core.pos_to_string(pos)
			))
		end

		minetest.register_node("ctf_teams:chest_" .. team, def)
	end
end
