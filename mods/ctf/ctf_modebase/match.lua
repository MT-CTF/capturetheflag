local restart_on_next_match = false
ctf_modebase.map_on_next_match = nil
ctf_modebase.mode_on_next_match = nil

local map_pools = {}

function ctf_modebase.start_match_after_vote()
	for _, pos in pairs(ctf_teams.team_chests) do
		minetest.remove_node(pos)
	end
	ctf_teams.team_chests = {}

	local old_mode = ctf_modebase.current_mode

	if ctf_modebase.mode_on_next_match ~= old_mode then
		if old_mode and ctf_modebase.modes[old_mode].on_mode_end then
			ctf_modebase.modes[old_mode].on_mode_end()
		end
		ctf_modebase.current_mode = ctf_modebase.mode_on_next_match
		RunCallbacks(ctf_modebase.registered_on_new_mode, ctf_modebase.mode_on_next_match, old_mode)
	end

	ctf_modebase.place_map(ctf_modebase.mode_on_next_match, ctf_modebase.map_on_next_match, function()
		give_initial_stuff.reset_stuff_providers()

		RunCallbacks(ctf_modebase.registered_on_new_match)

		if ctf_map.current_map.initial_stuff then
			give_initial_stuff.register_stuff_provider(function()
				return ctf_map.current_map.initial_stuff
			end)
		end

		ctf_teams.allocate_teams(ctf_map.current_map.teams)

		ctf_modebase.current_mode_matches = ctf_modebase.current_mode_matches + 1
	end)

	ctf_modebase.map_on_next_match = nil
	ctf_modebase.mode_on_next_match = nil
end

local function start_new_match()
	local path = minetest.get_worldpath() .. "/queue_restart.txt"
	if ctf_core.file_exists(path) then
		assert(os.remove(path))
		restart_on_next_match = true
	end

	if restart_on_next_match then
		minetest.request_shutdown("Restarting server at imperator request.", true)
		return
	end

	ctf_modebase.on_match_end()

	if ctf_modebase.mode_on_next_match then
		ctf_modebase.current_mode_matches = 0
		ctf_modebase.start_match_after_vote()
	-- Show mode selection form every 'ctf_modebase.MAPS_PER_MODE'-th match
	elseif ctf_modebase.current_mode_matches >= ctf_modebase.MAPS_PER_MODE or not ctf_modebase.current_mode then
		ctf_modebase.current_mode_matches = 0
		ctf_modebase.mode_vote.start_vote()
	else
		ctf_modebase.mode_on_next_match = ctf_modebase.current_mode
		ctf_modebase.start_match_after_vote()
	end
end

function ctf_modebase.start_new_match(delay)
	ctf_modebase.match_started = false
	if delay and delay > 0 then
		minetest.after(3, start_new_match)
	else
		start_new_match()
	end
end

--- @param mode string
--- @param mapidx integer
function ctf_modebase.place_map(mode, mapidx, callback)
	if not mapidx then
		if not map_pools[mode] or #map_pools[mode] == 0 then
			map_pools[mode] = {}

			for idx, map in ipairs(ctf_modebase.map_catalog.maps) do
				if not map.game_modes or table.indexof(map.game_modes, mode) ~= -1 then
					table.insert(map_pools[mode], idx)
				end
			end
		end

		local idx = math.random(1, #map_pools[mode])
		mapidx = table.remove(map_pools[mode], idx)
	end

	ctf_modebase.map_catalog.current_map = mapidx
	local map = ctf_modebase.map_catalog.maps[mapidx]
	ctf_map.place_map(map, function()
		-- Set time, time_speed, skyboxes, and physics

		minetest.set_timeofday(map.start_time/24000)

		for _, player in pairs(minetest.get_connected_players()) do
			local name = PlayerName(player)

			skybox.set(player, table.indexof(ctf_map.skyboxes, map.skybox)-1)

			physics.set(name, "ctf_modebase:map_physics", {
				speed = map.phys_speed,
				jump = map.phys_jump,
				gravity = map.phys_gravity,
			})

			-- Convert name of mode into it's def
			local mode_def = ctf_modebase.modes[mode]

			if mode_def.physics then
				player:set_physics_override({
					sneak_glitch = mode_def.physics.sneak_glitch or false,
					new_move = mode_def.physics.new_move or true
				})
			end

			minetest.settings:set("time_speed", map.time_speed * 72)
		end

		ctf_map.announce_map(map)

		callback(map)
	end)
end

local function set_next(param)
	local map = nil
	local map_name, mode = ctf_modebase.match_mode(param)

	if mode then
		if not ctf_modebase.modes[mode] then
			return "No such game mode: " .. mode
		end
	end

	if map_name then
		map = ctf_modebase.map_catalog.map_dirnames[map_name]
		if not map then
			return "No such map: " .. map_name
		end
	end

	ctf_modebase.map_on_next_match = map
	ctf_modebase.mode_on_next_match = mode
end

minetest.register_chatcommand("ctf_next", {
	description = "Set a new map and mode after the match ends",
	privs = {ctf_admin = true},
	params = "[-f] <mode:technical modename> <technical mapname>",
	func = function(name, param)
		minetest.log("action", string.format("[ctf_admin] %s ran /ctf_next %s", name, param))
		local force, pos2 = param:find("-f ")

		if pos2 then
			param = param:sub(pos2+1)
		end

		local error = set_next(param)
		if error then
			return false, error
		end

		if force then
			ctf_modebase.start_new_match()
		end

		return true, "The next map and mode are queued"
	end,
})

minetest.register_chatcommand("ctf_skip", {
	description = "Skip to a new match now",
	privs = {ctf_admin = true},
	params = "[<mode:technical modename> <technical mapname>]",
	func = function(name, param)
		minetest.log("action", string.format("[ctf_admin] %s ran /ctf_skip %s", name, param))

		if param and param ~= "" then
			local error = set_next(param)
			if error then
				return false, error
			end
		end

		ctf_modebase.start_new_match()

		return true, "Skipping match..."
	end,
})

minetest.register_chatcommand("queue_restart", {
		description = "Queue server restart",
		privs = {server = true},
		func = function(name)
				restart_on_next_match = true
				minetest.log("action", name .. " queued a restart")
				return true, "Restart is queued."
		end
})

minetest.register_chatcommand("unqueue_restart", {
		description = "Unqueue server restart",
		privs = {server = true},
		func = function(name)
				restart_on_next_match = false
				minetest.log("action", name .. " un-queued a restart")
				return true, "Restart is cancelled."
		end
})

minetest.register_on_joinplayer(function(player)
	player:set_hp(player:get_properties().hp_max)

	if ctf_modebase.current_mode and ctf_map.current_map then
		local map = ctf_map.current_map
		local mode_def = ctf_modebase:get_current_mode()
		skybox.set(player, table.indexof(ctf_map.skyboxes, map.skybox)-1)

		physics.set(player:get_player_name(), "ctf_modebase:map_physics", {
			speed = map.phys_speed,
			jump = map.phys_jump,
			gravity = map.phys_gravity,
		})

		if mode_def.physics then
			player:set_physics_override({
				sneak_glitch = mode_def.physics.sneak_glitch or false,
				new_move = mode_def.physics.new_move or true
			})
		end
	end
end)
