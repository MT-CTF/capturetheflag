local ids = {}

local texture_res = 24 -- heart texture resolution

local function calculate_offset(hearts)
	return {x = (-hearts * texture_res) - 25, y = -(48 + texture_res + 16)}
end


minetest.register_on_joinplayer(function(player)
	-- If the hudbars mod is installed, we don't need to change the hp bar
	if minetest.get_modpath("hudbars") == nil and ctf_settings.get(player, "use_hudbars") == "false" then
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
			offset = calculate_offset(10),
		})
	end
end)

minetest.register_on_leaveplayer(function(player)
	ids[player:get_player_name()] = nil
end)

-- HACK `register_playerevent` is not documented, but used to implement statbars by MT internally
minetest.register_playerevent(function(player, eventname)
	local id = ids[player:get_player_name()]
	if not id then return end

	if eventname == "health_changed" then
		player:hud_change(id, "number", player:get_hp())
	elseif eventname == "properties_changed" then
		-- HP max has probably changed, update HP bar background size ("item") accordingly
		local hp_max = player:get_properties().hp_max
		player:hud_change(id, "item", hp_max)
		player:hud_change(id, "offset", calculate_offset(hp_max / 2))
	end
end)