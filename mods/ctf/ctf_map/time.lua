local BASE_TIME_SPEED = 72

function ctf_map.update_time()
	local time = ctf_map.map.start_time
	local mult = ctf_map.map.time_speed or 1
	if time then
		minetest.set_timeofday(time)
	else
		minetest.set_timeofday(0.4)
	end

	minetest.settings:set("time_speed", BASE_TIME_SPEED * mult)
end
