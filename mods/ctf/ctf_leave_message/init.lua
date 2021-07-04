function core.send_leave_message(player_name, timed_out)
	local player = ctf.player(player_name)
	local tcolor = ctf_colors.get_color(player).css

	local announcement = "*** " ..  minetest.colorize(tcolor, player_name) .. " left the game."
	if timed_out then
		announcement = announcement .. " (timed out)"
	end
	minetest.chat_send_all(announcement)
end

minetest.register_on_leaveplayer(function(player, timed_out)
	local player_name = player:get_player_name()
	ctf.send_leave_message(player_name, timed_out)
end)
