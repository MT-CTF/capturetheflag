local voting = false
local voters = {}
local voter_count = 0
local timer = 0

local check_interval = 0

local maps_placed = {}
local new_specific_map = nil
local function start_new_match(new_mode)
	for _, pos in pairs(ctf_teams.team_chests) do
		minetest.remove_node(pos)
	end
	ctf_teams.team_chests = {}

	local old_map = ctf_map.current_map
	local old_mode = ctf_modebase.current_mode

	if new_mode ~= old_mode then
		if old_mode and ctf_modebase.modes[old_mode].on_mode_end then
			ctf_modebase.modes[old_mode].on_mode_end()
		end
		ctf_modebase.current_mode = new_mode
		RunCallbacks(ctf_modebase.registered_on_new_mode, new_mode, old_mode)
	end

	ctf_modebase.place_map(new_mode, new_specific_map, function(map)
		give_initial_stuff.reset_stuff_providers()

		RunCallbacks(ctf_modebase.registered_on_new_match, map, old_map)

		if map.initial_stuff then
			give_initial_stuff.register_stuff_provider(function()
				return map.initial_stuff
			end)
		end

		ctf_teams.allocate_teams(map.teams)

		ctf_modebase.current_mode_matches = ctf_modebase.current_mode_matches + 1
	end)
end

minetest.register_globalstep(function(dtime)
	if not voting then return end

	check_interval = check_interval + dtime

	if check_interval >= 3 then
		timer = timer - check_interval
		check_interval = 0
	else
		return
	end

	if timer <= 0 then
		local votes = {_most = {c = 0}}

		for _, mode in pairs(ctf_modebase.modelist) do
			votes[mode] = 0
		end

		for pname, info in pairs(voters) do
			if not info.choice and timer > 0 then
				ctf_modebase.show_modechoose_form(pname)
			else
				votes[info.choice] = (votes[info.choice] or 0) + 1

				if votes[info.choice] >= votes._most.c then
					votes._most.c = votes[info.choice]
					votes._most.n = info.choice
				end
			end
		end

		voting = false
		voters = {}

		local new_mode = votes._most.n or ctf_modebase.modelist[math.random(1, #ctf_modebase.modelist)]

		minetest.chat_send_all(string.format("Voting is over, '%s' won with %d votes!",
			HumanReadable(new_mode),
			votes._most.c or 0
		))

		start_new_match(new_mode)
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()

	if voting then
		voters[minetest.get_player_information(name).address] = {
			choice = false,
			formname = ctf_modebase.show_modechoose_form(player)
		}
	end

	if ctf_modebase.current_mode and ctf_map.current_map then
		local map = ctf_map.current_map
		local mode_def = ctf_modebase:get_current_mode()
		skybox.set(player, table.indexof(ctf_map.skyboxes, map.skybox)-1)

		physics.set(name, "ctf_modebase:map_physics", {
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

minetest.register_on_leaveplayer(function(player)
	if voting then
		voters[minetest.get_player_information(player:get_player_name()).address] = nil
		voter_count = voter_count - 1
	end
end)

function ctf_modebase.start_mode_vote()
	voters = {}

	for _, player in pairs(minetest.get_connected_players()) do
		voters[minetest.get_player_information(player:get_player_name()).address] = {
			choice = false,
			formname = ctf_modebase.show_modechoose_form(player)
		}
	end

	timer = ctf_modebase.VOTING_TIME
	voting = true
	voter_count = 0
end

function ctf_modebase.start_new_match(new_mode, new_map)
	new_specific_map = new_map

	if ctf_modebase.current_mode then
		ctf_modebase:get_current_mode().on_match_end()
	end

	if new_mode then
		ctf_modebase.current_mode_matches = 0

		start_new_match(new_mode)
	-- Show mode selection form every 'ctf_modebase.MAPS_PER_MODE'-th match
	elseif ctf_modebase.current_mode_matches >= ctf_modebase.MAPS_PER_MODE or not ctf_modebase.current_mode then
		ctf_modebase.current_mode_matches = 0

		ctf_modebase.start_mode_vote()
	else
		start_new_match(ctf_modebase.current_mode)
	end
end

function ctf_modebase.show_modechoose_form(player)
	local modenames = {}

	for modename in pairs(ctf_modebase.modes) do
		table.insert(modenames, modename)
	end
	table.sort(modenames)

	local elements = {}
	local idx = 0
	for _, modename in ipairs(modenames) do
		elements[modename] = {
			type = "button",
			label = HumanReadable(modename),
			exit = true,
			pos = {"center", idx + 0.5},
			func = function(playername, fields, field_name)
				if voting then
					if ctf_modebase.modes[modename] then
						local voter = voters[minetest.get_player_information(playername).address]

						if not voter.choice then
							voter_count = voter_count + 1
						end

						voter.choice = modename

						if voter_count >= table.count(voters) then
							timer = 0
						end

						minetest.chat_send_all(string.format("%s voted for the mode '%s'", playername, HumanReadable(modename)))
					else
						ctf_modebase.show_modechoose_form(player)
					end
				end
			end,
		}

		idx = idx + 1
	end

	ctf_gui.show_formspec(player, "ctf_modebase:mode_select", {
		size = {x = 8, y = 8},
		title = "Mode Selection",
		description = "Please vote on what gamemode you would like to play",
		on_quit = function(pname)
			if voting then
				local address = minetest.get_player_information(pname).address

				minetest.after(0.1, function()
					if voting and voters[address] and not voters[address].choice then
						ctf_modebase.show_modechoose_form(pname)
					end
				end)
			end
		end,
		elements = elements,
	})

	return "ctf_modebase:mode_select"
end

--- @param mode string
--- @param mapidx integer
function ctf_modebase.place_map(mode, mapidx, callback)
	if not mapidx then
		local new_pool = {}

		if #maps_placed >= #ctf_modebase.map_catalog.maps then
			maps_placed = {}
		end

		for idx = 1, #ctf_modebase.map_catalog.maps do
			if table.indexof(maps_placed, idx) == -1 then
				table.insert(new_pool, idx)
			end
		end

		mapidx = new_pool[math.random(1, #new_pool)]
	end

	table.insert(maps_placed, mapidx)
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

minetest.register_chatcommand("ctf_next", {
	description = "Skip to a new match.",
	privs = {ctf_admin = true},
	params = "<mode:technical modename> <technical mapname>",
	func = function(name, param)
		local map = nil
		local map_name, mode = ctf_modebase.match_mode(param)

		if mode then
			if not ctf_modebase.modes[mode] then
				return false, "No such game mode: " .. mode
			end
		end

		if map_name then
			map = ctf_modebase.map_catalog.map_dirnames[map_name]
			if not map then
				return false, "No such map: " .. map_name
			end
		end

		ctf_modebase.start_new_match(mode, map)
	end,
})
