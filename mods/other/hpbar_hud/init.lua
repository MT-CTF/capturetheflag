local hpbar_hud_ids = {}

minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({healthbar = false}) -- Hide the builtin HP bar
	-- Add own HP bar with the same visuals as the builtin one
	hpbar_hud_ids[player:get_player_name()] = player:hud_add({
		hud_elem_type = "statbar",
		position = {x = 0.5, y = 1},
		text = "heart.png",
		text2 = "heart_gone.png",
		number = minetest.PLAYER_MAX_HP_DEFAULT,
		item = minetest.PLAYER_MAX_HP_DEFAULT,
		direction = 0,
		size = {x = 24, y = 24},
		offset = {x = (-10 * 24) - 25, y = -(48 + 24 + 16)},
	})
end)

minetest.register_on_leaveplayer(function(player)
	hpbar_hud_ids[player:get_player_name()] = nil
end)

-- HACK `register_playerevent` is not documented, but used to implement statbars by MT internally
minetest.register_playerevent(function(player, eventname)
	if eventname == "health_changed" then
		player:hud_change(hpbar_hud_ids[player:get_player_name()], "number", player:get_hp())
	elseif eventname == "properties_changed" then
		-- HP max has probably changed, update HP bar background size ("item") accordingly
		player:hud_change(hpbar_hud_ids[player:get_player_name()], "item", player:get_properties().hp_max)
	end
end)