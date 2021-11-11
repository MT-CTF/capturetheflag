local TREASURE_VERSION = 1

ctf_map.treasurefy_node = function(pos, node, clicker)
	if not ctf_modebase.current_mode then return end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local treasures = ctf_modebase:get_current_mode().treasures or {}
	if ctf_map.current_map then
		local map_treasures = ctf_map.treasure_from_string(ctf_map.current_map.treasures)

		for k, v in pairs(map_treasures) do
			treasures[k] = v
		end
	end

	for item, def in pairs(treasures) do
		local treasure = ItemStack(item)

		for c = 1, def.max_stacks or 1, 1 do
			if math.random() < (def.rarity or 0.5) then
				treasure:set_count(math.random(def.min_count or 1, def.max_count or 1))
				inv:add_item("main", treasure)
			end
		end
	end
end

-- name ; min_count ; max_count ; max_stacks ; rarity ;;
ctf_map.treasure_from_string = function(str)
	if not str then return {} end

	local out = {}

	for name, min_count, max_count, max_stacks, rarity in str:gmatch("([^%;]+);(%d*);(%d*);(%d*);(%d*);%d;") do
		out[name] = {
			min_count  = min_count  or 1,
			max_count  = max_count  or 1,
			max_stacks = max_stacks or 1,
			rarity     = rarity     or 0.5,
			TREASURE_VERSION,
		}
	end

	return out
end

ctf_map.treasure_to_string = function(treasures)
	if not treasures then return "" end

	local out = ""

	for name, t in pairs(treasures) do
		out = string.format("%s%s;%s;%s;%s;%s;%d;",
			out, name,
			t.min_count or 1,
			t.max_count or 1,
			t.max_stacks or 1,
			t.rarity or 0.5,
			TREASURE_VERSION
		)
	end

	return out
end