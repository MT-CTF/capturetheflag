assert(minetest.get_mapgen_setting("mg_name") == "singlenode", "singlenode mapgen is required.")

minetest.register_alias("mapgen_singlenode", "ctf_map:ignore")
minetest.register_alias("ctf_map:flag", "air")

minetest.register_alias("flowers:mushroom_red", "air")
minetest.register_alias("flowers:mushroom_brown", "air")
minetest.register_alias("flowers:waterlily", "air")
minetest.register_alias("flowers:rose", "air")
minetest.register_alias("flowers:tulip", "air")
minetest.register_alias("flowers:dandelion_yellow", "air")
minetest.register_alias("flowers:geranium", "air")
minetest.register_alias("flowers:viola", "air")
minetest.register_alias("flowers:dandelion_white", "air")
minetest.register_alias("flowers:chrysanthemum_green", "air")
minetest.register_alias("default:grass_1", "air")
minetest.register_alias("default:grass_2", "air")
minetest.register_alias("default:grass_3", "air")
minetest.register_alias("default:grass_4", "air")
minetest.register_alias("default:sand_with_kelp", "default:sand")
minetest.register_alias("default:grass_5", "air")
minetest.register_alias("default:bush_leaves", "air")
minetest.register_alias("default:bush_stem", "air")
minetest.register_alias("default:stone_with_gold", "default:stone")


local max_r  = 120
local mapdir = minetest.get_modpath("ctf_map") .. "/maps/"
ctf_map.map  = nil


local next_idx
minetest.register_chatcommand("set_next", {
	privs = { ctf_admin = true },
	func = function(name, param)
		for i, mname in pairs(ctf_map.available_maps) do
			if mname:lower():find(param, 1, true) then
				next_idx = i
				return true, "Selected " .. mname
			end
		end
	end,
})


local function search_for_maps()
	local files_hash = {}

	local dirs = minetest.get_dir_list(mapdir, true)
	table.insert(dirs, ".")
	for _, dir in pairs(dirs) do
		if dir ~= ".git" then
			local files = minetest.get_dir_list(mapdir .. dir, false)
			for i=1, #files do
				local parts = files[i]:split(".")
				local filename = parts[1]
				local extension = parts[2]
				if extension == "mts" then
					files_hash[dir .. "/" .. filename] = true
				else
					if extension ~= "conf" and extension ~= "md"
							and files[i] ~= ".git" then
						error("Map extension is not '.mts': " .. files[i])
					end
				end
			end
		end
	end

	ctf_map.available_maps = {}
	for key, _ in pairs(files_hash) do
		local conf = Settings(mapdir .. "/" .. key .. ".conf")
		minetest.log("error", "ctf.maps." .. key:gsub("%./", ""):gsub("/", "."))
		local val = minetest.settings:get("ctf.maps." .. key:gsub("%./", ""):gsub("/", "."))
		if not conf:get_bool("disabled", false) and val ~= "false" then
			table.insert(ctf_map.available_maps, key)
		end
	end
	if next(ctf_map.available_maps) == nil then
		error("No maps found in directory " .. mapdir)
	end
	return ctf_map.available_maps
end

search_for_maps()

minetest.register_chatcommand("maps_reload", {
	privs = { ctf_admin = true },
	func = function(name, param)
		local maps = search_for_maps()
		next_idx = nil
		return true, #maps .. " maps found: " .. table.concat(maps, ", ")
	end,
})


