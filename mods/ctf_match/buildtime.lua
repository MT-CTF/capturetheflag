ctf.register_on_init(function()
	ctf._set("match.build_time",         60)
end)

ctf_match.registered_on_build_time_start = {}
function ctf_match.register_on_build_time_start(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf_match.registered_on_build_time_start, func)
end

ctf_match.registered_on_build_time_end = {}
function ctf_match.register_on_build_time_end(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf_match.registered_on_build_time_end, func)
end

ctf_match.build_timer = 0

function ctf_match.is_in_build_time()
	return ctf_match.build_timer > 0
end

ctf_match.register_on_new_match(function()
	ctf_match.build_timer = ctf.setting("match.build_time")
end)
ctf.register_on_new_game(function()
	ctf_match.build_timer = ctf.setting("match.build_time")
	if ctf_match.build_timer > 0 then
		for i = 1, #ctf_match.registered_on_build_time_start do
			ctf_match.registered_on_build_time_start[i]()
		end
	end
end)

local function get_m_s_from_s(s)
	local m = math.floor(s / 60)
	s = math.floor(s - m * 60)

	return m .. "m " .. s .. "s"
end

local last = 0
minetest.register_globalstep(function(delta)
	if ctf_match.build_timer > 0 then
		ctf_match.build_timer = ctf_match.build_timer - delta
		if ctf_match.build_timer <= 0 then
			for i = 1, #ctf_match.registered_on_build_time_end do
				ctf_match.registered_on_build_time_end[i]()
			end
		end
		local rbt = math.floor(ctf_match.build_timer)
		if last ~= rbt then
			local text = get_m_s_from_s(ctf_match.build_timer) .. " until match begins!"
			for _, player in pairs(minetest.get_connected_players()) do
				ctf.hud:change(player, "ctf_match:countdown", "text", text)
			end
		end
	end
end)

ctf_match.register_on_build_time_start(function()
	minetest.chat_send_all("Prepare your base! Match starts in " ..
		ctf.setting("match.build_time") .. " seconds.")
	minetest.setting_set("enable_pvp", "false")
end)

ctf_match.register_on_build_time_end(function()
	if minetest.global_exists("chatplus") then
		chatplus.log("Build time over!")
	end
	minetest.chat_send_all("Build time over! Attack and defend!")
	minetest.setting_set("enable_pvp", "true")
	for _, player in pairs(minetest.get_connected_players()) do
		ctf.hud:remove(player, "ctf_match:countdown")
	end
end)

ctf_flag.register_on_prepick_up(function(name, flag)
	if ctf_match.is_in_build_time() then
		minetest.chat_send_player(name, "Match hasn't started yet!")
		ctf.move_to_spawn(name)
		return false
	else
		return true
	end
end)

ctf.hud.register_part(function(player, name, tplayer)
	if ctf_match.build_timer <= 0 then
		ctf.hud:remove(player, "ctf_match:countdown")
	elseif not ctf.hud:exists(player, "ctf_match:countdown") then
		ctf.hud:add(player, "ctf_match:countdown", {
			hud_elem_type = "text",
			position      = {x = 0.5, y = 0.5},
			scale         = {x = 0, y = 70},
			text          = get_m_s_from_s(ctf_match.build_timer) .. " until match begins!",
			number        = 0xFFFFFF,
			offset        = {x = -20, y = 20},
			alignment     = {x = 0.2, y = 0}
		})
	end
end)
