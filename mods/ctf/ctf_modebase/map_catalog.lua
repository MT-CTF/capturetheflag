ctf_modebase.map_catalog = {
	maps = {},
	map_names = {},
	map_dirnames = {},
	current_map = false,
}

local maps_pool = {}
local used_maps = {}
local used_maps_idx = 1
local map_repeat_interval

local function init()
	local maps = minetest.get_dir_list(ctf_map.maps_dir, true)
	table.sort(maps)

	for i, dirname in ipairs(maps) do
		local map = ctf_map.load_map_meta(i, dirname)
		if map.map_version and map.enabled then
			table.insert(ctf_modebase.map_catalog.maps, map)
			table.insert(ctf_modebase.map_catalog.map_names, map.name)
			ctf_modebase.map_catalog.map_dirnames[map.dirname] = #ctf_modebase.map_catalog.maps
		end
	end

	for i = 1, #ctf_modebase.map_catalog.maps do
		table.insert(maps_pool, i)
	end

	map_repeat_interval = math.floor(#ctf_modebase.map_catalog.maps / 2)
end

init()
assert(#ctf_modebase.map_catalog.maps > 0 or ctf_core.settings.server_mode == "mapedit")

function ctf_modebase.map_catalog.select_map(filter)
	local maps = {}
	for idx, map in ipairs(maps_pool) do
		if not filter or filter(ctf_modebase.map_catalog.maps[map]) then
			table.insert(maps, idx)
		end
	end

	local selected = maps[math.random(1, #maps)]

	if not selected then
		selected = ctf_modebase.map_catalog.map_dirnames["plains"]
	end

	ctf_modebase.map_catalog.current_map = maps_pool[selected]

	if map_repeat_interval > 0 then
		if #used_maps < map_repeat_interval then
			table.insert(used_maps, maps_pool[selected])
			maps_pool[selected] = maps_pool[#maps_pool]
			maps_pool[#maps_pool] = nil
		else
			used_maps[used_maps_idx], maps_pool[selected] = maps_pool[selected], used_maps[used_maps_idx]
			used_maps_idx = used_maps_idx + 1
			if used_maps_idx > #used_maps then
				used_maps_idx = 1
			end
		end
	end
end

function ctf_modebase.map_catalog.select_map_for_mode(mode)
	ctf_modebase.map_catalog.select_map(function(map)
		return not map.game_modes or table.indexof(map.game_modes, mode) ~= -1
	end)
end
