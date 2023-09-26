local hud = mhud.init()

local DEFAULT_BUILD_TIME = 60 * 3

local timer = nil

ctf_modebase.build_timer = {}

local function timer_func(time_left)
	for _, player in pairs(minetest.get_connected_players()) do
		local time_str = "Removing Barrier..."

		if time_left > 0 then
			time_str = string.format("%dm %ds until match begins!", math.floor(time_left / 60), math.floor(time_left % 60))
		end

		if not hud:exists(player, "build_timer") then
			hud:add(player, "build_timer", {
				hud_elem_type = "text",
				position = {x = 0.5, y = 0.5},
				offset = {x = 0, y = -42},
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
			hud_events.new(player, {
				quick = true,
				text = "You can't cross the barrier until build time is over!",
				color = "warning",
			})
			player:set_pos(ctf_map.current_map.teams[pteam].flag_pos)
		end
	end

	if time_left <= 0 then
		ctf_modebase.build_timer.finish()
		return
	end

	timer = minetest.after(1, timer_func, time_left - 1)
end


function ctf_modebase.build_timer.finish()
	if timer == nil then return end

	if ctf_map.current_map then
		ctf_map.remove_barrier(ctf_map.current_map, function()
			timer:cancel()
			timer = nil
			hud:remove_all()
			local text = "Build time is over!"
			minetest.chat_send_all(text)
			ctf_modebase.announce(text)

			ctf_modebase.on_match_start()

			minetest.sound_play("ctf_modebase_build_time_over", {
				gain = 1.0,
				pitch = 1.0,
			}, true)
		end)
	else
		timer:cancel()
		timer = nil
		hud:remove_all()

		ctf_modebase.on_match_start()
	end
end

ctf_api.register_on_new_match(function()
	timer = minetest.after(1, timer_func, ctf_modebase:get_current_mode().build_timer or DEFAULT_BUILD_TIME)
end)

ctf_api.register_on_match_end(function()
	if timer == nil then return end
	timer:cancel()
	timer = nil
	hud:remove_all()
end)

local old_protected = minetest.is_protected
minetest.is_protected = function(pos, pname, ...)
	if timer == nil then
		return old_protected(pos, pname, ...)
	end

	local pteam = ctf_teams.get(pname)

	if pteam and not ctf_core.pos_inside(pos, ctf_teams.get_team_territory(pteam)) then
		hud_events.new(pname, {
			quick = true,
			text = "You can't interact outside of your team territory during build time!",
			color = "warning",
		})

		return true
	else
		return old_protected(pos, pname, ...)
	end
end

minetest.register_chatcommand("ctf_start", {
	description = "Skip build time",
	privs = {ctf_admin = true},
	func = function(name, param)
		minetest.log("action", string.format("[ctf_admin] %s ran /ctf_start", name))

		ctf_modebase.build_timer.finish()

		return true, "Build time ended"
	end,
})

