local ids = {}

local texture_res = 24 -- heart texture resolution

minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({healthbar = false}) -- Hide the builtin HP bar
	-- Add own HP bar with the same visuals as the builtin one
	ids[player:get_player_name()] = player:hud_add({
		hud_elem_type = "statbar",
		position = {x = 0.5, y = 1},
		text = "heart.png",
		text2 = "heart_gone.png",
		number = minetest.PLAYER_MAX_HP_DEFAULT,
		item = minetest.PLAYER_MAX_HP_DEFAULT,
		direction = 0,
		size = {x = texture_res, y = texture_res},
		offset = {x = - 264, y = -(48 + texture_res + 16)},
	})
end)

minetest.register_on_leaveplayer(function(player)
	ids[player:get_player_name()] = nil
end)

-- HACK `register_playerevent` is not documented, but used to implement statbars by MT internally
minetest.register_playerevent(function(player, eventname)
	local id = ids[player:get_player_name()]
	if not id then return end

	if eventname == "health_changed" then
		player:hud_change(id, "number", math.round(player:get_hp() / 10))
	elseif eventname == "properties_changed" then
		-- HP max has probably changed, update HP bar background size ("item") accordingly
		player:hud_change(id, "item", math.round(player:get_properties().hp_max / 10))
	end
end)