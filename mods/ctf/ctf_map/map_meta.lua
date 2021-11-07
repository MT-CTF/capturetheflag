local CURRENT_MAP_VERSION = "2"

function ctf_map.skybox_exists(subdir)
	local list = minetest.get_dir_list(subdir, true)

	return not (table.indexof(list, "skybox") == -1)
end

function ctf_map.load_map_meta(idx, dirname)
	local meta = Settings(ctf_map.maps_dir .. dirname .. "/map.conf")

	if not meta then error("Map '"..dump(dirname).."' not found") end

	minetest.log("info", "load_map_meta: Loading map meta from '" .. dirname .. "/map.conf'")

	local map
	local offset = vector.new(600 * idx, 0, 0)

	if not meta:get("map_version") then
		if not meta:get("r") then
			error("Map was not properly configured: " .. ctf_map.maps_dir .. dirname .. "/map.conf")
		end

		local mapr = meta:get("r")
		local maph = meta:get("h")
		local start_time = meta:get("start_time")
		local time_speed = meta:get("time_speed")
		local initial_stuff = meta:get("initial_stuff")
		local treasures = meta:get("treasures")

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
			treasures     = treasures and treasures:split(";"),
			skybox        = "none",
			start_time    = start_time and tonumber(start_time) or ctf_map.DEFAULT_START_TIME,
			time_speed    = time_speed and tonumber(time_speed) or 1,
			phys_speed    = tonumber(meta:get("phys_speed")),
			phys_jump     = tonumber(meta:get("phys_jump")),
			phys_gravity  = tonumber(meta:get("phys_gravity")),
			chests        = {},
			teams         = {},
			barrier_area  = {pos1 = pos1, pos2 = pos2}
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
				pos1   = vector.add(from, offset_to_new),
				pos2   = vector.add(to,   offset_to_new),
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
	elseif meta:get("map_version") == CURRENT_MAP_VERSION then
		-- If new items are added also remember to change the table in mapedit_gui.lua
		-- You should also update the version number too
		local size = minetest.deserialize(meta:get("size"))

		offset.y = -size.y/2

		map = {
			map_version   = CURRENT_MAP_VERSION,
			pos1          = offset,
			pos2          = vector.add(offset, size),
			offset        = offset,
			size          = size,
			dirname       = dirname,
			enabled       = meta:get("enabled"),
			name          = meta:get("name"),
			author        = meta:get("author"),
			hint          = meta:get("hint"),
			license       = meta:get("license"),
			others        = meta:get("others"),
			initial_stuff = minetest.deserialize(meta:get("initial_stuff")),
			treasures     = minetest.deserialize(meta:get("treasures")),
			skybox        = meta:get("skybox"),
			start_time    = tonumber(meta:get("start_time")),
			time_speed    = tonumber(meta:get("time_speed")),
			phys_speed    = tonumber(meta:get("phys_speed")),
			phys_jump     = tonumber(meta:get("phys_jump")),
			phys_gravity  = tonumber(meta:get("phys_gravity")),
			chests        = minetest.deserialize(meta:get("chests")),
			teams         = minetest.deserialize(meta:get("teams")),
			barrier_area  = minetest.deserialize(meta:get("barrier_area")),
		}

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

	mapmeta.barrier_area.pos1 = vector.subtract(mapmeta.barrier_area.pos1, mapmeta.offset)
	mapmeta.barrier_area.pos2 = vector.subtract(mapmeta.barrier_area.pos2, mapmeta.offset)

	meta:set("map_version"  , CURRENT_MAP_VERSION)
	meta:set("size"         , minetest.serialize(vector.subtract(mapmeta.pos2, mapmeta.pos1)))
	meta:set("enabled"      , mapmeta.enabled and "true" or "false")
	meta:set("name"         , mapmeta.name)
	meta:set("author"       , mapmeta.author)
	meta:set("hint"         , mapmeta.hint)
	meta:set("license"      , mapmeta.license)
	meta:set("others"       , mapmeta.others)
	meta:set("initial_stuff", minetest.serialize(mapmeta.initial_stuff))
	meta:set("treasures"    , minetest.serialize(mapmeta.treasures))
	meta:set("skybox"       , mapmeta.skybox)
	meta:set("start_time"   , mapmeta.start_time)
	meta:set("time_speed"   , mapmeta.time_speed)
	meta:set("phys_speed"   , mapmeta.phys_speed)
	meta:set("phys_jump"    , mapmeta.phys_jump)
	meta:set("phys_gravity" , mapmeta.phys_gravity)
	meta:set("chests"       , minetest.serialize(mapmeta.chests))
	meta:set("teams"        , minetest.serialize(mapmeta.teams))
	meta:set("barrier_area" , minetest.serialize(mapmeta.barrier_area))

	meta:write()

	minetest.after(0.1, function()
		local filepath = path .. "map.mts"
		if minetest.create_schematic(mapmeta.pos1, mapmeta.pos2, nil, filepath) then
			minetest.chat_send_all(minetest.colorize(ctf_map.CHAT_COLOR, "Saved Map '" .. mapmeta.name .. "' to " .. path))
		else
			minetest.chat_send_all(minetest.colorize(ctf_map.CHAT_COLOR, "Map Saving Failed!"))
		end
	end)
end
