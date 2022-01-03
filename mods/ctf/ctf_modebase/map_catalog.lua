ctf_modebase.map_catalog = {
	maps = {},
	map_names = {},
	map_dirnames = {},
	current_map = false,
}

local function init()
	local maps = minetest.get_dir_list(ctf_map.maps_dir, true)
	table.sort(maps)

	for i, dirname in ipairs(maps) do
		local map = ctf_map.load_map_meta(i, dirname)
		if map.map_version then
			table.insert(ctf_modebase.map_catalog.maps, map)
			table.insert(ctf_modebase.map_catalog.map_names, map.name)
			ctf_modebase.map_catalog.map_dirnames[map.dirname] = #ctf_modebase.map_catalog.maps
		end
	end
end

init()
assert(#ctf_modebase.map_catalog.maps > 0 or ctf_core.settings.server_mode == "mapedit")

-- List of shuffled map indices, used in conjunction with random map selection
local shuffled_order
local shuffled_idx

-- Fisher-Yates-Savilli shuffling algorithm, used for shuffling map selection order
-- Adapted from snippet provided in https://stackoverflow.com/a/35574006
-- Improved to ensure that the first maps from current shuffled order differ
-- from the last maps from previous shuffled order
-- You can set the minimum distance between the same map using map_recurrence_threshold param
local function shuffle_maps(previous_order, map_recurrence_threshold)
	local maps_count = #ctf_modebase.map_catalog.maps

	map_recurrence_threshold = math.min(map_recurrence_threshold or 0, maps_count - 1)

	if not previous_order then
		map_recurrence_threshold = 0
		previous_order = {}
		for i = 1, maps_count do
			previous_order[i] = i
		end
	end

	-- Reset shuffled_idx
	shuffled_idx = 1

	-- Create table of ordered indices
	shuffled_order = {}

	-- At first select maps that don't intersect with the last maps from previous order
	for i = 1, map_recurrence_threshold do
		local j = math.random(1, maps_count - map_recurrence_threshold)
		local k = maps_count - map_recurrence_threshold + i
		shuffled_order[i] = previous_order[j]
		previous_order[j] = previous_order[k]
	end

	-- Select remaining maps
	for i = map_recurrence_threshold + 1, maps_count do
		local j = math.random(1, maps_count - i + 1)
		local k = maps_count - i + 1
		shuffled_order[i] = previous_order[j]
		previous_order[j] = previous_order[k]
	end
end

function ctf_modebase.map_catalog.select_map()
	-- If shuffled_idx overflows, re-shuffle map selection order
	if not shuffled_order or shuffled_idx > #shuffled_order then
		shuffle_maps(shuffled_order, 3)
	end

	-- Get the real idx stored in table shuffled_order at index [shuffled_idx]
	ctf_modebase.map_catalog.current_map = shuffled_order[shuffled_idx]
	shuffled_idx = shuffled_idx + 1
end

function ctf_modebase.map_catalog.select_map_for_mode(mode)
	while true do
		ctf_modebase.map_catalog.select_map()
		local map = ctf_modebase.map_catalog.maps[ctf_modebase.map_catalog.current_map]
		if not map.game_modes or table.indexof(map.game_modes, mode) ~= -1 then
			break
		end
	end
end
