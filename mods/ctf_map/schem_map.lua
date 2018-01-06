assert(minetest.get_mapgen_setting("mg_name") == "singlenode", "singlenode mapgen is required.")

minetest.register_alias("mapgen_singlenode", "ctf_map:ignore")

local max_r = 120
function ctf_map.place_map(map)
	local r = map.r
	local h = map.h
	minetest.emerge_area(map.pos1, map.pos2)

	local schempath = minetest.get_modpath("ctf_map") .. "/maps/" .. map.schematic
	local res = minetest.place_schematic(map.pos1, schempath, map.rotation == "z" and "0" or "90")

	if res ~= nil then
		local seed = minetest.get_mapgen_setting("seed")
		local pos1_middle = { x = -r, y = -h / 2, z = 0 }
		local pos2_middle = { x =  r, y =  h / 2, z = 0 }
		place_chests(map.pos1, pos2_middle, seed)
		place_chests(pos1_middle, map.pos2, seed)
	end

	return res ~= nil
end

local mapdir = minetest.get_modpath("ctf_map") .. "/maps/"

do
	local files_hash = {}
	local files = minetest.get_dir_list(mapdir, false)
	for i=1, #files do
		files_hash[files[i]:split(".")[1]] = true
	end

	ctf_map.available_maps = {}
	for key, _ in pairs(files_hash) do
		table.insert(ctf_map.available_maps, key)
	end
end


ctf_map.map = nil

function ctf_match.load_map_meta(name, offset)
	local meta = Settings(mapdir .. name .. ".conf")
	local map = {
		name      = meta:get("name"),
		author    = meta:get("author"),
		rotation  = meta:get("rotation"),
		schematic = name .. ".mts",
		r         = tonumber(meta:get("r")),
		h         = tonumber(meta:get("h")),
		teams     = {}
	}

	assert(map.r <= max_r)

	map.pos1 = vector.add(offset, { x = -map.r, y = -map.h / 2, z = -map.r })
	map.pos2 = vector.add(offset, { x =  map.r, y = map.h / 2,  z =  map.r })

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

	return map
end

ctf_match.register_on_new_match(function()
	local idx = math.random(#ctf_map.available_maps)
	local name = ctf_map.available_maps[idx]
	ctf_map.map = ctf_match.load_map_meta(name, vector.new(600 * (idx - 1), 0, 0))
	ctf_map.place_map(ctf_map.map)

	minetest.after(10, function()
		minetest.fix_light(ctf_map.map.pos1, ctf_map.map.pos2)
	end)
end)

function ctf_match.create_teams()
	local number = ctf.setting("match.teams")

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
