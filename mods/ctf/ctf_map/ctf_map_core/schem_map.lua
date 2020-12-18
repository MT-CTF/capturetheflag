assert(minetest.get_mapgen_setting("mg_name") == "singlenode", "singlenode mapgen is required.")

minetest.register_alias("mapgen_singlenode", "ctf_map:ignore")
minetest.register_alias("ctf_map:flag", "air")
minetest.register_alias("ctf_map:ind_cobble", "ctf_map:cobble")
minetest.register_alias("ctf_map:ind_stone", "ctf_map:stone")

minetest.register_alias_force("flowers:mushroom_red", "air")
minetest.register_alias_force("flowers:mushroom_brown", "air")
minetest.register_alias_force("flowers:waterlily", "air")
minetest.register_alias_force("flowers:rose", "air")
minetest.register_alias_force("flowers:tulip", "air")
minetest.register_alias_force("flowers:dandelion_yellow", "air")
minetest.register_alias_force("flowers:geranium", "air")
minetest.register_alias_force("flowers:viola", "air")
minetest.register_alias_force("flowers:dandelion_white", "air")
minetest.register_alias_force("flowers:chrysanthemum_green", "air")
minetest.register_alias_force("default:grass_1", "air")
minetest.register_alias_force("default:grass_2", "air")
minetest.register_alias_force("default:grass_3", "air")
minetest.register_alias_force("default:grass_4", "air")
minetest.register_alias_force("default:sand_with_kelp", "default:sand")
minetest.register_alias_force("default:grass_5", "air")
minetest.register_alias_force("default:bush_leaves", "air")
minetest.register_alias_force("default:bush_stem", "air")
minetest.register_alias_force("default:stone_with_gold", "default:stone")


local max_r    = 120
ctf_map.map    = nil
ctf_map.mapdir = minetest.get_modpath(minetest.get_current_modname()) .. "/maps/"

-- Modify server status message to include map info
local map_str
local old_server_status = minetest.get_server_status
function minetest.get_server_status(name, joined)
	local status = old_server_status(name, joined)

	if not ctf_map.map or not map_str then
		return status
	end

	local str = map_str
	if name and minetest.get_player_by_name(name) then
		str = str
	end
	status = status .. "\n" .. str

	-- If player just joined, also display map hint
	if joined and ctf_map.map.hint then
		status = status .. "\n" .. minetest.colorize("#f49200", ctf_map.map.hint)
	end

	return status
end


function ctf_map.get_idx_and_map(param)
	param = param:lower():trim()
	for i, map in pairs(ctf_map.available_maps) do
		if map.name:lower():find(param, 1, true) or
				map.dirname:lower():find(param, 1, true) then
			return i, map
		end
	end
end

ctf_map.next_idx = nil
local function set_next_by_param(name, param)
	local idx, map = ctf_map.get_idx_and_map(param)
	if idx then
		ctf_map.next_idx = idx
		return true, "Selected " .. map.name
	else
		return false, "Couldn't find any matching map!"
	end
end

minetest.register_chatcommand("set_next", {
	privs = { ctf_admin = true },
	func = set_next_by_param
})

do
	-- Override /ctf_next to support an optional map name as param
	local old_func = minetest.registered_chatcommands["ctf_next"].func
	minetest.override_chatcommand("ctf_next", {
		params = "[map]",
		description = "Start the next match. The map name can be optionally specified as param.",
		func = function(name, param)
			if param and param ~= "" then
				local success, msg = set_next_by_param(name, param)
				if not success then
					return false, msg
				else
					minetest.chat_send_player(name, msg)
				end
			end

			return old_func(name)
		end
	})
end

