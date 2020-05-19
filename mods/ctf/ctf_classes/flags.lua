ctf_flag.register_on_pick_up(function(name)
	ctf_classes.update(minetest.get_player_by_name(name))
end)

ctf_flag.register_on_drop(function(name)
	ctf_classes.update(minetest.get_player_by_name(name))
end)

local old_func = ctf_flag.on_punch
local function on_punch(pos, node, player, ...)
	local class = ctf_classes.get(player)
	if not class.properties.can_capture then
		local pname = player:get_player_name()
		local flag = ctf_flag.get(pos)
		local team = ctf.player(pname).team
		if flag and flag.team and team and team ~= flag.team then
			minetest.chat_send_player(pname,
				"You need to change classes to capture the flag!")
			return
		end
	end

	return old_func(pos, node, player, ...)
end

local function show(_, _, player)
	local can_change, reason = ctf_classes.can_change(player)
	if not can_change then
		minetest.chat_send_player(player:get_player_name(), reason)
	else
		ctf_classes.show_gui(player:get_player_name(), player)
	end
end

ctf_flag.on_rightclick = show
ctf_flag.on_punch = on_punch