function ctf_map.place_map(map)
	ctf_map.emerge_with_callbacks(nil, map.pos1, map.pos2, function()
		local schempath = mapdir .. map.schematic
		local res = minetest.place_schematic(map.pos1, schempath,
				map.rotation == "z" and "0" or "90")

		assert(res)

		for _, value in pairs(ctf_map.map.teams) do
			ctf_team_base.place(value.color, value.pos)
		end

		local seed = minetest.get_mapgen_setting("seed")
		for _, chestzone in pairs(ctf_map.map.chests) do
			minetest.log("warning", "Placing " .. chestzone.n .. " chests from " ..
					minetest.pos_to_string(chestzone.from) .. " to "..
					minetest.pos_to_string(chestzone.to))
			place_chests(chestzone.from, chestzone.to, seed, chestzone.n)
		end

		minetest.after(2, function()
			local msg = "Map: " .. map.name .. " by " .. map.author
			if map.hint then
				msg = msg .. "\n" .. map.hint
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

function ctf_match.load_map_meta(idx, name)
	local offset = vector.new(600 * idx, 0, 0)
	local conf_path = mapdir .. name .. ".conf"
	local meta   = Settings(conf_path)

	if meta:get("r") == nil then
		error("Map was not properly configured: " .. conf_path)
	end

	local initial_stuff = meta:get("initial_stuff")
	local treasures = meta:get("treasures")
	treasures = treasures and treasures:split(";")
	local map = {
		idx           = idx,
		name          = meta:get("name"),
		author        = meta:get("author"),
		hint          = meta:get("hint"),
		rotation      = meta:get("rotation"),
		schematic     = name .. ".mts",
		initial_stuff = initial_stuff and initial_stuff:split(","),
		treasures     = treasures,
		r             = tonumber(meta:get("r")),
		h             = tonumber(meta:get("h")),
		offset        = offset,
		teams         = {},
		chests        = {}
	}

	assert(map.r <= max_r)

	map.pos1 = vector.add(offset, { x = -map.r, y = -map.h / 2, z = -map.r })
	map.pos2 = vector.add(offset, { x =  map.r, y = map.h / 2,  z =  map.r })

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

	-- Register per-map treasures or the default set of treasures
	-- if treasures field hasn't been defined in map meta
	if treasurer and ctf_treasure then
		treasurer.treasures = {}
		if treasures then
			for _, item in pairs(treasures) do
				item = item:split(",")
				-- treasurer.register_treasure(name, rarity, preciousness, count)
				if #item == 4 then
					treasurer.register_treasure(item[1],
						tonumber(item[2]),
						tonumber(item[3]),
						tonumber(item[4]))
				-- treasurer.register_treasure(name, rarity, preciousness, {min, max})
				elseif #item == 5 then
					treasurer.register_treasure(item[1],
						tonumber(item[2]),
						tonumber(item[3]),
						{
							tonumber(item[4]),
							tonumber(item[5])
						})
				end
			end
		else
			ctf_treasure.register_default_treasures()
		end
	end

	-- Read custom chest zones from config
	i = 1
	while meta:get("chests." .. i .. ".from") do
		local from  = minetest.string_to_pos(meta:get("chests." .. i .. ".from"))
		local to    = minetest.string_to_pos(meta:get("chests." .. i .. ".to"))
		assert(from and to, "Positions needed for chest zone " .. i .. " in map " .. map.name)

		map.chests[i] = {
			from = vector.add(offset, from),
			to   = vector.add(offset, to),
			n    = tonumber(meta:get("chests." .. i .. ".n") or "23"),
		}

		minetest.log("warning", dump(map.chests[i]))

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

ctf_match.register_on_new_match(function()
	minetest.clear_objects({ mode = "quick" })

	-- Choose next map index, but don't select the same one again
	local idx
	if next_idx then
		idx = next_idx
	elseif ctf_map.map then
		idx = math.random(#ctf_map.available_maps - 1)
		if idx >= ctf_map.map.idx then
			idx = idx + 1
		end
	else
		idx = math.random(#ctf_map.available_maps)
	end
	next_idx = (idx % #ctf_map.available_maps) + 1

	-- Load meta data
	local name = ctf_map.available_maps[idx]
	ctf_map.map = ctf_match.load_map_meta(idx, name)

	-- Place map
	ctf_map.place_map(ctf_map.map)
end)

function ctf_match.create_teams()
	for key, value in pairs(ctf_map.map.teams) do
		local name  = key
		local color = value.color
		local flag  = value.pos

		if name and color and flag then
			print(" - creating " .. key)
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
			minetest.log("error", " - Failed to create " .. key)
		end
	end
end

minetest.register_on_joinplayer(function(player)
	local map = ctf_map.map
	if not map then
		return
	end

	local msg = "Map: " .. map.name .. " by " .. map.author
	if map.hint then
		msg = msg .. "\n" .. map.hint
	end
	minetest.chat_send_player(player:get_player_name(), msg)
end)
