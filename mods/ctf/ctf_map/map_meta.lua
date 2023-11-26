local CURRENT_MAP_VERSION = "3"
local BARRIER_Y_SIZE = 16

local modname = minetest.get_current_modname()

function ctf_map.skybox_exists(subdir)
	local list = minetest.get_dir_list(subdir, true)

	return table.indexof(list, "skybox") ~= -1
end

-- calc_flag_center() calculates the center of a map from the positions of the flags.
local function calc_flag_center(map)
	local flag_center = vector.zero()
	local flag_count = 0

	for _, team in pairs(map.teams) do
		flag_center = flag_center + team.flag_pos
		flag_count = flag_count + 1
	end

	flag_center = flag_center:apply(function(value)
		return value / flag_count
	end)

	return flag_center
end

function ctf_map.load_map_meta(idx, dirname)
	local meta = Settings(ctf_map.maps_dir .. dirname .. "/map.conf")

	if not meta then error("Map '"..dump(dirname).."' not found") end

	minetest.log("info", "load_map_meta: Loading map meta from '" .. dirname .. "/map.conf'")

	local map
	local offset = vector.new(608 * idx, 0, 0) -- 608 is a multiple of 16, the size of a mapblock

	if not meta:get("map_version") then
		if not meta:get("r") then
			error("Map was not properly configured: " .. ctf_map.maps_dir .. dirname .. "/map.conf")
		end

		local mapr = meta:get("r")
		local maph = meta:get("h")
		local start_time = meta:get("start_time")
		local time_speed = meta:get("time_speed")
		local initial_stuff = meta:get("initial_stuff")

		offset.y = -maph / 2

		local offset_to_new = vector.new(mapr, maph/2, mapr)

		local pos1 = offset
		local pos2 = vector.add(offset, vector.new(mapr * 2,  maph, mapr * 2))

		map = {
			pos1          = pos1,
			pos2          = pos2,
			rotation      = meta:get("rotation"),
			offset        = offset,
			size          = vector.subtract(pos2, pos1),
			enabled       = not meta:get("disabled", false),
			dirname       = dirname,
			name          = meta:get("name"),
			author        = meta:get("author"),
			hint          = meta:get("hint"),
			license       = meta:get("license"),
			others        = meta:get("others"),
			base_node     = meta:get("base_node"),
			initial_stuff = initial_stuff and initial_stuff:split(","),
			treasures     = meta:get("treasures"),
			skybox        = "none",
			start_time    = start_time and tonumber(start_time) or ctf_map.DEFAULT_START_TIME,
			time_speed    = time_speed and tonumber(time_speed) or 1,
			phys_speed    = tonumber(meta:get("phys_speed")),
			phys_jump     = tonumber(meta:get("phys_jump")),
			phys_gravity  = tonumber(meta:get("phys_gravity")),
			chests        = {},
			teams         = {},
			barrier_area  = {pos1 = pos1, pos2 = pos2},
			barriers = false,
		}

		-- Read teams from config
		local i = 1
		while meta:get("team." .. i) do
			local tname  = meta:get("team." .. i)
			local tpos   = minetest.string_to_pos(meta:get("team." .. i .. ".pos"))

			map.teams[tname] = {
				enabled = true,
				flag_pos = vector.add(offset, vector.add( tpos, offset_to_new )),
				pos1 = vector.new(),
				pos2 = vector.new()
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
				pos1   = vector.add(offset, vector.add(from, offset_to_new)),
				pos2   = vector.add(offset, vector.add(to,   offset_to_new)),
				amount = tonumber(meta:get("chests." .. i .. ".n") or "20"),
			}

			i = i + 1
		end

		-- Add default chest zone if none given
		if i == 1 then
			map.chests[i] = {
				pos1 = map.pos1,
				pos2 = map.pos2,
				amount = ctf_map.DEFAULT_CHEST_AMOUNT,
			}
		end
	else
		-- If new items are added also remember to change the table in mapedit_gui.lua
		-- The version number should be updated if you change an item
		local size = minetest.deserialize(meta:get("size"))

		offset.y = -size.y/2

		map = {
			map_version    = CURRENT_MAP_VERSION,
			pos1           = offset,
			pos2           = vector.add(offset, size),
			offset         = offset,
			size           = size,
			dirname        = dirname,
			enabled        = meta:get("enabled") == "true",
			name           = meta:get("name"),
			author         = meta:get("author"),
			hint           = meta:get("hint"),
			license        = meta:get("license"),
			others         = meta:get("others"),
			initial_stuff  = minetest.deserialize(meta:get("initial_stuff")),
			treasures      = meta:get("treasures"),
			skybox         = meta:get("skybox"),
			start_time     = tonumber(meta:get("start_time")),
			time_speed     = tonumber(meta:get("time_speed")),
			phys_speed     = tonumber(meta:get("phys_speed")),
			phys_jump      = tonumber(meta:get("phys_jump")),
			phys_gravity   = tonumber(meta:get("phys_gravity")),
			chests         = minetest.deserialize(meta:get("chests")),
			teams          = minetest.deserialize(meta:get("teams")),
			barrier_area   = minetest.deserialize(meta:get("barrier_area")),
			game_modes     = minetest.deserialize(meta:get("game_modes")),
			enable_shadows = tonumber(meta:get("enable_shadows") or "0.26"),
		}
		if tonumber(meta:get("map_version")) > 2 and not ctf_core.settings.low_ram_mode then
			local f, err = io.open(ctf_map.maps_dir .. dirname .. "/barriers.data", "rb")

			if (ctf_core.settings.server_mode ~= "mapedit" and assert(f, err)) or f then
				local barriers = f:read("*all")

				f:close()

				assert(barriers and barriers ~= "")

				barriers = minetest.deserialize(minetest.decompress(barriers, "deflate"))

				if barriers then
					for _, barrier_area in pairs(barriers) do
						barrier_area.pos1 = vector.add(barrier_area.pos1, offset)
						barrier_area.pos2 = vector.add(barrier_area.pos2, offset)

						for i = 1, barrier_area.max do
							if not barrier_area.reps[i] then
								barrier_area.reps[i] = minetest.CONTENT_IGNORE
							else
								barrier_area.reps[i] = minetest.get_content_id(barrier_area.reps[i])
							end
						end
					end

					map.barriers = barriers
				else
					minetest.log("error", "Map "..dirname.." has a corrupted barriers file. Re-save map to fix")
				end
			else
				minetest.log("error", "Map "..dirname.." is missing its barriers file. Re-save map to fix")
			end
		end

		for id, def in pairs(map.chests) do
			map.chests[id].pos1 = vector.add(offset, def.pos1)
			map.chests[id].pos2 = vector.add(offset, def.pos2)
		end

		for id, def in pairs(map.teams) do
			map.teams[id].flag_pos = vector.add(offset, def.flag_pos)

			map.teams[id].pos1 = vector.add(offset, def.pos1)
			map.teams[id].pos2 = vector.add(offset, def.pos2)
		end

		if map.barrier_area then
			map.barrier_area.pos1 = vector.add(offset, map.barrier_area.pos1)
			map.barrier_area.pos2 = vector.add(offset, map.barrier_area.pos2)
		else
			map.barrier_area = {pos1 = map.pos1, pos2 = map.pos2}
		end
	end

	map.flag_center = calc_flag_center(map)

	if ctf_map.skybox_exists(ctf_map.maps_dir .. dirname) then
		skybox.add({dirname, "#ffffff", [5] = "png"})

		map.skybox = dirname
		map.skybox_forced = true
	end

	return map
