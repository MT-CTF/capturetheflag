ctf_combat_mode = {}

local hud = mhud.init()

local in_combat = {}

local function update_hud(player, time)
	player = PlayerName(player)

	if time <= 0 then
		return ctf_combat_mode.remove(player)
	end

	local hud_message = "You are in combat [%ds left]"

	if hud:exists(player, "combat_indicator") then
		hud:change(player, "combat_indicator", {
			text = hud_message:format(time)
		})
	else
		hud:add(player, "combat_indicator", {
			hud_elem_type = "text",
			position = {x = 1, y = 0.2},
			alignment = {x = "left", y = "down"},
			offset = {x = -6, y = 0},
			text = hud_message:format(time),
			color = 0xF00000,
		})
	end

	minetest.after(1, function()
		local playerobj = minetest.get_player_by_name(player)

		if playerobj and in_combat[player] then
			local pos = vector.offset(playerobj:get_pos(), 0, 1, 0)
			local node = minetest.registered_nodes[minetest.get_node(pos).name]

			if node.walkable == false then
				in_combat[player].time = in_combat[player].time - 1
			else
				in_combat[player].time = in_combat[player].time + 0.5
			end

			update_hud(player, in_combat[player].time)
		end
	end)
end

function ctf_combat_mode.set(player, time, extra)
	player = PlayerName(player)

	if not in_combat[player] then
		in_combat[player] = {time = time, extra = {}}
		update_hud(player, time)
	else
		in_combat[player].time = time
	end

	for k, v in pairs(extra) do
		in_combat[player].extra[k] = v
	end
end

function ctf_combat_mode.get(player)
	return in_combat[PlayerName(player)]
end

function ctf_combat_mode.get_all()
	return in_combat
end

function ctf_combat_mode.get_extra(player, name)
	local pname = PlayerName(player)
	local ret = {}

	if in_combat[pname] then
		for k, v in pairs(in_combat[pname].extra) do
			if v == name then
				table.insert(ret, k)
			end
		end
	end

	return ret
end

function ctf_combat_mode.remove(player)
	in_combat[PlayerName(player)] = nil

	if hud:get(player, "combat_indicator") then
		hud:remove(player, "combat_indicator")
	end
end

function ctf_combat_mode.remove_all()
	for _, player in pairs(minetest.get_connected_players()) do
		if in_combat[player:get_player_name()] then
			ctf_combat_mode.remove(player)
		end
	end
end

ctf_modebase.register_on_match_end(function()
	ctf_combat_mode.remove_all()
end)
