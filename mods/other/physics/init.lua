physics = {}

local players = {}

minetest.register_on_joinplayer(function(player)
	players[player:get_player_name()] = {}
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

local function update(name)
	assert(players[name])
	local player = minetest.get_player_by_name(name)
	local override = {
		speed   = 1,
		jump    = 1,
		gravity = 1
	}

	for _, layer in pairs(players[name]) do
		for attr, val in pairs(layer) do
			override[attr] = override[attr] * val
		end
	end

	player:set_physics_override(override)
end

function physics.set(pname, name, modifiers)
	if not players[pname] then
		return
	end

	players[pname][name] = modifiers
	update(pname)
end

function physics.remove(pname, name)
	if not players[pname] then
		return
	end

	players[pname][name] = nil
	update(pname)
end
