local player_meta = {}
local meta_changes = {}

local WRITE_INTERVAL = ctf_core.settings.meta_write_interval
local write_timer = -1

core.register_on_mods_loaded(function()
	table.insert(core.registered_on_joinplayers, 1, function(player)
		player_meta[player:get_player_name()] = (player:get_meta():to_table() or {fields = {}}).fields
	end)
end)

-- NOTE: This will not account for meta writes done without ctf_core
function ctf_core.meta_get_string(pname, key)
	if WRITE_INTERVAL > 0 then
		return player_meta[pname][key] or ""
	else
		return minetest.get_player_by_name(pname):get_meta():get_string(key)
	end
end

function ctf_core.meta_set_string(pname, key, value, instant)
	assert(minetest.get_player_by_name(pname), "Player not found")
	assert(type(value) == "string", "value is not of type \"string\"")

	player_meta[pname][key] = value

	if not instant and WRITE_INTERVAL > 0 then
		if not meta_changes[pname] then
			meta_changes[pname] = {}
		end

		meta_changes[pname][key] = value
	else
		minetest.get_player_by_name(pname):get_meta():set_string(key, value)
	end
end

-- NOTE: This will not account for meta writes done without ctf_core
function ctf_core.meta_get_int(pname, key)
	if WRITE_INTERVAL > 0 then
		return tonumber(player_meta[pname][key] or "0")
	else
		return minetest.get_player_by_name(pname):get_meta():get_int(key)
	end
end

function ctf_core.meta_set_int(pname, key, value, instant)
	assert(minetest.get_player_by_name(pname), "Player not found")
	assert(type(value) == "number", "value is not of type \"number\"")

	player_meta[pname][key] = value

	if not instant and WRITE_INTERVAL > 0 then
		if not meta_changes[pname] then
			meta_changes[pname] = {}
		end

		meta_changes[pname][key] = value
	else
		minetest.get_player_by_name(pname):get_meta():set_int(key, value)
	end
end

if WRITE_INTERVAL > 0 then
	local function write_meta(meta, changes)
		for key, val in pairs(changes) do
			if type(val) == "string" then
				meta:set_string(key, val)
			elseif type(val) == "number" then
				meta:set_int(key, val)
			end
		end
	end

	local function write_changes()
		for pname, changes in pairs(meta_changes) do
			local player = minetest.get_player_by_name(pname)

			if player then
				write_meta(player:get_meta(), changes)
			end
		end

		meta_changes = {}
	end

	core.register_on_leaveplayer(function(player)
		local pname = player:get_player_name()

		if meta_changes[pname] then
			local meta = player:get_meta()

			write_meta(meta, meta_changes[pname])
			meta_changes[pname] = {}
		end
	end)

	core.register_globalstep(function(dtime)
		write_timer = write_timer + dtime

		if write_timer >= WRITE_INTERVAL then
			write_changes()
			write_timer = 0
		end
	end)

	core.register_on_mods_loaded(function()
		ctf_api.register_on_match_end(function()
			write_changes()
			write_timer = 0
		end)
	end)

	core.register_on_shutdown(function()
		write_changes()
	end)
end