local function load_map_meta(idx, dirname, meta)
	minetest.log("info", "load_map_meta: Loading map meta from '" .. dirname .. "/map.conf'")
	if not meta:get("r") then
		error("Map was not properly configured: " .. dirname .. "/map.conf")
	end

	local offset = vector.new(600 * idx, 0, 0)

	local initial_stuff = meta:get("initial_stuff")
	local treasures = meta:get("treasures")
	local start_time = meta:get("start_time")
	local time_speed = meta:get("time_speed")

	local map = {
		dirname       = dirname,
		name          = meta:get("name"),
		r             = tonumber(meta:get("r")),
		h             = tonumber(meta:get("h")),
		author        = meta:get("author"),
		hint          = meta:get("hint"),
		rotation      = meta:get("rotation"),
		license       = meta:get("license"),
		others        = meta:get("others"),
		base_node     = meta:get("base_node"),
		initial_stuff = initial_stuff and initial_stuff:split(","),
		treasures     = treasures and treasures:split(";"),
		start_time    = start_time and tonumber(start_time),
		time_speed    = time_speed and tonumber(time_speed),
		skybox        = ctf_map.skybox_exists(dirname),
		phys_speed    = tonumber(meta:get("phys_speed")),
		phys_jump     = tonumber(meta:get("phys_jump")),
		phys_gravity  = tonumber(meta:get("phys_gravity")),
		offset        = offset,
		teams         = {},
		chests        = {}
	}

	assert(map.r <= max_r)

	map.pos1 = vector.add(offset, { x = -map.r, y = -map.h / 2, z = -map.r })
	map.pos2 = vector.add(offset, { x =  map.r, y =  map.h / 2, z =  map.r })

	-- Read teams from config
	local i = 1
	while meta:get("team." .. i) do
		local tname  = meta:get("team." .. i)
		local tcolor = meta:get("team." .. i .. ".color")
		local tpos   = minetest.string_to_pos(meta:get("team." .. i .. ".pos"))

		map.teams[tname] = {
			color = tcolor,
			pos = vector.add(offset, tpos),
		}

		i = i + 1
	end

	-- Read custom chest zones from config
	i = 1
	minetest.log("verbose", "Parsing chest zones of " .. map.name .. "...")
	while meta:get("chests." .. i .. ".from") do
		local from  = minetest.string_to_pos(meta:get("chests." .. i .. ".from"))
		local to    = minetest.string_to_pos(meta:get("chests." .. i .. ".to"))
		assert(from and to, "Positions needed for chest zone " ..
				i .. " in map " .. map.name)

		from, to = vector.sort(from, to)

		map.chests[i] = {
			from = vector.add(offset, from),
			to   = vector.add(offset, to),
			n    = tonumber(meta:get("chests." .. i .. ".n") or "23"),
		}

		i = i + 1
	end

	-- Add default chest zones if none given
	if i == 1 then
		while meta:get("team." .. i) do
			local chests1
			if i == 1 then
				chests1 = vector.add(offset, { x = -map.r, y = -map.h / 2, z = 0 })
			elseif i == 2 then
				chests1 = map.pos1
			end

			local chests2
			if i == 1 then
				chests2 = map.pos2
			elseif i == 2 then
				chests2 = vector.add(offset, { x = map.r, y = map.h / 2, z = 0 })
			end

			map.chests[i] = {
				from = chests1,
				to = chests2,
				n = 23,
			}
			i = i + 1
		end
	end

	return map
end

-- List of shuffled map indices, used in conjunction with random map selection
local shuffled_order = {}
local shuffled_idx

math.randomseed(os.time())

