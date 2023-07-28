hpbar = {}
local max = {hp = 20}

-- credit:
-- https://github.com/minetest/minetest/blob/6de8d77e17017cd5cc7b065d42566b6b1cd076cc/builtin/game/statbars.lua#L30-L37
local function scaleToDefault(player, field)
	-- Scale "hp" or "breath" to supported amount
	local current = player["get_" .. field](player)
	local max_display = math.max(player:get_properties()[field .. "_max"], current)
	if max_display == 0 then
		return 0
	end
	return math.round(current * max[field] / max_display)
end

function hpbar.update(player)
	local tex = player:get_properties().textures

	local hp = scaleToDefault(player, "hp")

	local health_t = "blank.png"
	local health_bg_t = "blank.png"

	if hpbar.can_show(player) and hp > 0 then
		health_t = "health_" .. hp .. ".png"
		health_bg_t = "health_bg.png"
	end

	if tex[2] ~= health_t then
		player_api.set_texture(player, 2, health_t)
	end

	if tex[4] ~= health_bg_t then
		player_api.set_texture(player, 4, health_bg_t)
	end
end

minetest.register_playerevent(function(player, eventname)
	if eventname == "health_changed" or eventname == "properties_changed" then
		hpbar.update(player)
	end
end)

function hpbar.can_show(player)
	return true
end

minetest.register_on_joinplayer(function(player)
	hpbar.update(player)
end)