end

function ctf_map.save_map(mapmeta)
	local path = minetest.get_worldpath() .. "/schems/" .. mapmeta.dirname .. "/"
	minetest.mkdir(path)

	minetest.chat_send_all(minetest.colorize(ctf_map.CHAT_COLOR, "Saving Map..."))

	-- Write to .conf
	local meta = Settings(path .. "map.conf")

	mapmeta.pos1, mapmeta.pos2 = vector.sort(mapmeta.pos1, mapmeta.pos2)

	if not mapmeta.offset then
		mapmeta.offset = mapmeta.pos1
	end

	for id, def in pairs(mapmeta.chests) do
		def.pos1, def.pos2 = vector.sort(def.pos1, def.pos2)

		mapmeta.chests[id].pos1 = vector.subtract(def.pos1, mapmeta.offset)
		mapmeta.chests[id].pos2 = vector.subtract(def.pos2, mapmeta.offset)
	end

	for id, def in pairs(mapmeta.teams) do
		-- Remove team from the list if not enabled
		if not def.enabled then
			mapmeta.teams[id] = nil
		else
			local flagpos = minetest.find_node_near(def.flag_pos, 3, {"group:flag_bottom"}, true)

			if not flagpos then
				flagpos = def.flag_pos
				minetest.chat_send_all(minetest.colorize("red",
					"Failed to find flag for team " .. id ..
					". Node at given position: " .. dump(minetest.get_node(flagpos).name)
				))
			end

			mapmeta.teams[id].flag_pos = vector.subtract(
				flagpos,
				mapmeta.offset
			)

			mapmeta.teams[id].pos1 = vector.subtract(def.pos1, mapmeta.offset)
			mapmeta.teams[id].pos2 = vector.subtract(def.pos2, mapmeta.offset)
		end
	end

	-- Calculate where barriers are
	local barriers = {}
	local pos1, pos2 = mapmeta.pos1:copy(), mapmeta.pos2:copy()
	local barrier_area = {pos1 = pos1:subtract(mapmeta.offset), pos2 = pos2:subtract(mapmeta.offset)}

	if pos1.y > pos2.y then
		local t = pos2
		pos2 = pos1
		pos1 = t
	end

	if pos1.y + BARRIER_Y_SIZE < pos2.y then
		pos2.y = pos1.y + BARRIER_Y_SIZE
	end

	local queue_break = false
	while true do
		local tmp = {
			-- pos1 = pos1
			-- pos2 = pos2
			-- max = #data
			reps = {}
		}
		local vm = VoxelManip()
		pos1, pos2 = vm:read_from_map(pos1, pos2)
		tmp.pos1, tmp.pos2 = pos1:subtract(mapmeta.offset), pos2:subtract(mapmeta.offset)

		local data = vm:get_data()
		local barrier_found = false
		for i, v in ipairs(data) do
			for b, rep in pairs(ctf_map.barrier_nodes) do
				if v == b then
					barrier_found = true
					tmp.reps[i] = minetest.get_name_from_content_id(rep)
				end
			end
		end

		tmp.max = #data

		if barrier_found then
			table.insert(barriers, tmp)
		end

		if queue_break then
			break
		end

		if pos2.y + BARRIER_Y_SIZE < mapmeta.pos2.y then
			pos1.y = pos2.y + 1
			pos2.y = pos2.y + BARRIER_Y_SIZE
		else
			pos1.y = pos2.y + 1
			pos2.y = mapmeta.pos2.y
			queue_break = true
		end
	end

	meta:set("map_version"   , CURRENT_MAP_VERSION)
	meta:set("size"          , minetest.serialize(vector.subtract(mapmeta.pos2, mapmeta.pos1)))
	meta:set("enabled"       , mapmeta.enabled and "true" or "false")
	meta:set("name"          , mapmeta.name)
	meta:set("author"        , mapmeta.author)
	meta:set("hint"          , mapmeta.hint)
	meta:set("license"       , mapmeta.license)
	meta:set("others"        , mapmeta.others)
	meta:set("initial_stuff" , minetest.serialize(mapmeta.initial_stuff))
	meta:set("treasures"     , mapmeta.treasures or "")
	meta:set("skybox"        , mapmeta.skybox)
	meta:set("start_time"    , mapmeta.start_time)
	meta:set("time_speed"    , mapmeta.time_speed)
	meta:set("phys_speed"    , mapmeta.phys_speed)
	meta:set("phys_jump"     , mapmeta.phys_jump)
	meta:set("phys_gravity"  , mapmeta.phys_gravity)
	meta:set("chests"        , minetest.serialize(mapmeta.chests))
	meta:set("teams"         , minetest.serialize(mapmeta.teams))
	meta:set("barrier_area"  , minetest.serialize(barrier_area))
	meta:set("game_modes"    , minetest.serialize(mapmeta.game_modes))
	meta:set("enable_shadows", mapmeta.enable_shadows)

	meta:write()

	local filepath = path .. "map.mts"
	if minetest.create_schematic(mapmeta.pos1, mapmeta.pos2, nil, filepath) then
		minetest.chat_send_all(minetest.colorize(ctf_map.CHAT_COLOR, "Saved Map '" .. mapmeta.name .. "' to " .. path))
		minetest.chat_send_all(minetest.colorize(ctf_map.CHAT_COLOR,
								"To play, move it to \""..minetest.get_modpath(modname).."/maps/"..mapmeta.dirname..", "..
								"start a normal ctf game, and run \"/ctf_next -f "..mapmeta.dirname.."\""));
	else
		minetest.chat_send_all(minetest.colorize(ctf_map.CHAT_COLOR, "Map Saving Failed!"))
	end

	local f = assert(io.open(path .. "barriers.data", "wb"))
	f:write(minetest.compress(minetest.serialize(barriers), "deflate"))
	f:close()
end
