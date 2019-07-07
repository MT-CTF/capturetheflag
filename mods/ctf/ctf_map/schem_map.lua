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
ctf_map.mapdir = minetest.get_modpath("ctf_map") .. "/maps/"
ctf_map.map    = nil

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
		str = minetest.colorize("#44FF44", str)
	end
	status = status .. "\n" .. str

	-- If player just joined, also display map hint
	if joined and ctf_map.map.hint then
		status = status .. "\n" .. minetest.colorize("#22FF22", ctf_map.map.hint)
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

local next_idx
minetest.register_chatcommand("set_next", {
	privs = { ctf_admin = true },
	func = function(name, param)
		local idx, map = ctf_map.get_idx_and_map(param)
		if idx then
			next_idx = idx
			minetest.log("action", name .. " selected '" .. map.name .. "' as next map")
			return true, "Selected " .. map.name
		else
			return false, "Couldn't find any matches"
		end
	end,
})

local function load_map_meta(idx, dirname, meta)
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
		r             = tonumber(meta:get("r")),
		h             = tonumber(meta:get("h")),
		name          = meta:get("name"),
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
	return ctf_map.available_maps
end

load_maps()

minetest.register_chatcommand("maps_reload", {
	privs = { ctf_admin = true },
	func = function(name, param)
		next_idx = nil

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

		assert(res)

		for _, value in pairs(ctf_map.map.teams) do
			ctf_map.place_base(value.color, value.pos)
		end

		local seed = minetest.get_mapgen_setting("seed")
		for _, chestzone in pairs(ctf_map.map.chests) do
			minetest.log("verbose", "Placing " .. chestzone.n .. " chests from " ..
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
	ctf_map.map = ctf_map.available_maps[idx]
	ctf_map.map.idx = idx

	map_str = "Map: " .. ctf_map.map.name .. " by " .. ctf_map.map.author

	-- Register per-map treasures, or the default set of treasures
	-- if treasures field hasn't been defined in map meta
	if ctf_treasure then
		treasurer.treasures = {}
		if ctf_map.treasures then
			for _, item in pairs(ctf_map.treasures) do
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
			-- If treasure is a part of map's initial stuff, don't register it
			local blacklist = ctf_map.map.initial_stuff or give_initial_stuff.get_stuff()
			for _, def in pairs(ctf_treasure.get_default_treasures()) do
				local is_valid = true
				for _, b_item in pairs(blacklist) do
					local b_stack = ItemStack(b_item)
					local t_stack = ItemStack(def[1])
					if b_stack:get_name() == t_stack:get_name() and
							t_stack:get_count() == 1 then
						is_valid = false
						minetest.log("info",
								"ctf_map: Omitting treasure - " .. def[1])
						break
					end
				end

				if is_valid then
					minetest.log("info",
							"ctf_map: Registering treasure - " .. def[1])
					treasurer.register_treasure(def[1], def[2], def[3], def[4])
				end
			end
		end
	end

	-- Place map
	place_map(ctf_map.map)

	-- Update time speed
	ctf_map.update_time()

	-- Update players' skyboxes last
	ctf_map.set_skybox_all()
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
