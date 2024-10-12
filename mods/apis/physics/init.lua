physics = {}

local players = {}
local default_overrides = {
	speed        = 1.0,
	speed_crouch = 1.0,
	jump         = 1.0,
	gravity      = 1.0,
}

minetest.register_on_joinplayer(function(player)
	players[player:get_player_name()] = {}
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

local function update(name)
	local player = minetest.get_player_by_name(name)
	local override = table.copy(default_overrides)

	for _, layer in pairs(players[name]) do
		for attr, val in pairs(layer) do
			override[attr] = override[attr] * val
		end
	end

	if (override.jump or 0) <= 1.1 then
		override.jump = 1.1
	end

	if (override.speed or 0) <= 1.1 then
		override.speed = 1.1
	end

	player:set_physics_override(override)
end

function physics.set(name, layer, modifiers)
	name = PlayerName(name)

	if not players[name] then
		return
	end

	for attr, val in pairs(modifiers) do
		-- Throw error if an unsupported attribute is encountered
		assert(default_overrides[attr], "physics: Unsupported attribute!")

		-- Remove an attribute if its value is 1
		if val == 1 then
			modifiers[attr] = nil
		end
	end

	players[name][layer] = modifiers
	update(name)
end

function physics.remove(name, layer)
	name = PlayerName(name)

	if not players[name] then
		return
	end

	players[name][layer] = nil
	update(name)
end
