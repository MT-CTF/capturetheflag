-- add_mode_func(minetest.register_on_dieplayer, "on_dieplayer", true) is the same as calling
--[[
	minetest.register_on_dieplayer(function(...)
		if current_mode.on_dieplayer then
			return current_mode.on_dieplayer(...)
		end
	end, true)
]]--
local function add_mode_func(minetest_func, mode_func_name, ...)
	minetest_func(function(...)
		local current_mode = ctf_modebase:get_current_mode()

		if not current_mode then return end

		if current_mode[mode_func_name] then
			return current_mode[mode_func_name](...)
		end
	end, ...)
end

add_mode_func(ctf_teams.register_on_allocplayer  , "on_allocplayer"  )
add_mode_func(ctf_teams.register_on_deallocplayer, "on_deallocplayer")
add_mode_func(minetest .register_on_dieplayer    , "on_dieplayer"    )
add_mode_func(minetest .register_on_respawnplayer, "on_respawnplayer")
add_mode_func(minetest .register_on_punchplayer  , "on_punchplayer"  )

add_mode_func(minetest.register_on_joinplayer , "on_joinplayer" )
add_mode_func(minetest.register_on_leaveplayer, "on_leaveplayer")

add_mode_func(ctf_modebase.register_on_new_match, "on_new_match", true)
add_mode_func(ctf_modebase.register_on_new_mode, "on_mode_start", true)
-- on_mode_end is called in match.lua's ctf_modebase.start_new_match()

add_mode_func(ctf_healing.register_on_heal, "on_healplayer")

ctf_teams.allocate_player = function(...)
	local current_mode = ctf_modebase:get_current_mode()

	if not current_mode or #ctf_teams.current_team_list <= 0 then return end

	if current_mode.allocate_player then
		return current_mode.allocate_player(...)
	else
		return ctf_teams.default_allocate_player
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
		if current_mode.is_bound_item(dropper, itemstack) then
			return itemstack
		end
	end

	return default_item_drop(itemstack, dropper, ...)
end

dropondie.register_drop_filter(function(player, itemname)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.is_bound_item then
		return not current_mode.is_bound_item(player, ItemStack(itemname))
	end

	return true
end)

minetest.register_allow_player_inventory_action(function(player, action, inventory, info)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.is_bound_item and
	action == "take" and current_mode.is_bound_item(player, info.stack) then
		return 0
	end
end)

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
