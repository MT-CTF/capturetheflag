ctf.register_on_init(function()
	ctf._set("match.build_time",         10)
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

ctf.register_on_new_game(function()
	ctf_match.build_timer = ctf.setting("match.build_time")
	if ctf_match.build_timer > 0 then
		for i = 1, #ctf_match.registered_on_build_time_start do
			ctf_match.registered_on_build_time_start[i]()
		end
	end
end)

minetest.register_globalstep(function(delta)
	if ctf_match.build_timer > 0 then
		ctf_match.build_timer = ctf_match.build_timer - delta
		if ctf_match.build_timer <= 0 then
			for i = 1, #ctf_match.registered_on_build_time_end do
				ctf_match.registered_on_build_time_end[i]()
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
	minetest.chat_send_all("Build time over! Attack and defend!")
	minetest.setting_set("enable_pvp", "true")
end)
