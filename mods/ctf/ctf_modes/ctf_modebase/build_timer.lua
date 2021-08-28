local hud = mhud.init()

local DEFAULT_BUILD_TIME = 60 * 3

local target_map
local timer
local second_timer = 0

local build_timer = {
	start = function(mapdef, time)
		timer = time or DEFAULT_BUILD_TIME
		target_map = mapdef
	end,
	in_progress = function()
		return timer ~= nil
	end,
	finish = function(ignore_barrier)
		timer = nil

		if target_map then
			if not ignore_barrier then
				minetest.sound_play("ctf_modebase_build_time_over", {
					gain = 1.0,
					pitch = 1.0,
				}, true)

				ctf_map.remove_barrier(target_map)
			end

			hud:remove_all()

			target_map = nil
			timer = nil
			second_timer = 0
		end
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
	if not timer then return end

	timer = timer - dtime
	second_timer = second_timer + dtime

	if timer <= 0 then
		return build_timer.finish()
	end

	if second_timer >= 1 then
		second_timer = 0

		for _, player in pairs(minetest.get_connected_players()) do
			local time_str = string.format("%dm %ds until match begins!", math.floor(timer / 60), math.floor(timer % 60))
			local pteam = ctf_teams.get(player)

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

			if not ctf_core.pos_inside(player:get_pos(), ctf_teams.get_team_territory(pteam)) then
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
		build_timer.finish()

		return true, "Build time ended"
	end,
})

return build_timer
