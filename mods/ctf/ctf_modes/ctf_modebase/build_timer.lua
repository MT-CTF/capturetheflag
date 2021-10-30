local hud = mhud.init()

local DEFAULT_BUILD_TIME = 60 * 3

local timer
local target_map
local finish_callback
local second_timer = 0

ctf_modebase.build_timer = {
	start = function(mapdef, time, callback)
		timer = time or DEFAULT_BUILD_TIME
		target_map = mapdef
		finish_callback = callback
	end,
	in_progress = function()
		return timer ~= nil
	end,
	finish = function(ignore_barrier)
		if timer == nil then return end

		finish_callback()

		if target_map then
			if not ignore_barrier then
				minetest.sound_play("ctf_modebase_build_time_over", {
					gain = 1.0,
					pitch = 1.0,
				}, true)

				ctf_map.remove_barrier(target_map)
			end

			hud:remove_all()
		end

		timer = nil
		target_map = nil
		finish_callback = nil
		second_timer = 0
	end
}

local old_protected = minetest.is_protected
minetest.is_protected = function(pos, pname, ...)
	if timer == nil then
		return old_protected(pos, pname, ...)
	end

	local pteam = ctf_teams.get(pname)

	if pteam and not ctf_core.pos_inside(pos, ctf_teams.get_team_territory(pteam)) then
		minetest.chat_send_player(pname, "You can't interact outside of your team territory during build time!")

		return true
	else
		return old_protected(pos, pname, ...)
	end
end

minetest.register_globalstep(function(dtime)
	if timer == nil then return end

	timer = timer - dtime
	second_timer = second_timer + dtime

	if timer <= 0 then
		return ctf_modebase.build_timer.finish()
	end

	if second_timer >= 1 then
		second_timer = 0

		for _, player in pairs(minetest.get_connected_players()) do
			local time_str = string.format("%dm %ds until match begins!", math.floor(timer / 60), math.floor(timer % 60))

			if not hud:exists(player, "build_timer") then
				hud:add(player, "build_timer", {
					hud_elem_type = "text",
					position = {x = 0.5, y = 0.5},
					offset = {x = 0, y = -42},
					alignment = {x = "center", y = "up"},
					text = time_str,
					color = 0xFFFFFF,
				})
			else
				hud:change(player, "build_timer", {
					text = time_str
				})
			end

			local pteam = ctf_teams.get(player)
			if pteam and not ctf_core.pos_inside(player:get_pos(), ctf_teams.get_team_territory(pteam)) then
				minetest.chat_send_player(player:get_player_name(), "You can't cross the barrier until build time is over!")
				player:set_pos(ctf_map.current_map.teams[pteam].flag_pos)
			end
		end
	end
end)

minetest.register_chatcommand("ctf_start", {
	description = "Skip build time",
	privs = {ctf_admin = true},
	func = function(name, param)
		ctf_modebase.build_timer.finish()

		return true, "Build time ended"
	end,
})
