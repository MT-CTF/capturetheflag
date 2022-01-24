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
		if map.map_version and map.enabled then
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
local used_maps
local unused_maps

-- Fisher-Yates-Savilli shuffling algorithm, used for shuffling map selection order
-- Adapted from snippet provided in https://stackoverflow.com/a/35574006
-- Improved to ensure that the first maps from current shuffled order differ
-- from the last maps from previous shuffled order
-- You can set the minimum distance between the same map using map_recurrence_threshold param
local function shuffle_maps(map_recurrence_threshold)
	local maps_count = #ctf_modebase.map_catalog.maps

	map_recurrence_threshold = math.min(map_recurrence_threshold or 0, maps_count - 1)

	if unused_maps then
		assert(#used_maps > 0)
	else
		unused_maps = {}
		used_maps = {}
		for i = 1, maps_count do
			unused_maps[i] = i
		end
	end

	local unused_maps_count = #unused_maps
	table.insert_all(unused_maps, used_maps)

	-- Create table of ordered indices
	shuffled_order = {}

	-- Choose the right boundary of maps we can select
	-- We can select all unused maps and maps that don't intersect with threshold
	local right = math.max(unused_maps_count, maps_count - map_recurrence_threshold)

	for left = 1, maps_count do
		local idx = math.random(left, right)
		table.insert(shuffled_order, unused_maps[idx])
		unused_maps[idx] = unused_maps[left]

		-- Move the right boundary if we were limited by threshold
		if left + (maps_count - map_recurrence_threshold) > unused_maps_count and right < maps_count then
			right = right + 1
		end
	end

	-- Reset index and used maps
	shuffled_idx = 1
	used_maps = {}
	unused_maps = {}
end

function ctf_modebase.map_catalog.select_map(filter)
	local idx
	while true do
		-- If shuffled_idx overflows, re-shuffle map selection order
		if not shuffled_order or shuffled_idx > #shuffled_order then
			shuffle_maps(3)
		end

		-- Get the real idx stored in table shuffled_order at index [shuffled_idx]
		idx = shuffled_order[shuffled_idx]
		shuffled_idx = shuffled_idx + 1

		if not filter or filter(ctf_modebase.map_catalog.maps[idx]) then
			break
		end

		table.insert(unused_maps, idx)
	end

	table.insert(used_maps, idx)
	ctf_modebase.map_catalog.current_map = idx
end

function ctf_modebase.map_catalog.select_map_for_mode(mode)
	ctf_modebase.map_catalog.select_map(function(map)
		return not map.game_modes or table.indexof(map.game_modes, mode) ~= -1
	end)
end