-- Fisher-Yates shuffling algorithm, used for shuffling map selection order
-- Adapted from snippet provided in https://stackoverflow.com/a/35574006
local function shuffle_maps(idx_to_avoid)
	-- Reset shuffled_idx
	shuffled_idx = 1

	-- Create table of ordered indices
	shuffled_order = {}
	for i = 1, #ctf_map.available_maps, 1 do
		shuffled_order[i] = i
	end

	-- Shuffle table
	for i = #ctf_map.available_maps, 1, -1 do
		local j = math.random(i)
		shuffled_order[i], shuffled_order[j] = shuffled_order[j], shuffled_order[i]
	end

	-- Prevent the last map of the previous cycle from becoming the first in the next cycle
	if shuffled_order[1] == idx_to_avoid then
		local k = math.random(#ctf_map.available_maps - 1)
		shuffled_order[1], shuffled_order[k + 1] = shuffled_order[k + 1], shuffled_order[1]
	end
end

local random_selection_mode = false
local function select_map()
	local idx

	-- If next_idx exists, return the same
	if ctf_map.next_idx then
		idx = ctf_map.next_idx
		ctf_map.next_idx = nil
		return idx
	end

	if random_selection_mode then
		-- Get the real idx stored in table shuffled_order at index [shuffled_idx]
		idx = shuffled_order[shuffled_idx]
		shuffled_idx = shuffled_idx + 1

		-- If shuffled_idx overflows, re-shuffle map selection order
		if shuffled_idx > #ctf_map.available_maps then
			shuffle_maps(shuffled_order[#ctf_map.available_maps])
		end
	else
		-- Choose next map index, but don't select the same one again
		if ctf_map.map then
			idx = math.random(#ctf_map.available_maps - 1)
			if idx >= ctf_map.map.idx then
				idx = idx + 1
			end
		else
			idx = math.random(#ctf_map.available_maps)
		end
		ctf_map.next_idx = (idx % #ctf_map.available_maps) + 1
	end
	return idx
end

local function load_maps()
	local idx = 1
	ctf_map.available_maps = {}
	for _, dirname in pairs(minetest.get_dir_list(ctf_map.mapdir, true)) do
		if dirname ~= ".git" then
			local conf = Settings(ctf_map.mapdir .. "/" .. dirname .. "/map.conf")
			local val = minetest.settings:get("ctf_map." ..
				string.gsub(dirname, "%./", ""):gsub("/", "."))

			-- If map isn't disabled, load map meta
			if not conf:get_bool("disabled", false) and val ~= "false" then
				local map = load_map_meta(idx, dirname, conf)
				ctf_map.available_maps[idx] = map
				idx = idx + 1

				minetest.log("info", "Loaded map '" .. map.name .. "'")
			end
		end
	end

	if not next(ctf_map.available_maps) then
		error("No maps found in directory " .. ctf_map.mapdir)
	end

	-- Determine map selection mode depending on number of available maps
	-- If random, then shuffle the map selection order
	random_selection_mode = #ctf_map.available_maps >=
		(tonumber(minetest.settings:get("ctf_map.random_selection_threshold")) or 10)
	if random_selection_mode then
		shuffle_maps()
	end

	return ctf_map.available_maps
end

load_maps()

minetest.register_chatcommand("maps_reload", {
	privs = { ctf_admin = true },
	func = function(name, param)
		ctf_map.next_idx = nil

		local maps = load_maps()
		local ret = #maps .. " maps found:\n"
		for i = 1, #maps do
			ret = ret .. " * " .. maps[i].name
			if i ~= #maps then
				ret = ret .. "\n"
			end
		end

		return true, ret
	end,
})

local function place_map(map)
	ctf_map.emerge_with_callbacks(nil, map.pos1, map.pos2, function()
		local schempath = ctf_map.mapdir .. map.dirname .. "/map.mts"
		local res = minetest.place_schematic(map.pos1, schempath,
				map.rotation == "z" and "0" or "90")

		assert(res, "Unable to place schematic, does the MTS file exist? path=" .. schempath)

		for _, value in pairs(ctf_map.map.teams) do
			ctf_map.place_base(value.color, value.pos)
		end

		for _, chestzone in pairs(ctf_map.map.chests) do
			minetest.log("verbose", "Placing " .. chestzone.n .. " chests from " ..
					minetest.pos_to_string(chestzone.from) .. " to "..
					minetest.pos_to_string(chestzone.to))
			tsm_chests.place_chests(chestzone.from, chestzone.to, chestzone.n)
		end

		minetest.after(2, function()
			local msg = (minetest.colorize("#fcdb05", "Map: ") .. minetest.colorize("#f49200", map.name) ..
				minetest.colorize("#fcdb05", " by ") .. minetest.colorize("#f49200", map.author))
			if map.hint then
				msg = msg .. "\n" .. minetest.colorize("#f49200", map.hint)
			end
			minetest.chat_send_all(msg)
			if minetest.global_exists("irc") and irc.connected then
				irc:say("Map: " .. map.name)
			end
		end)

		minetest.after(10, function()
			minetest.fix_light(ctf_map.map.pos1, ctf_map.map.pos2)
		end)
	end, nil)
end

ctf_map.registered_on_map_loaded = {}
function ctf_map.register_on_map_loaded(func)
	ctf_map.registered_on_map_loaded[#ctf_map.registered_on_map_loaded + 1] = func
end

ctf_match.register_on_new_match(function()
	minetest.clear_objects({ mode = "quick" })

	-- Select map
	local idx = select_map()
	ctf_map.map = ctf_map.available_maps[idx]
	ctf_map.map.idx = idx

	map_str = (minetest.colorize("#fcdb05", "Map: ") .. minetest.colorize("#f49200", ctf_map.map.name) ..
		minetest.colorize("#fcdb05", " by ") .. minetest.colorize ("#f49200", ctf_map.map.author))

	-- Register per-map treasures, or the default set of treasures
	-- if treasures field hasn't been defined in map meta
	ctf_map.register_treasures(ctf_map.map)

	-- Place map
	place_map(ctf_map.map)

	-- Update per-map env. like time, time speed, skybox, physics, etc.
	ctf_map.update_env()

	-- Run on_map_loaded callbacks
	for i = 1, #ctf_map.registered_on_map_loaded do
		ctf_map.registered_on_map_loaded[i](ctf_map.map)
	end
end)

function ctf_match.create_teams()
	for key, value in pairs(ctf_map.map.teams) do
		local name  = key
		local color = value.color
		local flag  = table.copy(value.pos)

		if name and color and flag then
			minetest.log("action", "Creating team " .. key)
			ctf.team({
				name     = name,
				color    = color,
				add_team = true
			})

			ctf_flag.add(name, flag)

			minetest.after(0, function()
				ctf_flag.assert_flag(flag)
			end)
		else
			minetest.log("error", "Failed to create team " .. key)
		end
	end
end
