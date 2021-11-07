local wear_timers = {}

ctf_modebase.update_wear = {}

function ctf_modebase.update_wear.find_item(pinv, item)
	for pos, stack in pairs(pinv:get_list("main")) do
		if stack:get_name() == item then
			return pos, stack
		end
	end
end

function ctf_modebase.update_wear.start_update(pname, item, step, down, finish_callback)
	if not wear_timers[pname] then wear_timers[pname] = {} end
	if wear_timers[pname][item] then return end

	wear_timers[pname][item] = minetest.after(1, function()
		wear_timers[pname][item] = nil
		local player = minetest.get_player_by_name(pname)

		if player then
			local pinv = player:get_inventory()
			local pos, stack = ctf_modebase.update_wear.find_item(pinv, item)

			if pos then
				local wear = stack:get_wear()

				if down then
					wear = math.max(0, wear - step)
				else
					wear = math.min(65534, wear + step)
				end

				stack:set_wear(wear)
				pinv:set_stack("main", pos, stack)

				if (down and wear > 0) or (not down and wear < 65534) then
					ctf_modebase.update_wear.start_update(pname, item, step, down, finish_callback)
				elseif finish_callback then
					finish_callback()
				end
			end
		end
	end)
end

function ctf_modebase.update_wear.cancel_updates()
	for _, timers in pairs(wear_timers) do
		for _, timer_job in pairs(timers) do
			timer_job:cancel()
		end
	end

	wear_timers = {}
end

function ctf_modebase.update_wear.cancel_player_updates(pname)
	pname = PlayerName(pname)

	if wear_timers[pname] then
		for _, timer_job in pairs(wear_timers[pname]) do
			timer_job:cancel()
		end

		wear_timers[pname] = nil
	end
end

minetest.register_on_dieplayer(function(player)
	ctf_modebase.update_wear.cancel_player_updates(player)
end)

minetest.register_on_leaveplayer(function(player)
	ctf_modebase.update_wear.cancel_player_updates(player)
end)
