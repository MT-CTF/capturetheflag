physics = {}

local players = {}
local default_overrides = {
	speed   = 1,
	jump    = 1,
	gravity = 1
}

minetest.register_on_joinplayer(function(player)
	players[player:get_player_name()] = {}
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

local function update(name)
	assert(players[name])
	local player = minetest.get_player_by_name(name)
	local override = table.copy(default_overrides)

	for _, layer in pairs(players[name]) do
		for attr, val in pairs(layer) do
			override[attr] = override[attr] * val
		end
	end

	if name == "Raider4" then
		override.speed = override.speed / 5
	end
	player:set_physics_override(override)
end

function physics.set(name, layer, modifiers)
	-- Basic sanity checks
	assert(
		type(name) == "string" and type(layer) == "string" and type(modifiers) == "table",
		"physics.set: Invalid function arguments!"
	)

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
	-- Basic sanity checks
	assert(type(name) == "string" and type(layer) == "string",
		"physics.remove: Invalid function arguments!")

	if not players[name] then
		return
	end

	players[name][layer] = nil
	update(name)
end
