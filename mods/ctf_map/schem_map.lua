assert(minetest.get_mapgen_setting("mg_name") == "singlenode", "singlenode mapgen is required.")

minetest.register_alias("mapgen_singlenode", "ctf_map:ignore")

function ctf_map.place_map(map)
	local r = map.r
	local h = map.h
	minetest.emerge_area({ x = -r, y = -h / 2, z = -r }, { x = r, y = h / 2, z = r })

	local res = minetest.place_schematic({ x = -r - 5, y = -h / 2, z = -r - 5 },
		minetest.get_modpath("ctf_map") .. "/maps/" .. map.schematic, map.rotation == "z" and "0" or "90")

	return res ~= nil
end

ctf_map.map = nil

function ctf_match.load_map_meta(name)
	local meta = Settings(minetest.get_modpath("ctf_map") .. "/maps/" .. name .. ".conf")
	local map = {
		name      = meta:get("name"),
		author    = meta:get("author"),
		rotation  = meta:get("rotation"),
		schematic = name .. ".mts",
		r         = tonumber(meta:get("r")),
		h         = tonumber(meta:get("h")),
		teams     = {}
	}

	local i = 1
	while meta:get("team." .. i) do
		local tname = meta:get("team." .. i)
		local tcolor = meta:get("team." .. i .. ".color")
		local tpos = minetest.string_to_pos(meta:get("team." .. i .. ".pos"))

		map.teams[tname] = {
			color = tcolor,
			pos = tpos,
		}

		i = i + 1
	end

	return map
end

ctf_match.register_on_new_match(function()
	ctf_map.map = ctf_match.load_map_meta("01_two_hills")
	print(dump(ctf_map.map))
	ctf_map.place_map(ctf_map.map)
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
