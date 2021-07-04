function ctf.send_leave_message(name, timed_out)
	local player = ctf.player(name)

	local tcolor = ctf_colors.get_color(player).css

	local announcement = "*** " ..  minetest.colorize(tcolor, name) .. " left the game."
	if timed_out then
		announcement = announcement .. " (timed out)"
	end
	core.chat_send_all(announcement)
end

function core.send_leave_message()
	return
end

core.register_on_leaveplayer(function(player, timed_out)
	local player_name = player:get_player_name()
	ctf.send_leave_message(player_name, timed_out)
end)