function ctf_modebase.register_mode(name, func)
	ctf_modebase.modes[name] = func
	table.insert(ctf_modebase.modelist, name)
end

function ctf_modebase.on_mode_end()
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return end
	current_mode.on_mode_end()
end

function ctf_modebase.on_mode_start()
	RunCallbacks(ctf_api.registered_on_mode_start)

	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return end
	current_mode.on_mode_start()
end

function ctf_modebase.on_new_match()
	RunCallbacks(ctf_api.registered_on_new_match)

	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return end
	current_mode.on_new_match()
end

function ctf_modebase.on_match_start()
	RunCallbacks(ctf_api.registered_on_match_start)

	ctf_modebase.match_started = true
end

function ctf_modebase.on_match_end()
	RunCallbacks(ctf_api.registered_on_match_end)

	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return end
	current_mode.on_match_end()
end

function ctf_modebase.on_respawnplayer(player)
	RunCallbacks(ctf_api.registered_on_respawnplayer, player)

	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return end
	current_mode.on_respawnplayer(player)
end

minetest.register_on_leaveplayer(function(...)
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return end
	current_mode.on_leaveplayer(...)
end)

minetest.register_on_dieplayer(function(...)
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return end
	current_mode.on_dieplayer(...)
end)

ctf_teams.register_on_allocplayer(function(...)
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return true end
	current_mode.on_allocplayer(...)
end)

minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return true end

	local team1, team2 = ctf_teams.get(player), ctf_teams.get(hitter)

	if not team1 and not team2 then return end

	local real_damage, error = current_mode.on_punchplayer(
		player, hitter, damage, time_from_last_punch, tool_capabilities, dir
	)

	if real_damage then
		player:set_hp(player:get_hp() - real_damage, {type="punch"})
	end

	if error then
		hud_events.new(hitter, {
			quick = true,
			text = error,
			color = "warning",
		})
	end

	return true
end)

ctf_healing.register_on_heal(function(player, patient, ...)
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return true end
	local team1, team2 = ctf_teams.get(player), ctf_teams.get(patient)

	if not team1 and not team2 then return end

	return current_mode.on_healplayer(player, patient, ...)
end)

function ctf_modebase.on_flag_rightclick(...)
	if ctf_modebase.current_mode then
		ctf_modebase:get_current_mode().on_flag_rightclick(...)
	end
end

function ctf_modebase.on_flag_capture(capturer, flagteams)
	RunCallbacks(ctf_api.registered_on_flag_capture, capturer, flagteams)
end

ctf_teams.team_allocator = function(...)
	if not ctf_modebase.in_game then return end

	local current_mode = ctf_modebase:get_current_mode()

	if not current_mode or #ctf_teams.current_team_list <= 0 then return end

	if current_mode.team_allocator then
		return current_mode.team_allocator(...)
	else
		return ctf_teams.default_team_allocator(...)
	end
end

local default_calc_knockback = minetest.calculate_knockback
minetest.calculate_knockback = function(...)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.calculate_knockback then
		return current_mode.calculate_knockback(...)
	else
		return default_calc_knockback(...)
	end
end

--
--- can_drop_item()

local default_item_drop = minetest.item_drop
minetest.item_drop = function(itemstack, dropper, ...)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.is_bound_item then
		if current_mode.is_bound_item(dropper, itemstack:get_name()) then
			return itemstack
		end
	end

	return default_item_drop(itemstack, dropper, ...)
end

minetest.register_allow_player_inventory_action(function(player, action, inventory, info)
	if player:get_hp() <= 0 then
		return 0
	end

	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.is_bound_item and
	action == "take" and current_mode.is_bound_item(player, info.stack:get_name()) then
		return 0
	end
end)

ctf_ranged.can_use_gun = function(player, name)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.is_restricted_item then
		return not current_mode.is_restricted_item(player, name)
	end

	return true
end

function ctf_modebase.match_mode(param)
	local _, _, opt_param, mode_param = string.find(param, "^(.*) +mode:([^ ]*)$")

	if not mode_param then
		_, _, mode_param, opt_param = string.find(param, "^mode:([^ ]*) *(.*)$")
	end

	if not mode_param then
		opt_param = param
	end

	if not mode_param or mode_param == "" then
		mode_param = nil
	end
	if not opt_param or opt_param == "" then
		opt_param = nil
	end

	return opt_param, mode_param
end

--- end
--
