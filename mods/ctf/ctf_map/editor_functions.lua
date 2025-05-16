local getpos_players = {}

local S = minetest.get_translator(minetest.get_current_modname())

function ctf_map.get_pos_from_player(name, amount, donefunc)
	getpos_players[name] = {amount = amount, func = donefunc, positions = {}}

	if amount == 2 and minetest.get_modpath("worldedit") then
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.marker_update(name)

		getpos_players[name].place_markers = true
	end

	minetest.chat_send_player(name, minetest.colorize(ctf_map.CHAT_COLOR,
			S("Please punch a node or run `/ctf_map here` to supply coordinates")))
end

local function add_position(player, pos)
	pos = vector.round(pos)

	table.insert(getpos_players[player].positions, pos)
	minetest.chat_send_player(player, minetest.colorize(ctf_map.CHAT_COLOR,
			S("Got pos") .. " " ..minetest.pos_to_string(pos, 1)))

	if getpos_players[player].place_markers then
		if #getpos_players[player].positions == 1 then
			worldedit.pos1[player] = pos
			worldedit.mark_pos1(player)
		elseif #getpos_players[player].positions == 2 then
			worldedit.pos2[player] = pos
			worldedit.mark_pos2(player)
		end
	end

	if getpos_players[player].amount > 1 then
		getpos_players[player].amount = getpos_players[player].amount - 1
	else
		minetest.chat_send_player(player, minetest.colorize(ctf_map.CHAT_COLOR,
				S("Done getting positions!")))
		getpos_players[player].func(player, getpos_players[player].positions)
		getpos_players[player] = nil
	end
end

ctf_map.register_map_command("here", function(name, params)
	local player = PlayerObj(name)

	if player then
		if getpos_players[name] then
			add_position(name, player:get_pos())
			return true
		else
			return false, S("You aren't doing anything that requires coordinates")
		end
	end
end)

minetest.register_on_punchnode(function(pos, _, puncher)
	puncher = PlayerName(puncher)

	if getpos_players[puncher] then
		add_position(puncher, pos)
	end
end)

minetest.register_on_leaveplayer(function(player)
	getpos_players[PlayerName(player)] = nil
end)
