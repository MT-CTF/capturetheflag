local max = {hp = 20}
local players = {}

minetest.register_entity("ctf_hpbar:entity", {
	visual = "sprite",
	visual_size = {x=1, y=1/16, z=1},
	textures = {"blank.png"},
	collisionbox = {0},
	physical = false,
	static_save = false,
})

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

local function update_entity(entity, hp)
	local health_t = "blank.png"
	if hp > 0 then
		health_t = "health_" .. hp .. ".png"
	end

	entity:set_properties({textures = {health_t}})
end

minetest.register_playerevent(function(player, eventname)
	if eventname == "health_changed" or eventname == "properties_changed" then
		local pname = player:get_player_name()
		if players[pname] ~= nil then
			local new_hp = scaleToDefault(player, "hp")
			if new_hp ~= players[pname].hp then
				players[pname].hp = new_hp
				update_entity(players[pname].entity, new_hp)
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local entity = minetest.add_entity(player:get_pos(), "ctf_hpbar:entity")
	entity:set_attach(player, "", {x=0, y=19, z=0}, {x=0, y=0, z=0})

	local hp = scaleToDefault(player, "hp")
	players[player:get_player_name()] = {entity=entity, hp=hp}
	update_entity(entity, hp)
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if players[pname] ~= nil then
		players[pname].entity:remove()
		players[pname] = nil
	end
end)
